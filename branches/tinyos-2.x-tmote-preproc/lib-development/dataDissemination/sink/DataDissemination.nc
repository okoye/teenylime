/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 300 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 21:50:56 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataDissemination.nc 300 2008-02-26 19:50:56Z mceriotti $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "Configuration.h"
#include "TupleSpace.h"

/**
 * A component that activates the dissemination of tuples in the network.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module DataDissemination {

  uses {
    interface Boot;
    interface TupleSpace as TS;

    interface TeenyLIMESystem;

    interface TLObjects;

    interface AMPacket;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  NeighborTuple<uint16_t, lqi, uint16_t> neighborTuple;
  tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> toInject;
  TLOpId_t dataReactId, neighborReactId, rdgId, rdRemId;
  TLOpId_t inId, outId, inCurrentTupleId;
  TLOpId_t rdNotifiedDataId, rdNeighborId, inToInjectId;

  uint16_t currentDissId;
  uint16_t nextDissId;
  uint16_t newestHeardId;
  uint16_t dataOwner;
  bool readingRem, remRdFailed;
  bool somethingToInject;

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

  void addReactions(){
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> disseminationT;
    tuple<uint16_t, lqi, uint16_t> neighborT;
    disseminationT = newTuple(
                              actualField(DISSEMINATION_TYPE),
                              dontCare(),
                              dontCare(),
                              dontCare());
    neighborT = newTuple(
                         different(TL_LOCAL),
                         lqiRead(),
                         dontCare());
    call TS.addReaction(&dataReactId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &disseminationT);
    call TS.addReaction(&neighborReactId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &neighborT);
  }

  void startRemRd(uint16_t destination){
    tuple<uint8_t, uint16_t, uint16_t,
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> rem;
    rem = newTuple(
                   actualField(DISSEMINATION_TYPE),
                   actualField(nextDissId),
                   dontCare(),
                   dontCare());
    readingRem = TRUE;
    remRdFailed = FALSE;
    call TS.rd(&rdRemId, TRUE, destination, RAM_TS, (tuple *) &rem);
  }

  void startLocRdg(uint16_t classId){
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
      loc = newTuple(
                     actualField(DISSEMINATION_TYPE),
                     dontCare(),
                     actualField(classId),
                     dontCare());
    call TS.rdg(&rdgId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &loc);
  }

  task void recoverNotifiedData(){
    tuple<uint8_t, uint16_t, uint16_t,
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> t;
    tuple<uint16_t, lqi, uint16_t> tNeigh;
    if (currentDissId == newestHeardId)
    	return;
    tNeigh = newTuple(
                       dontCare(),
                       lqiRead(),
                       actualField(newestHeardId));
    /* Read the id of an owner of the most recent dissemination id */
    call TS.rd(&rdNeighborId, FALSE, TL_LOCAL, RAM_TS, (tuple *)
               &tNeigh);
    /* Read if there is some data with the dissemination id
       following the local one (if there is not one, a remote rd is issued on
       the node with the most recent dissemination id)*/
    t = newTuple(
                 actualField(DISSEMINATION_TYPE),
                 actualField(nextDissId),
                 dontCare(),
                 dontCare());
    call TS.rd(&rdNotifiedDataId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
  }

  task void injectNewData(){
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> temp;
    atomic{
      if (newestHeardId != currentDissId){
        return;
      } else {
        temp = newTuple(
                        actualField(DISSEMINATION_TYPE),
                        actualField(DISSEMINATE_A_NEW_TUPLE),
                        dontCare(),
                        dontCare());
        call TS.in(&inToInjectId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
      }
      if (somethingToInject){
        somethingToInject = FALSE;
        toInject.value1 = nextDissId;
        call Leds.led1Toggle();
        call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &toInject);
        post injectNewData();
      }
    }
  }

  event void Boot.booted() {
    currentDissId = 0;
    newestHeardId = 0;
    nextDissId = currentDissId  + 1;
    if (nextDissId == DISSEMINATE_A_NEW_TUPLE){
      nextDissId++;
    }
    dataOwner = TL_LOCAL;
    readingRem = FALSE;
    remRdFailed = FALSE;
    somethingToInject = FALSE;
    addReactions();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    neighborTuple = newTuple(
                             actualField(call AMPacket.address()),
                             lqiRead(),
                             actualField(currentDissId));
    return (tuple *) &neighborTuple;
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> *rcv;
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> *new_diss;
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> *last_diss;
    tuple<uint16_t, lqi, uint16_t> *neigh;

    PROCESS_OP(neighborReactId,
               /* Reaction for a neighbor tuple */
               neigh = (tuple<uint16_t, lqi,
                        uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (isSecondNewer(newestHeardId, neigh->value2)){
                 /* The neighbor tuple contains a dissemination id
                    never heard */
                 dataOwner = neigh->value0;
                 newestHeardId = neigh->value2;
                 if (!readingRem){
                   post recoverNotifiedData();
                 }
               });
    
    PROCESS_OP(rdNotifiedDataId,
               /* Read for the data with the notified dissemination id */
               rcv = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
                if (rcv != NULL){
                 startLocRdg(rcv->value2);
               } else if (rcv == NULL && !readingRem && dataOwner != TL_LOCAL){
                 /* There is no data locally available with the announced
                    id */
                 startRemRd(dataOwner);
               });

    PROCESS_OP(dataReactId,
               /* Reaction for disseminated data */
               rcv = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (rcv->value1 == DISSEMINATE_A_NEW_TUPLE){
                 post injectNewData();
               } else if (!isSecondNewer(currentDissId, rcv->value1)) {
                 /* If the disseminated data is older or equal to the current
                    dissemination id */
                 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
               } else if (nextDissId == rcv->value1 && !readingRem) {
                 /* If the data has an id which is the one following the current
                    dissemination id owned by the local node */
                 startLocRdg(rcv->value2);                 
               } else if (isSecondNewer(newestHeardId, rcv->value1)){
                 /* If the data has an id bigger than the most recent one 
                    heard by the local node */
                 newestHeardId = rcv->value1;
                 if (!readingRem) {
                   /* If the data has an id bigger than the one following the
                      current dissemination id owned by the local node */
                   post recoverNotifiedData();
                 }
               });
    
    PROCESS_OP(rdgId,
               /* Local rdg for disseminated tuples */
               last_diss = NULL;
               new_diss = NULL;
               for (rcv = (tuple<uint8_t, uint16_t, uint16_t,
                           uint8_t[TUPLE_DISS_PAYLOAD_SIZE]>
                           *) call TS.nextTuple(operationId, iterator);
                    rcv != NULL;
                    rcv = (tuple<uint8_t, uint16_t, uint16_t,
                           uint8_t[TUPLE_DISS_PAYLOAD_SIZE]>
                           *) call TS.nextTuple(operationId, iterator)){
                 if (!isSecondNewer(currentDissId, rcv->value1)){
                   if (last_diss == NULL ||
                       isSecondNewer(last_diss->value1, rcv->value1))
                     last_diss = rcv;
                   else
                     call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
                 } else if (rcv->value1 == nextDissId){
                   if (new_diss == NULL)
                     new_diss = rcv;
                   else
                     call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
                 }
               }
               if (new_diss != NULL){
                 if (last_diss != NULL){
                   call TS.in(&inCurrentTupleId, FALSE, TL_LOCAL, RAM_TS, 
                              (tuple*) last_diss->value3);
                   call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) last_diss);
                 }
                 /* The tuple has a newer id */
                 currentDissId = nextDissId;
                 nextDissId = currentDissId  + 1;
                 if (nextDissId == DISSEMINATE_A_NEW_TUPLE){
                   nextDissId++;
                 }
       	         neighborTuple = newTuple(
                                          actualField(call AMPacket.address()),
                                          lqiRead(),                             
                                          actualField(currentDissId));
                 call TeenyLIMESystem.updateNeighborTuple((tuple *)&neighborTuple);
                 call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, 
                             (tuple *) new_diss->value3);
                 call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, 
                             (tuple *) new_diss);
               }
               if (isSecondNewer(currentDissId, newestHeardId))
                 post recoverNotifiedData();
               else
                 newestHeardId = currentDissId;
               );

    PROCESS_OP(inToInjectId,
               rcv = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (rcv != NULL){
                 call TLObjects.copy_tuple((tuple *) &toInject, (tuple *) rcv);
                 somethingToInject = TRUE;
                 call TS.nextTuple(operationId, iterator);
               } else {
                 somethingToInject = FALSE;
               });


    PROCESS_OP(rdRemId,
               /* Remote rd for disseminated tuples */
               readingRem = FALSE;
               rcv = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (remRdFailed){
                 remRdFailed = FALSE;
                 post recoverNotifiedData();
               } else {
                 if (rcv != NULL){
                   call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
                 } else {
                   currentDissId = nextDissId;
                   nextDissId = currentDissId  + 1;
                   if (nextDissId == DISSEMINATE_A_NEW_TUPLE){
                     nextDissId++;
                   }
                 }
                 if (isSecondNewer(currentDissId, newestHeardId))
                   post recoverNotifiedData();
                 else{
                   newestHeardId = currentDissId;
                   post injectNewData();
                 }
               });
    
    PROCESS_OP(rdNeighborId,
               /* rd for the id of the neihbor that has a given
                  dissemination id */
               neigh = (tuple<uint16_t, lqi,
                        uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (neigh != NULL)
                 dataOwner = neigh->value0;
               else 
                 dataOwner = TL_LOCAL;
               );
    
    PROCESS_OP(inId,
               rcv = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (rcv != NULL)
                 call TS.nextTuple(operationId, iterator);
               );
    
    PROCESS_OP(inCurrentTupleId,
               if (call TS.nextTuple(operationId, iterator) != NULL)
                 call TS.nextTuple(operationId, iterator);
               );    
  }
  
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){

    CHECK_OP(rdRemId, RELIABLE_OP_FAIL,
             remRdFailed = TRUE;
             );
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 
}

