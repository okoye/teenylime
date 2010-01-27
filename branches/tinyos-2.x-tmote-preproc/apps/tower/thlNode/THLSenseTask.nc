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
 * *	$Id: TempSenseTask.nc 296 2008-02-26 18:31:13Z mceriotti $
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
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module THLSenseTask {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as ReadTemp;
    interface Read<uint16_t> as ReadHumidity;
    interface Read<uint16_t> as ReadTotalSolar;
    interface Read<uint16_t> as ReadPhotoSynth;
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
  uint16_t currentTick, period, numSamples;

  // Session handling

  // Session handling
  uint8_t msgType;

  // Temporary var needed for split-phase operations across
  // temperature and humidity sensing
  uint16_t currentTemperature, currentHum, currentTotalSolar;

  nx_struct opaqueTupleTemp {
    nx_uint8_t type;
    nx_uint16_t address;
    nx_uint16_t seqNum;
    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t totalSolar;
    nx_uint16_t photoSynth;
  };


  bool fw_active = FALSE;

  event void Boot.booted() {

    call GlobalTime.startTimer();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTemperatureTask(tuple<uint8_t, uint8_t, uint16_t, 
                            uint16_t> *taskTuple) {
    // A new task description arrived
    if (call TSensePeriod.isRunning()) {
      // Cancel the previous task
      call TSensePeriod.stop();
    } 
    currentTick = 0;
    period = taskTuple->value2; 
    numSamples = taskTuple->value3; 
    call TSensePeriod.startPeriodic((uint32_t)MINUTE);
    
#ifdef PRINTF_SUPPORT
    printf ("T%uN%u\n", period, numSamples);
    call PrintfFlush.flush();
#endif   
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t> 
      *taskTuple;
    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, 
                           uint16_t, uint16_t> *) call TS.nextTuple(operationId,iterator); 
               if (taskTuple != NULL) {
                 startTemperatureTask(taskTuple);
                 call TS.nextTuple(operationId,iterator);
               });
  }
  
  event void TSensePeriod.fired() {
    
    currentTick++;
    
#ifdef PRINTF_SUPPORT
    printf ("P%uTi%uN%u\n", period, currentTick, numSamples);
    call PrintfFlush.flush();
#endif   

    if (currentTick % period == 0) {
      
      if (currentTick == (numSamples*period) && 
          numSamples != INFINITE_OP_TIME) {
        call TSensePeriod.stop();
        msgType = TEMP_HUM_LIGHT_END_SESSION;
      } else {
        msgType = TEMP_HUM_LIGHT_TYPE;
      }

      call ReadTemp.read();      
    }
  }

  event void ReadTemp.readDone(error_t result, uint16_t val) {  
    
    currentTemperature = val;
    call ReadHumidity.read();
  }

  event void ReadHumidity.readDone(error_t result, uint16_t val) {

    currentHum = val;
    call ReadTotalSolar.read();
  }

  event void ReadTotalSolar.readDone(error_t result, uint16_t val) {

    currentTotalSolar = val;
    call ReadPhotoSynth.read();
  }

  event void ReadPhotoSynth.readDone(error_t result, uint16_t val) {

    TLOpId_t outId;
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> thlReading;
    nx_struct opaqueTupleTemp* ot;
    static  uint16_t msgSeqNum = 0;

    thlReading = newTuple(
                           actualField(MSG_TYPE),
                           actualField(TL_LOCAL),
                           actualField(RELIABLE_DELIVERY),
                           arrayField());
    
    ot = (nx_struct opaqueTupleTemp*) thlReading.value3;
    
    ot->type = msgType;
    ot->address = TL_LOCAL;
    ot->seqNum = msgSeqNum++;
    ot->temperature = currentTemperature;
    ot->humidity = currentHum;
    ot->totalSolar = currentTotalSolar;
    ot->photoSynth = val;
        
    if (fw_active) {
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &thlReading);
    } else {
      msgSeqNum--;
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
    tuple<uint8_t, uint8_t, uint16_t, uint16_t>
      taskPattern;
    taskPattern = newTuple(
			   actualField(TASK_TYPE),
			   actualField(THL_TASK),
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

