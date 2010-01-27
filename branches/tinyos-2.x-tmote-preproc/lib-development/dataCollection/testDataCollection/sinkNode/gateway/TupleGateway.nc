/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 913 $
 * * DATE
 * *    $LastChangedDate: 2009-10-15 16:26:44 -0500 (Thu, 15 Oct 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleGateway.nc 913 2009-10-15 21:26:44Z mceriotti $
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

#include "TupleSerialMsg.h"
#include "Configuration.h"
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

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> sending;

  tuple<uint8_t, uint16_t, uint16_t, 
    uint8_t[TUPLE_DISS_PAYLOAD_SIZE]> diss_tuple;

  tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint16_t,
    uint16_t> tree_building_tuple;

  task void serialSend();
  task void handleSerialMsg();
  task void buildTree();
  task void disseminateTuples();

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
    call SerialControl.start();
    serialBusy = TRUE;
    installReactions();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
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
                      *) call TS.nextTuple(operationId, iterator);
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
                      *) call TS.nextTuple(operationId, iterator);
               if (rec != NULL) {
                 call TLObjects.copy_tuple((tuple *) &sending, (tuple *) rec);
                 call TS.nextTuple(operationId, iterator);
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

  task void buildTree(){
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tree_building_tuple);
  }
  
  task void disseminateTuples(){
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple*)&diss_tuple);
  }

  task void handleSerialMsg(){
    tuple * t;
    t = (tuple *) temp_serial_msg.data;
    if (isOfType(t,tuple<uint8_t, uint16_t, uint16_t, uint16_t, uint16_t,
                 uint16_t>)){
      call TLObjects.copy_tuple((tuple *) &tree_building_tuple,t);
      post buildTree();
    } else {
      call TLObjects.copy_tuple((tuple *) &diss_tuple,t);
      post disseminateTuples();
    }
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

