/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 912 $
 * * DATE
 * *    $LastChangedDate: 2009-10-14 07:09:32 -0500 (Wed, 14 Oct 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DTSenseTask.nc 912 2009-10-14 12:09:32Z mceriotti $
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

#include "msp430usart.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "Configuration.h"
#include "TupleSpace.h"
#include "msp430usart.h"

/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define UART_TIMEOUT 3000

module DTSenseTask {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface UartStream;
    interface Resource as UartResource;
    interface Timer<TMilli> as TSensePeriod;
    interface Alarm<TMilli, uint16_t> as UartTimeout;

    interface Read<uint16_t> as ReadTemperature;

    interface Leds;
    interface GlobalTime;


#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfTemp;
}

implementation {

  TLOpId_t inId, inTkId, inNotId, reactionId;

  // Parameters of currently running sensing task (if any)
  uint16_t senseTick, reportTick, currentSamples, 
    samplingPeriod, reportingPeriod, totalSamples;

  // Sensed data
  uint32_t totalTemperature, totalDeformation;
  uint8_t nInputReadings;

  bool tkReactActive;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> token;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> dtReading;

  // Session handling
  norace uint8_t msgType;
  nx_struct opaqueTupleFos {
    nx_uint8_t type;
    nx_uint16_t address;
    nx_uint16_t seqNum;

  };

 nx_struct opaqueTupleDT {
    nx_uint16_t sample_type_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint32_t totalTemperature;
    nx_uint32_t totalDeformation;
    nx_uint8_t nReadings; 
  };

  // See FOS serial protocol
  uint8_t bufferReq[1] = "b";
  uint8_t recv[81];

  uint32_t sum = 0;
  bool task_started;

  bool uartPending = FALSE;

  void processDataA();

  event void Boot.booted() {

   tkReactActive = FALSE; 
    token = newTuple(
                     actualField(MSG_TYPE),
                     dontCare(),
                     actualField(TOKEN),
                     dontCare());

    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &token);  

    // Powering up temperature sensor
    TOSH_MAKE_HUM_PWR_OUTPUT();
    TOSH_SET_HUM_PWR_PIN();

    task_started = FALSE;

    call GlobalTime.startTimer();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startFosTask(tuple<uint8_t, uint8_t, uint16_t, uint16_t, 
                            uint16_t> *taskTuple) {

    // A new task description arrived
    if (call TSensePeriod.isRunning()) {
      // Cancel the previous task
      call TSensePeriod.stop();
    } 

    senseTick = 0;
    reportTick = 0;
    currentSamples = 0;
    nInputReadings = 0;
    totalTemperature = 0;
    totalDeformation = 0;
    samplingPeriod = taskTuple->value2; 
    reportingPeriod = taskTuple->value3; 
    totalSamples = taskTuple->value4;
 
    task_started = TRUE;

    call TSensePeriod.startPeriodic((uint32_t)MINUTE);

    call Leds.led1On();
    
#ifdef PRINTF_SUPPORT
    printf ("S%dR%dT%d\n", samplingPeriod, reportingPeriod, totalSamples);
    call PrintfFlush.flush();
#endif   
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {

    TLOpId_t opId;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t> 
      *taskTuple;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
      *tokenTuple;
    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, uint16_t, uint16_t, 
                           uint16_t> *) call TS.nextTuple(operationId, iterator); 
               if (taskTuple != NULL) {
                 startFosTask(taskTuple);
                 call TS.nextTuple(operationId, iterator);
               });

    PROCESS_OP(reactionId,
               tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
               call TS.nextTuple(operationId,iterator);
               if (tkReactActive){
                 tkReactActive = FALSE;
                 call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, 
                            (tuple *) &token);
               });

    PROCESS_OP(inTkId,
               tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
               call TS.nextTuple(operationId,iterator); 
               if (tokenTuple != NULL) {
                 call TS.nextTuple(operationId,iterator);
                 if (dtReading.value0 == QUEUE){
                   dtReading.value0 = MSG_TYPE;
		   call Leds.led2Off();
                   call TS.out(&opId, FALSE, TL_LOCAL, RAM_TS, 
                               (tuple *) &dtReading);
                 }
               } else {
                 tkReactActive = TRUE;
               });

  }
  
  event void TSensePeriod.fired() {
    
    senseTick++;
    
    if (senseTick % samplingPeriod == 0) {      
      atomic currentSamples++;
      if (currentSamples == totalSamples &&
          totalSamples != INFINITE_OP_TIME) {
	call Leds.led1Off();
        call TSensePeriod.stop();
      } 
      
      //call ReadTemperature.read();      
      //to debug without the sensor, comment above uncomment below
      processDataA();
    }
  }


  event void ReadTemperature.readDone(error_t result, uint16_t val) {  
    
    // Updating temperature
    totalTemperature += val;
    // Sending read request to FOS
    atomic uartPending = TRUE;
    call UartTimeout.start(UART_TIMEOUT);
    call UartResource.request();      
  }

  task void sendStream() {
    // Sending request message
    call UartStream.send(bufferReq,sizeof(bufferReq));
  }

  event void UartResource.granted() {
    // UART resource obtained, running state signaling
    post sendStream();
  }

  async event void UartStream.sendDone(uint8_t* buf, uint16_t len, 
				       error_t error){

    uint8_t i;

    if (error != SUCCESS) {
      post sendStream();
    } else {
      // Waiting for the answer
      call Leds.led0On();
      for (i=0; i<81; i++) {
	recv[i] = 0;
      }
/*       call UartStream.enableReceiveInterrupt();     */
      call UartStream.receive(recv, 81);
    }
  }

  void reboot() {
    WDTCTL = WDT_ARST_1_9; 
    while(1);
  }

  async event void UartTimeout.fired() {

    atomic {
      if (uartPending) {
	uartPending = FALSE;
	call Leds.led0Off();
	reboot();
/* 	call UartResource.release(); */
      }
    }
  }

  task void processData() {
   
    static  uint16_t msgSeqNum = 0;
    uint32_t currentDeformation = 0;
/*     uint8_t i; */
    
/*     atomic { */
/*       for (i=0; i<40; i++) { */
/* 	currentDeformation += (recv[(i*2)+1] << 8) + recv[(i*2)+2]; */
/*       } */
/*     } */

/*     currentDeformation = currentDeformation / 40; */
    atomic currentDeformation = ((recv[1] << 8) + recv[2]);
    totalDeformation += currentDeformation;
    nInputReadings++;

    reportTick++;

    if (reportTick % reportingPeriod == 0
	|| currentSamples == totalSamples) {
    nx_struct opaqueTupleDT* ot;
      
      dtReading = newTuple(
			    actualField(QUEUE),
			    actualField(TL_LOCAL),
			    actualField(RELIABLE_DELIVERY),
			    arrayField());
    
      ot = (nx_struct opaqueTupleDT*) dtReading.value3;

      if (currentSamples == totalSamples && 
          totalSamples != INFINITE_OP_TIME) {
	ot->sample_type_id = DT_END_SESSION;
      } else {
        ot->sample_type_id = DT_TYPE;
      }
      ot->node_id = TL_LOCAL;
      ot->seq_num = msgSeqNum++;
      atomic {
	ot->totalTemperature = totalTemperature; 
	ot->totalDeformation = totalDeformation;
	ot->nReadings = nInputReadings;
	totalTemperature = 0;
	totalDeformation = 0;
	nInputReadings = 0;
      }
      
      if (!tkReactActive){
        call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token);
      } 
    }
  }

  void processDataA(){
      post processData();
};


  async event void UartStream.receiveDone(uint8_t* buf, 
					  uint16_t len, 
					  error_t error ) {
    atomic{
      if (uartPending) {
	uartPending = FALSE;
	call Leds.led0Off();
	call UartTimeout.stop();
	call UartResource.release();
	post processData();
      }
    }
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }
  
  task void searchNewTasks() {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t>
      taskPattern;
    taskPattern = newTuple(
			   actualField(TASK_TYPE),
			   actualField(DT_TASK),
			   dontCare(),
			   dontCare(),
			   dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }
  
  async event void GlobalTime.timeEvent(){
    post searchNewTasks();
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  async event void UartStream.receivedByte(uint8_t byte){
  }

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

  async command const msp430adc12_channel_config_t* AdcConfTemp.getConfiguration() {
    return &configTemperature;
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

