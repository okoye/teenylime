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
 * *	$Id: AccelSenseTask.nc 883 2009-07-14 12:51:17Z mceriotti $
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
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module AccelSenseTask {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as SensorX;
    interface Read<uint16_t> as SensorY;
    interface Timer<TMilli> as TSensePeriod;

    interface CollectionInfo;
    interface Leds;
    interface GlobalTime;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId;

  // Parameters of currently running sensing task (if any)
  uint16_t currentTick, period, numPeriods;

  uint8_t type = ACCELERATION;
  
  uint16_t msgSeqNum = 0;

  nx_struct opaqueTuple {
    nx_uint8_t type;
    nx_uint8_t accel_type;
    nx_uint16_t address;
    nx_uint16_t seqNum;
    nx_uint16_t size;
    nx_uint16_t time_distance;
    nx_uint16_t value[TUPLE_MSG_PAYLOAD_SIZE/2 - 10];
  };

  bool fw_active = FALSE;

  uint16_t numSamples = (TUPLE_MSG_PAYLOAD_SIZE/2 - 10)/2;

  tuple<uint8_t, uint16_t, uint16_t, 
    uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> readingT;
  nx_struct opaqueTuple* ot;

  event void Boot.booted() {

    readingT = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());
    ot = (nx_struct opaqueTuple *) readingT.value3;
    ot->type = type;
    ot->address = TL_LOCAL;
    ot->accel_type = ADXL203;
    call GlobalTime.startTimer();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTask(tuple<uint8_t, uint8_t, uint16_t, uint16_t> *taskTuple) {
    // A new task description arrived
    if (call TSensePeriod.isRunning()) {
      // Cancel the previous task
      call TSensePeriod.stop();
    } 
    currentTick = 0;
    ot->size = 0;
    period = taskTuple->value2; 
    numPeriods = taskTuple->value3;
    ot->time_distance = period*SECOND/numSamples;

    call TSensePeriod.startPeriodic((uint32_t)period*SECOND/numSamples);
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t> 
      *taskTuple;
    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, uint16_t,
                           uint16_t> *) call TS.nextTuple(operationId, iterator); 
               if (taskTuple != NULL) {
                 startTask(taskTuple);
                 call TS.nextTuple(operationId,iterator);
               });
  }
  
  event void TSensePeriod.fired() {
    currentTick++;
    if (currentTick == (numSamples*period*numPeriods) && 
        numPeriods != INFINITE_OP_TIME) {
      call TSensePeriod.stop();
    }
    call SensorX.read();
  }

  void sendData(){
    TLOpId_t outId;    
    ot->seqNum = msgSeqNum++;
    if (fw_active) {
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &readingT);
    } else {
      msgSeqNum--;
    }
    ot->size = 0;
  }

  event void SensorX.readDone(error_t result, uint16_t val) {
    ot->value[ot->size++] = val;
    if (ot->size >= numSamples*2) {    
      sendData();
    }    
    call SensorY.read();
  }
  
  event void SensorY.readDone(error_t result, uint16_t val) {   
    ot->value[ot->size++] = val;
    if (ot->size >= numSamples*2) {    
      sendData();
    }
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }
  
  task void searchNewTasks() {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t> taskPattern;
    taskPattern = newTuple(
                           actualField(TASK_TYPE),
                           actualField(type),
                           dontCare(),
                           dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }
  
  async event void GlobalTime.timeEvent(){
    post searchNewTasks();
  }

  event void CollectionInfo.forwardingStatus(uint8_t status) {

    switch (status) {

    case FORWARDING_ACTIVE:
      if (!fw_active) {
        fw_active = TRUE;
      }
      break;
      
    case FORWARDING_INACTIVE:
      if (fw_active) {
        fw_active = FALSE;
      }      
      break;
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

