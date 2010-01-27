/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 918 $
 * * DATE
 * *    $LastChangedDate: 2009-10-20 10:31:11 -0500 (Tue, 20 Oct 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TrafficCl2Task.nc 918 2009-10-20 15:31:11Z mceriotti $
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
 * The component in charge of parsing task tuples for class 1 traffic, 
 * and to generate class 1 traffic. 
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module TrafficCl2Task {

  uses {
    interface Boot;
    interface TupleSpace as TS;
    interface Timer<TMilli> as TrafficPeriod;
    interface Timer<TMilli> as TimerSearchTask;
    interface CollectionInfo;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId,reactionId,inTkn,outId,remreactionId;

  // Parameters of currently running sensing task (if any)
  uint16_t currentTick, period, numSamples;
  bool TokenReactionActive;

  // Session handling
  uint8_t msgType;

  nx_struct opaqueTuple {
    nx_uint16_t type;
    nx_uint16_t address;
    nx_uint16_t seqNum;
  };

  
  void sendData();
  task void addTokenReaction();

  event void Boot.booted() {
    call TimerSearchTask.startPeriodic(5000);
    TokenReactionActive = FALSE;
    post addTokenReaction();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTask(tuple<uint8_t, uint8_t, uint16_t, uint16_t, 
                 uint16_t, uint16_t, uint16_t> *taskTuple) {
    // A new task description arrived
    if (call TrafficPeriod.isRunning()) {
      // Cancel the previous task
      call TrafficPeriod.stop();
    } 
    if (TL_LOCAL % taskTuple->value6 != 0){
      call Leds.led2Toggle();
      currentTick = 0;
      period = taskTuple->value3; 
      numSamples = taskTuple->value4; 
      call TrafficPeriod.startPeriodic((uint32_t)MINUTE);
    } 
#ifdef PRINTF_SUPPORT
    printf ("CL2P%uN%uC%u\n", period, numSamples, taskTuple->value6);
    call PrintfFlush.flush();
#endif   
  }
  
  task void addTokenReaction(){
    /*Token Reaction*/
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> msg_react;
    msg_react = newTuple(
                         actualField(MSG_TYPE),
                         dontCare(),
                         actualField(TOKEN),
                         dontCare() );
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &msg_react);  
  }

  void sendData(){
    /*Send My data*/
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> class2msg;
    nx_struct opaqueTuple* ot;
    static  uint16_t msgSeqNum = 0;
    class2msg = newTuple(
                         actualField(MSG_TYPE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
      
    ot = (nx_struct opaqueTuple*) class2msg.value3;
    ot->type = msgType;
    ot->address = TL_LOCAL;
    ot->seqNum = msgSeqNum++;        
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &class2msg);    
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>  *taskTuple;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *rec; 
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> msg_type_tuple; 


    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, 
                            uint16_t, uint16_t, uint16_t, uint16_t,
                            uint16_t> *) call TS.nextTuple(operationId,
                                                           iterator);
               if (taskTuple != NULL) {
                 startTask(taskTuple);
                 call Leds.led1Toggle();
                 call TS.nextTuple(operationId, iterator);
               });

    PROCESS_OP(inTkn,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId,iterator);
               /*if there is a token then I can send a message*/
               if (rec != NULL){
                 /*remove Token from TS*/
                 call TS.nextTuple(operationId,iterator);
                 sendData();
                 if (TokenReactionActive){
                   TokenReactionActive = FALSE;
                 }
               } else {
                 /*Install the reaction*/
                 TokenReactionActive = TRUE;
               } 
               );            

    PROCESS_OP(reactionId,
               if (TokenReactionActive == TRUE){	
                 rec = (tuple<uint8_t, uint16_t, uint16_t,
                        uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                        *) call TS.nextTuple(operationId,iterator);
                 /*I have recieved a Token and I have a message to send*/
                 /*Token msg-type to be searched in the local TS*/
                 msg_type_tuple = newTuple (
                                            actualField(MSG_TYPE),
                                            actualField(TL_LOCAL),
                                            actualField(TOKEN),
                                            dontCare() );
                 call TS.in(&inTkn, FALSE, TL_LOCAL, RAM_TS,(tuple *) rec);
               });                             
  }
  
  event void TrafficPeriod.fired() {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> TokenMsg;
    currentTick++;
    if (currentTick % period == 0){
      call Leds.led0Toggle();
      if (currentTick == numSamples*period && 
          numSamples != INFINITE_OP_TIME) {
        call TrafficPeriod.stop();
        msgType = CLASS_2_END_SESSION;
      } else {
        msgType = CLASS_2_TYPE;
      }
      if (!TokenReactionActive){
        TokenMsg = newTuple (
                             actualField(MSG_TYPE),
                             actualField(TL_LOCAL),
                             actualField(TOKEN),
                             dontCare() );
        call TS.in(&inTkn, FALSE, TL_LOCAL, RAM_TS,(tuple *) &TokenMsg); 
      }
    }
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
                                   TLOpId_t operationId, 
                                   TLTarget_t target,  
                                   TLTupleSpace_t ts,
                                   tuple* returningTuple){
    CHECK_OP(remreactionId, OP_COMPLETED_OK,
             call Leds.led1On();				   
             );
  }
  
  task void searchNewTasks() {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>
      taskPattern;
    taskPattern = newTuple(
                           actualField(TASK_TYPE),
                           actualField(CLASS_2_TASK),
                           dontCare(),
                           dontCare(),
                           dontCare(),
                           dontCare(),
                           dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }
  
  event void TimerSearchTask.fired(){
    post searchNewTasks();
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

