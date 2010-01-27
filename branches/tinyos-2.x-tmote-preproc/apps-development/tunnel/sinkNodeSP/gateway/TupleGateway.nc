/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 18:08:41 +0200 (mer, 15 lug 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleGateway.nc 885 2009-07-15 16:08:41Z mceriotti $
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

#ifdef SERIAL_CONTROL
#define CONTROL_TIME 10000
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
#ifdef SERIAL_CONTROL
    interface Timer<TMilli> as TimerControlSerial;
#endif

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
  bool bootfix = FALSE;
#ifdef SERIAL_CONTROL
  bool controlReset;
  uint16_t booting,in,out,preOut,preOut2,preIn;
#endif

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
    serialBusy = TRUE;
    call SerialControl.start();

#ifdef SERIAL_CONTROL
    controlReset = FALSE;
    booting = 2;
    in = 0;
    out = 0;
    preOut = 0;
    preIn = 0;
#endif

    installReactions();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

#ifdef SERIAL_CONTROL

  void resetControl(){
    atomic{
      WDTCTL = WDT_ARST_250;
      while(1);
    }
  }


  task void sendControl(){
    uint16_t a;
    serial_control_msg_t controlMsg;    
    tuple_serial_msg_t* msg;
    atomic {
      if (!serialBusy){
        bootfix = TRUE;
        serialBusy = TRUE;
        call TimerControlSerial.startOneShot(CONTROL_TIME);
        controlReset = TRUE;
        controlMsg.booting = booting;
        if (booting == 2)
          controlMsg.in = in;
        else 
          controlMsg.in = preIn;
        controlMsg.out = out;
        for(a = 0;a<54;a++)
          controlMsg.buff[a] = 0;
        controlMsg.buff[11] = 3;
 
        msg = (tuple_serial_msg_t
               *) call SerialSend.getPayload(&packet);
        memcpy(msg, &controlMsg, sizeof(serial_control_msg_t));  
        if (call SerialSend.send(AM_BROADCAST_ADDR, &packet, 
                                 sizeof(tuple_serial_msg_t)) 
            != SUCCESS) {
          post sendControl();	
        } else{
        }
      } else{
        controlReset = FALSE;
        call TimerControlSerial.startOneShot(100);

      }
    }
  }
#endif

  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS){
      serialBusy = FALSE;
#ifdef SERIAL_CONTROL
      post sendControl();      
#endif
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

#ifdef SERIAL_CONTROL
    PROCESS_OP(reactionId, 
               rec = (tuple<uint8_t, uint16_t, uint16_t, 
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
                      *) call TS.nextTuple(operationId, iterator);
               if (booting == 1)
                 if (!serialBusy){
                   serialBusy = TRUE;
                   p = newTuple(
                                actualField(MSG_TYPE),
                                actualField(TL_LOCAL), 
                                dontCare(),
                                dontCare()); 

                   call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
                 });
#endif 
#ifndef SERIAL_CONTROL

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

                 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
               });
#endif


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
#ifdef SERIAL_CONTROL
    uint8_t Buff[sizeof(tuple_serial_msg_t)];
    tuple_serial_msg_t* msgS;
    msgS = (tuple_serial_msg_t
            *) call SerialSend.getPayload(&packet);
    memcpy(Buff, msgS, sizeof(tuple_serial_msg_t));  


    atomic{
      if (Buff[17]== 3){
        call Leds.led1Toggle();
        serialBusy = FALSE;
        if (error == SUCCESS){
          out++;
          if (booting == 1){
            preOut2 = out;
            out=0;
          }
          //          if (booting != 2)
          //            out = 0;
        } else {
          post sendControl();
        }

      }else{		
#endif
        if (error != SUCCESS){
          post reinsertTuple();
        } else {
          p = newTuple(
                       actualField(MSG_TYPE),
                       actualField(TL_LOCAL), 
                       dontCare(),
                       dontCare());
#ifdef SERIAL_CONTROL
          if (booting == 1){
            out++;
#endif
            //call Leds.led2Toggle();
            call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS,(tuple*)&p);
#ifdef SERIAL_CONTROL
          }
        }
#endif

      }  
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
    }
  }

  event message_t* SerialReceive.receive(message_t* msg, 
                                         void* payload, 
                                         uint8_t len) {

    serial_control_msg_t *controlMsg;
    //    uint16_t tempOut;
    uint8_t Buff[sizeof(tuple_serial_msg_t)];


    atomic{
      if (len == sizeof(tuple_serial_msg_t)){
#ifdef SERIAL_CONTROL
        //Check if it's a control MSG
        memcpy(Buff, (tuple_serial_msg_t*) payload, len);
        if (Buff[17]== 3){
          controlMsg = payload;
          if ((controlMsg->booting == 2)&&(booting == 2)){
            if (controlMsg->in == out){
              if (in == 1){
                booting = 1;
                preIn = 1;
                preOut = 1;
                out = 0;
                in=0;
                controlReset = FALSE;
              }
              else if (in == 0){
                controlReset = FALSE;
                in++;
                //                post sendControl();
                call TimerControlSerial.startOneShot(1000);
              }
              else
                resetControl();
            }
            else 
              resetControl();
          }
  
          if ((controlMsg->booting == 1) && (booting==1)){     
            call Leds.led2Toggle();
            if (controlMsg->in == preOut ){
              preOut = preOut2;         
              controlReset = FALSE;
              preIn = in + 1;
              in = 0;
            } else //{
              resetControl();
            //controlReset = TRUE; }
          }
        }else {
          if(booting == 1){
#endif
	
            memcpy(&temp_serial_msg, (tuple_serial_msg_t*) payload, len);
            post handleSerialMsg();

#ifdef SERIAL_CONTROL
            in++;
          }
        }
#endif

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
  
#ifdef SERIAL_CONTROL
  event void TimerControlSerial.fired() {
    if (bootfix){
      if (!controlReset)
        post sendControl();
      //I had no answer from the sink, wait 10 sec and reboot
      if (controlReset){
        resetControl();
      } 
    }
  }
#endif

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }
  
  event void PrintfControl.stopDone(error_t error) {
  }
  
  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 
}

