#include "Constants.h"
#include "TreeBuilder.h"
#include "TLConf.h"
#include "TMoteStackConf.h"

#define UNAVAILABLE_NODE 0xFFFF

/** 
 * Module for building the tree on any node different from the sink.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */
 
/**
 * TODO: use the nextwakeup in the neighbortuple instead to send in the forward 
 *         ( see Boot.booted() ) 
 */

module TreeBuilderP {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerParentUpdate;
    interface Timer<TMilli> as TimerFW;
    interface Timer<TMilli> as TimerParentWakeUp;

    interface Random;
    
    interface TupleSpace as TS;

    interface AMPacket;

    interface Leds;
    interface Orchestrator;

#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
    interface ProximityState as Proximity;
#endif
  }

  provides {  
    interface TreeConnection;
  }
}

#if (MY_TYPE == MOBILE_NODE)
#warning "*** TREE ROUTING: THIS NODE ARE USING THE TREE BUILDER BUT IS A MOBILE NODE ***"
#endif 

implementation {
  TLOpId_t reactionId, ingId;
  TLOpId_t outId;
  TLOpId_t rdCandLQI;
  uint16_t parent_round;

  bool isSink;
  bool firstTX;
  bool parentEveryTimeUp;
  uint16_t parent;
  uint16_t path_nlqi;
  uint16_t parent_nlqi, cand_nlqi;
  uint16_t parent_lqi, candidate_lqi;
    
  void installReaction() {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint32_t> p = newTuple(
                             actualField(TREE_BUILDING_MESSAGE),
                             dontCare(), 
                             dontCare(),
                             dontCare(),
                             dontCare());
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }
  
  bool isSecondNewer(uint16_t round1, uint16_t round2){
    if (round1 == round2){
      return FALSE;
    } else if (round1 < round2){
      if ((round2 - round1) < 0x8000) {
        return TRUE;
      } else {
        return FALSE;
      }
    } else {
      if ((round1 - round2) < 0x8000) {
        return FALSE;
      } else {
        return TRUE;
      }
    }
  }

  void forwardNotification(){
    uint16_t delay;
    delay = call Random.rand16();
    delay %= (MAX_FW_BACKOFF - MIN_FW_BACKOFF);
    delay += (MIN_FW_BACKOFF);
    
    firstTX=TRUE;
    if (isSink){
      call TimerFW.startOneShot(PEROIOD_REFRESH+delay);
    } else {
      call TimerFW.startOneShot(delay);
    }
  }
  
  event void Boot.booted() {
    parent = TL_LOCAL;
    parent_nlqi = CONGESTED_PATH;
    parent_lqi = 0;
    installReaction();
    parent_round=0;
    firstTX=TRUE;
    
    if (MY_TYPE == SINK_NODE){
      isSink=TRUE;
      parent_lqi = 0xFFFF;
    } else {
      isSink=FALSE;    
    }
    
    if (isSink){
      path_nlqi=0;
      forwardNotification();
    }
  }
  
  command uint16_t TreeConnection.getParent(){
    return parent;
  }
  
  command uint16_t TreeConnection.getPathCost(){
    return path_nlqi;
  }

  command uint16_t TreeConnection.getParentLQI(){
    return parent_lqi;
  }

  event void TimerFW.fired(){
    tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint32_t>  t1; 
    atomic{
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
      t1 = newTuple(
                    actualField(TREE_BUILDING_MESSAGE),
                    actualField(TL_LOCAL), 
                    actualField(parent_round),
                    actualField(path_nlqi),
                    actualField(call Proximity.nextRadioOn())
                   );
#else
      t1 = newTuple(
                    actualField(TREE_BUILDING_MESSAGE),
                    actualField(TL_LOCAL), 
                    actualField(parent_round),
                    actualField(path_nlqi),
                    actualField(NODE_EVERY_UP)
                   );
#endif

      call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t1);
      if (firstTX){
        firstTX=FALSE;
        call TimerFW.startOneShot(PROXIMITY_EPOCH/2);
        return;
      }    
      if (isSink){
        parent_round++;
          forwardNotification();
      }
    }
  }

  command void TreeConnection.setSink(bool isSinkNode){
    isSink = isSinkNode;
  }

  task void parentUpdate(){
    if (parent != TL_LOCAL){
      signal TreeConnection.parentUpdate(parent);
    }
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    uint16_t cand_path_nlqi;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint32_t>  t;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint32_t> *temp;
    tuple<uint16_t, lqi, rssi, uint32_t> *tparent;
    tuple<uint16_t, lqi, rssi, uint32_t> neighborT;
    uint16_t delay;

    PROCESS_OP(reactionId,
               temp = (tuple<uint8_t, uint16_t, uint16_t,
                       uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator);
               t = newTuple(
                            actualField(TREE_BUILDING_MESSAGE),
                            different(TL_LOCAL),
                            dontCare(),
                            dontCare(),
                            dontCare());
               call TS.ing(&ingId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
              );

    /*       RD for the RSSI value of the parent */
    PROCESS_OP(rdCandLQI,
               tparent = (tuple<uint16_t, lqi,
                          uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (tparent == NULL){
                 cand_nlqi = UNAVAILABLE_NODE;
               } else {
                 candidate_lqi = tparent->value1;
                 if (candidate_lqi <  MIN_RELIABLE_LINK_LQI){
                   cand_nlqi = UNRELIABLE_LINK;
                 } else if (candidate_lqi > MAX_ROUTING_LQI){
                   cand_nlqi = 1;
                 } else {
                   cand_nlqi = 1 + (MAX_ROUTING_LQI -
                                    candidate_lqi)/ROUTING_COST_UNIT;
                 }
               });

    /*     ING FOR THE TREEBUILD TUPLES */
    PROCESS_OP(ingId,
               for (temp = (tuple<uint8_t, uint16_t, uint16_t,
                       uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator);
                    temp != NULL;
                    temp = (tuple<uint8_t, uint16_t, uint16_t,
                            uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator)){
                            
                 if (isSink){
                   continue;                 
                 }
                 if (parent == TL_LOCAL ||
                     isSecondNewer(parent_round, temp->value2)){
                   /* I HAVE NO PARENT OR
                      I HAVE A PARENT AND THE SEQUENCE NUM OF THE TREE IS
                      NEWER THAN THE PREVIOUSLY JOINED ONE */
                   neighborT = newTuple(
                                        actualField(temp->value1),
                                        lqiRead(),
                                        dontCare(),
                                        dontCare());
                   call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, RAM_TS, (tuple *) &neighborT);
                   if (cand_nlqi != UNAVAILABLE_NODE) {
                     call TimerParentWakeUp.stop();
                     if (temp->value4 == NODE_EVERY_UP){
                       parentEveryTimeUp = TRUE;
                     } else {
                       call TimerParentWakeUp.startOneShot(temp->value4);
                     }
                     parent = temp->value1;
                     parent_round = temp->value2;
                     parent_nlqi = cand_nlqi;
                     parent_lqi = candidate_lqi;
                     path_nlqi =  parent_nlqi + temp->value3;
                     post parentUpdate();
                     forwardNotification();
                   }
                 } else {
                   /* THE SEQUENCE NUM IS CONCURRENT TO THE ONE OF THE ACTUAL PARENT */
                   neighborT = newTuple(
                                        actualField(temp->value1),
                                        lqiRead(),
                                        dontCare(),
                                        dontCare());
                   call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, RAM_TS, (tuple *) &neighborT);
                   if (cand_nlqi != UNAVAILABLE_NODE) {
                     cand_path_nlqi = cand_nlqi + temp->value3;
                     if ((path_nlqi >  cand_path_nlqi) ||
                         ((path_nlqi == cand_path_nlqi) &&
                          (cand_nlqi < parent_nlqi))) {
                       /* THE COST OF THE PATH IS BETTER THAN THE CURRENT ONE OR
                          THE COST OF THE PATH IS EQUAL BUT THE LINK TO THE
                          CANDIDATE IS BETTER */
                       call TimerParentWakeUp.stop();                       
                       if (temp->value4 == NODE_EVERY_UP){
                         parentEveryTimeUp = TRUE;
                       } else {
                         call TimerParentWakeUp.startOneShot(temp->value4);
                       }
                       parent = temp->value1;
                       parent_nlqi = cand_nlqi;
                       parent_lqi = candidate_lqi;
                       path_nlqi =  parent_nlqi + temp->value3;
                       post parentUpdate();
                       forwardNotification();
                     }
                   }
                 }
               });
  }
  
  command uint32_t TreeConnection.getParentNextWakeUp(){
    if (parent == TL_LOCAL){
      return NODE_EVERY_UP;  
    }
    if (parentEveryTimeUp){
      return NODE_EVERY_UP;
    } else {
      return ((call TimerParentWakeUp.gett0() + 
               call TimerParentWakeUp.getdt() - 
               call TimerParentWakeUp.getNow()));
    }
  }  
  
  event void TimerParentUpdate.fired(){
    post parentUpdate();
  }
  
  event void TimerParentWakeUp.fired(){
    if (parent == TL_LOCAL){
      call TimerParentWakeUp.stop();
      return;     
    }    
    call TimerParentWakeUp.startOneShot(PERIOD_TIME_ON+PERIOD_TIME_OFF);
    call Leds.led2Toggle();
  }
 
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
        TLOpId_t operationId, 
        TLTarget_t target,  
        TLTupleSpace_t ts,
        tuple* returningTuple){
  }

}
