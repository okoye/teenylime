/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleGateway.nc 883 2009-07-14 12:51:17Z mceriotti $
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

#include "Constants.h"
#include "Configuration.h"
#include "TupleSerialMsg.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/** 
 * Module that receives and sends data on the serial.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module TupleGateway {

  uses {
    interface Boot;

    interface TupleSpace as TS;

    interface Leds;

    interface AMPacket;

    interface TLObjects;

    interface GlobalTime;
	
    interface Timer<TMilli> as TimerWaitDisseminate;
    interface Timer<TMilli> as TimerWaitSynch;

    interface SplitControl as SerialControl;
    interface AMSend as SerialSend;
    interface Receive as SerialReceive;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  message_t packet;
  tuple_serial_msg_t temp_serial_msg;
  TLOpId_t reactionId;
  TLOpId_t inId, outId;
  bool serialBusy;

/*   bool startSync; */
  uint8_t dissIn, dissOut;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> sending;

  tuple<uint8_t, uint16_t, uint16_t, 
    uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> dissTupleQueue[DISS_SINK_QUEUE_LEN];

  tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, 
    uint16_t> tree_building_tuple;
  
  task void disseminateTuples();
  task void serialSend();
  task void handleSerialMsg();

  void installReactions(){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    p = newTuple(
                 actualField(MSG_TYPE),
                 actualField(TL_LOCAL),
                 dontCare(),
                 dontCare());
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }

  event void Boot.booted() {
/*     startSync = FALSE; */
    dissIn = 0;
    dissOut = 0;
/*     call TimerWait.startOneShot(TUPLE_DISSEMINATION_WAIT_TIME); */
    call SerialControl.start();
    serialBusy = TRUE;
    installReactions();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
    
    call GlobalTime.startTimer();
  }

  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS){
      serialBusy = FALSE;
    } else {
      call SerialControl.start();
    }
  }

  event void SerialControl.stopDone(error_t err) {}

  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *rec;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    
    PROCESS_OP(reactionId, 
               rec = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId,iterator);
               if (!serialBusy){
                 serialBusy = TRUE;
                 p = newTuple(
                              actualField(MSG_TYPE),
                              actualField(TL_LOCAL), 
                              dontCare(),
                              dontCare());
                 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple*)&p);
               });


    PROCESS_OP(inId,
               rec = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId,iterator);
               if (rec != NULL) {
                 call TLObjects.copy_tuple((tuple *) &sending, (tuple *) rec);
                 call TS.nextTuple(operationId,iterator);
                 post serialSend();
               } else {
                 serialBusy = FALSE;
               });
  }
  
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

  event void SerialSend.sendDone(message_t* msg, error_t error) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    atomic{
      if (error != SUCCESS){
        call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple*) &sending);
        serialBusy = FALSE;
      }
    } 
    p = newTuple(
                 actualField(MSG_TYPE),
                 actualField(TL_LOCAL), 
                 dontCare(),
                 dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple*)&p);
  }

  task void serialSend(){
    atomic{   
      tuple_serial_msg_t* msg;
      msg = (tuple_serial_msg_t
             *) call SerialSend.getPayload(&packet);
      call TLObjects.copy_tuple((tuple *) msg->data, (tuple *) &sending);
      if (call SerialSend.send(AM_BROADCAST_ADDR, &packet, 
                               sizeof(tuple_serial_msg_t)) 
          != SUCCESS) {
        call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple*) &sending);
        serialBusy = FALSE;
      }
    }
  }

  event message_t* SerialReceive.receive(message_t* msg, 
                                         void* payload, 
                                         uint8_t len) {
    atomic{
      if (len == sizeof(tuple_serial_msg_t)){
        memcpy(&temp_serial_msg, (tuple_serial_msg_t*) payload, len);
        post handleSerialMsg();
      }
    }
    return msg;
  }

  task void handleSerialMsg(){
    tuple * t;
    t = (tuple *) temp_serial_msg.data;   
    if (isOfType(t,tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint16_t,
                 uint16_t>)){
      call TLObjects.copy_tuple((tuple *) &tree_building_tuple,t);
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tree_building_tuple);
      call TimerWaitSynch.startOneShot(TUPLE_DISSEMINATION_WAIT_TIME);
    } else {
      call TLObjects.copy_tuple((tuple *) &(dissTupleQueue[dissIn]),t);
      dissIn = (dissIn+1) % DISS_SINK_QUEUE_LEN;
      if (dissIn==dissOut){
        post disseminateTuples();
      }
    }
  }
    
  task void disseminateTuples(){
    while (dissOut != dissIn){
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple*)&(dissTupleQueue[dissOut]));
      dissOut = (dissOut+1) % DISS_SINK_QUEUE_LEN;
    }
  }
  
  event void TimerWaitSynch.fired() {
    call GlobalTime.startSync();    
  }
  
  event void TimerWaitDisseminate.fired() {
      post disseminateTuples();
  }
  
  // Needed to avoid asynch call from timeEvent()
  task void startTupleDissemination() {
    call TimerWaitDisseminate.startOneShot(TUPLE_DISSEMINATION_WAIT_TIME);
  }
  
  async event void GlobalTime.timeEvent(){
    post startTupleDissemination();
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

