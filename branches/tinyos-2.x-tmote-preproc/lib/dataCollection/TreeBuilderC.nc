/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 296 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 20:31:13 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TreeBuilderC.nc 296 2008-02-26 18:31:13Z mceriotti $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU Lesser General Public License
 * *   as published by the Free Software Foundation; either version 2
 * *   of the License, or (at your option) any later version.
 * *
 * *   This program is distributed in the hope that it will be useful,
 * *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 * *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * *   GNU General Public License for more details.
 * *
 * *   You should have received a copy of the GNU General Public License
 * *   along with this program; if not, you may find a copy at the FSF web
 * *   site at 'www.gnu.org' or 'www.fsf.org', or you may write to the
 * *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * *   Boston, MA  02111-1307, USA
 ***/

#include "Configuration.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define UNAVAILABLE_NODE 0xFFFF

/** 
 * Module for building the tree on any node different from the sink.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module TreeBuilderC {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerParentUpdate;
    interface Timer<TMilli> as TimerFW;

    interface Random;
    
    interface TupleSpace as TS;

    interface AMPacket;

    interface Leds;
    interface TLObjects;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {
    interface TreeConnection;
  }
}

#ifdef LEAF_NODE
#warning "*** TREE ROUTING: THIS NODE IS GOING TO BE A LEAF ***"
#endif 

implementation {

  TLOpId_t reactionId, ingId;
  TLOpId_t outId;
  bool building, notifying_congestion;
  TLOpId_t rdCandLQI;

  uint16_t parent;
  uint16_t parent_round;
  uint16_t path_nlqi;
  uint16_t parent_nlqi, cand_nlqi;
  uint16_t parent_lqi, candidate_lqi;
  
  bool congested, reliable_path, forwarder_node;
  
  void installReaction() {
    tuple<uint8_t, uint16_t, uint16_t, 
      uint16_t> p = newTuple(
                             actualField(DATA_COLLECT_CTRL_TYPE),
                             dontCare(), 
                             dontCare(),
                             dontCare());
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }
  
  // Return TRUE if round2 follows round1
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
  
  event void Boot.booted() {
    parent = TL_LOCAL;
    parent_nlqi = CONGESTED_PATH;
    parent_lqi = 0;
    parent_round = 0;
    congested = TRUE;
    reliable_path = FALSE;
    building = FALSE;
    notifying_congestion = FALSE;
#ifndef LEAF_NODE
    forwarder_node = TRUE;
#endif
#ifdef LEAF_NODE
    forwarder_node = FALSE;
#endif
    installReaction();
    call Leds.led0On();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  command void TreeConnection.setReliablePath(bool reliable){
    atomic reliable_path = reliable;
  }

  command void TreeConnection.setForwarderNode(bool forwarder){
    forwarder_node = forwarder;
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

  // The parameter of the function is true if the notification is about 
  // the building of the routing tree, false otherwise
  void forwardNotification(bool building_tree){
    uint16_t delay;
    if (!forwarder_node)
      return;
    if (building_tree)
      building = TRUE;
    else
      notifying_congestion = TRUE;
    delay = call Random.rand16();
    delay %= (MAX_FW_BACKOFF - MIN_FW_BACKOFF);
    delay += (MIN_FW_BACKOFF);
    call TimerFW.startOneShot(delay);
  }

  void forwardCongestion(){
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t1;
    t1 = newTuple(
                  actualField(DATA_COLLECT_CTRL_TYPE),
                  actualField(TL_LOCAL), 
                  actualField(parent_round),
                  actualField(CONGESTED_PATH));
    call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t1);
  }

  event void TimerFW.fired(){
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t1;
    atomic{
      if (building){
        building = FALSE;
        t1 = newTuple(
                      actualField(DATA_COLLECT_CTRL_TYPE),
                      actualField(TL_LOCAL), 
                      actualField(parent_round),
                      actualField(path_nlqi));
        call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t1);
      }
      if (notifying_congestion){
        notifying_congestion = FALSE;
      	forwardCongestion();
      }
    }
  }

  task void parentUpdate(){
    if (congested)
      congested = FALSE;
    if (parent != TL_LOCAL){
      signal TreeConnection.parentUpdate(parent);
    }
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    uint16_t cand_path_nlqi;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> *temp;
    tuple<uint16_t, lqi, uint16_t> *tparent;
    tuple<uint16_t, lqi, uint16_t> neighborT;
    uint16_t delay;

    PROCESS_OP(reactionId,
               temp = (tuple<uint8_t, uint16_t, uint16_t,
                       uint16_t> *) call TS.nextTuple(operationId, iterator);
               t = newTuple(
                            actualField(DATA_COLLECT_CTRL_TYPE),
                            dontCare(),
                            dontCare(),
                            dontCare());
               call TS.ing(&ingId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t););

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
                       uint16_t> *) call TS.nextTuple(operationId, iterator);
                    temp != NULL;
                    temp = (tuple<uint8_t, uint16_t, uint16_t,
                            uint16_t> *) call TS.nextTuple(operationId, iterator)){
                 if (temp->value3 == CONGESTED_PATH){
                   if(temp->value1 == parent && !congested){
                     /* THE PATH IS CONGESTED (FROM MY PARENT I RECEIVED A
                        CONGESTED_PATH MESSAGE) */
                     congested = TRUE;
                     delay = call Random.rand16();
                     delay %= (UNRELREC_DELAY/2);
                     delay += (UNRELREC_DELAY/2 + UNRELREC_DELAY);
                     forwardNotification(FALSE);
                     call TimerParentUpdate.startOneShot(delay);
                     signal TreeConnection.congestedPath(FALSE, (temp->value2 == 0xFFFF));
                   }
                 } else if (reliable_path){
                   /* THE PATH IS RELIABLE: UPDATE THE COST AND FORWARD 
                      THE NOTIFICATION ONLY IF IT COMES FROM YOUR CURRENT
                      PARENT OR YOU HAVE NONE */
                   if (temp->value1 == parent || parent == TL_LOCAL){
                     neighborT = newTuple(
                                          actualField(temp->value1),
                                          lqiRead(),
                                          dontCare());
                     call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, RAM_TS, (tuple *)
                                &neighborT);
                     if (cand_nlqi != UNAVAILABLE_NODE) {
                       if(parent == TL_LOCAL){
                         parent = temp->value1;
                         post parentUpdate();
                       }
                       parent_round = temp->value2;
                       parent_nlqi = cand_nlqi;
                       parent_lqi = candidate_lqi;
                       path_nlqi =  parent_nlqi + temp->value3;
                       call Leds.led0Off();
                       forwardNotification(TRUE);
                     }
                   }
                 } else if (parent == TL_LOCAL ||
                            isSecondNewer(parent_round, temp->value2)){
                   /* I HAVE NO PARENT OR
                      I HAVE A PARENT AND THE SEQUENCE NUM OF THE TREE IS
                      NEWER THAN THE PREVIOUSLY JOINED ONE */
                   neighborT = newTuple(
                                        actualField(temp->value1),
                                        lqiRead(),
                                        dontCare());
                   call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, RAM_TS, (tuple *) &neighborT);
                   if (cand_nlqi != UNAVAILABLE_NODE) {
                     parent = temp->value1;
                     parent_round = temp->value2;
                     parent_nlqi = cand_nlqi;
                     parent_lqi = candidate_lqi;
                     path_nlqi =  parent_nlqi + temp->value3;
                     congested = FALSE;
                     call Leds.led0Off();
                     post parentUpdate();
                     forwardNotification(TRUE);
                   }
                 } else if (parent_round == temp->value2){
                   /* THE SEQUENCE NUM IS CONCURRENT TO THE ONE OF THE ACTUAL PARENT */
                   neighborT = newTuple(
                                        actualField(temp->value1),
                                        lqiRead(),
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
                       parent = temp->value1;
                       parent_round = temp->value2;
                       parent_nlqi = cand_nlqi;
                       parent_lqi = candidate_lqi;
                       path_nlqi =  parent_nlqi + temp->value3;
                       congested = FALSE;
                       call Leds.led0Off();
                       post parentUpdate();
                       forwardNotification(TRUE);
                     }
                   }
                 }
               });
  }
  
  command void TreeConnection.congested(bool failure){
    uint16_t delay;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t1;
    atomic{
      if (!congested){
        if (!failure){        
          delay = call Random.rand16();
          delay %= (UNRELREC_DELAY/2);
          delay += (UNRELREC_DELAY/2);
          congested = TRUE;
          call TimerParentUpdate.startOneShot(delay);
          signal TreeConnection.congestedPath(TRUE, FALSE);
          if (forwarder_node)
            forwardCongestion();
        } else if (forwarder_node){
          t1 = newTuple(
                        actualField(DATA_COLLECT_CTRL_TYPE),
                        actualField(TL_LOCAL), 
                        actualField(0xFFFF),
                        actualField(CONGESTED_PATH));
          call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t1);
        }
      }
    }
  }

  event void TimerParentUpdate.fired(){
    post parentUpdate();
  }
 
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
