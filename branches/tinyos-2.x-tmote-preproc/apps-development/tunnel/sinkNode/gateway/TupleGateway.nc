/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1017 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:32:29 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleGateway.nc 1017 2010-01-11 08:32:29Z mceriotti $
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

  nx_struct opaqueTupleSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t value;
  };

  nx_struct opaqueTupleAggSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t parent;
    nx_uint16_t parent_quality;
    nx_uint16_t voltage;
    nx_uint16_t temperature;
  };

  uint16_t msgSeqNum = 0;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> sending;
  
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
    serialBusy = FALSE;
    call SerialControl.start();
    installReactions();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void SerialControl.startDone(error_t err) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    if (err == SUCCESS){
    	atomic{
        if (!serialBusy){
          serialBusy = TRUE;
          p = newTuple(
                       actualField(MSG_TYPE),
                       actualField(TL_LOCAL), 
                       dontCare(),
                       dontCare());
          call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
        }
      }
    } else {
      call SerialControl.start();
    }
  }

  event void SerialControl.stopDone(error_t err) {}

  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *rec;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    nx_struct opaqueTupleSysInfo* ot;
    nx_struct opaqueTupleAggSysInfo* oat;    
    uint16_t parent;

    PROCESS_OP(reactionId, 
               rec = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               call Leds.led0Toggle();
               if (!serialBusy){
                 serialBusy = TRUE;
                 p = newTuple(
                              actualField(MSG_TYPE),
                              actualField(TL_LOCAL), 
                              dontCare(),
                              dontCare());
                 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
               });


    PROCESS_OP(inId,
               rec = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (rec != NULL) {
                 oat = (nx_struct opaqueTupleAggSysInfo*) rec->value3;
                 if(oat->info_type_id == INFO_TYPE_IDENTIFIER &&
                    oat->info_id == AGGREGATED_PERIODIC_INFO){
                   
                   oat->info_type_id = ROUTING_INFO_TYPE;
                   call TLObjects.copy_tuple((tuple *) &sending, (tuple *) rec);

                   ot = (nx_struct opaqueTupleSysInfo*) rec->value3;
                   ot->info_type_id = INFO_TYPE_IDENTIFIER;

                   /* ATTENTION: OVERWRITING OLD INFOS */
                   parent = oat->parent;
                   ot->info_id = BATTERY;
                   ot->value = oat->voltage;
                   call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)rec);

                   ot->seq_num++;
                   ot->info_id = TEMPERATURE;
                   ot->value = oat->temperature;
                   call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)rec);

                   ot->seq_num++;
                   ot->info_id = ROUTING_PARENT;
                   ot->value = parent;
                   call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)rec);

                   ot->seq_num++;
                   ot->info_id = ROUTING_PARENT_LQI;
                   ot->value = oat->parent_quality;
                   call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)rec);

                   post serialSend();
                 } else {
                   call TLObjects.copy_tuple((tuple *) &sending, (tuple *) rec);
                   post serialSend();
                 }
                 call TS.nextTuple(operationId, iterator);

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

  task void reinsertTuple(){
    atomic{
     serialBusy = FALSE;
     call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple*) &sending);
    }
  }

  event void SerialSend.sendDone(message_t* msg, error_t error) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    if (error != SUCCESS){
      post reinsertTuple();
    } else {
      //call Leds.led2Toggle();
      p = newTuple(
                   actualField(MSG_TYPE),
                   actualField(TL_LOCAL), 
                   dontCare(),
                   dontCare());
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
    }
  }

  task void serialSend(){
    tuple_serial_msg_t* msg;
    msg = (tuple_serial_msg_t
           *) call SerialSend.getPayload(&packet);
    call TLObjects.copy_tuple((tuple *) msg->data, (tuple *) &sending);
    if (call SerialSend.send(AM_BROADCAST_ADDR, &packet, 
                             sizeof(tuple_serial_msg_t)) 
        != SUCCESS) {
      post reinsertTuple();
    } else {
      //call Leds.led2Toggle();
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
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)t);
  }
    
  async event void GlobalTime.timeEvent(){
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

