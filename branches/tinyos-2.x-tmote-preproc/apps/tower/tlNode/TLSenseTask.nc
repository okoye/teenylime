/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1012 $
 * * DATE
 * *    $LastChangedDate: 2010-01-08 03:09:17 -0600 (Fri, 08 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TLSenseTask.nc 1012 2010-01-08 09:09:17Z mceriotti $
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
#include "CollectionInfo.h"

/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module TLSenseTask {

  provides {  
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfTemp;
#ifndef FAKE_LIGHT
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfLight;
#endif
  }

  uses {

    interface Boot;

    interface TupleSpace as TS;

#ifndef FAKE_LIGHT
    interface Read<uint16_t> as ReadLight;
#endif
    interface Read<uint16_t> as ReadTemperature;
    interface Timer<TMilli> as TSensePeriod;

    interface Leds;
    interface GlobalTime;

    interface CollectionInfo;

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
  uint8_t msgType;

  // Temporary var needed for split-phase operations across
  // temperature and humidity sensing
  uint16_t currentTemperature;

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

    // Powering up sensors
    TOSH_MAKE_HUM_PWR_OUTPUT();
    TOSH_SET_HUM_PWR_PIN();

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTemperatureTask(tuple<uint8_t, uint8_t, 
                            uint16_t, uint16_t> *taskTuple) {

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
        msgType = TEMP_LIGHT_END_SESSION;
      } else {
        msgType = TEMP_LIGHT_TYPE;
      }

      call ReadTemperature.read();      
    }
  }

#ifdef FAKE_LIGHT
  void fakeReadLight(error_t result, uint16_t val){
#else
  event void ReadLight.readDone(error_t result, uint16_t val) {
#endif
    TLOpId_t outId;
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> thlReading;
    nx_struct opaqueTupleTemp* ot;
    static uint16_t msgSeqNum = 0;

    thlReading = newTuple(
                           actualField(MSG_TYPE),
                           actualField(TL_LOCAL),
                           actualField(RELIABLE_DELIVERY),
                           arrayField());
    
    ot = (nx_struct opaqueTupleTemp*) thlReading.value3;
    
    // This node does not provide humidity and synth light readings
    ot->type = msgType;
    ot->address = TL_LOCAL;
    ot->seqNum = msgSeqNum++;
    ot->temperature = currentTemperature;
    ot->humidity = 0;
    ot->totalSolar = val;
    ot->photoSynth = 0;
        
    if (fw_active) {
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &thlReading);
    } else {
      msgSeqNum--;
    }

  }

  event void ReadTemperature.readDone(error_t result, uint16_t val) {  
    
    currentTemperature = val;
#ifdef FAKE_LIGHT
    fakeReadLight(SUCCESS, 0);
#else
    call ReadLight.read();
#endif
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
			   actualField(TL_TASK),
			   dontCare(),
			   dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }

  async event void GlobalTime.timeEvent(){
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

  const msp430adc12_channel_config_t configLight = {
      inch: INPUT_CHANNEL_A0,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  const msp430adc12_channel_config_t configTemperature = {
      inch: INPUT_CHANNEL_A1,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

#ifndef FAKE_LIGHT
  async command const msp430adc12_channel_config_t* AdcConfLight.getConfiguration() {
    return &configLight;
  }
#endif

  async command const msp430adc12_channel_config_t* AdcConfTemp.getConfiguration() {
    return &configTemperature;
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

}

