/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 310 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 18:31:52 +0200 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: VibrSenseTask.nc 310 2008-03-04 16:31:52Z lmottola $
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
#include "CollectionInfo.h"
#include "TupleSpace.h"
#include "TimeSynchConf.h"
#include "Msp430Adc12.h"

/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */
  
#define VIBR_BLOCKS 2 
#define FLASH_TIMEOUT 5000
#define SLOW_START_QUANTUM 25

// Defined in 32Khz (1 sec)
#define SENSOR_BOOT_TIMER 32767

module VibrSenseTaskFRAM {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Alarm<TMilli, uint16_t> as VSensePeriod;
    interface Alarm<T32khz, uint16_t> as VSenseSample;
    interface Timer<TMilli> as VReport;
/*     interface Timer<TMilli> as FlashReadDelay; */
    interface Alarm<TMilli, uint16_t> as FlashReadDelay;

    // For battery monitoring
    interface Timer<TMilli> as BatteryMonitor;

    interface Tuning;  

    interface Fm25lcSpi as FRAM;
    interface Resource as FRAMResource;

    interface Msp430Adc12MultiChannel as AccelRead;
    interface Msp430Adc12SingleChannel as BatteryReadADC;
    interface Resource as ResourceAccelRead;

    interface Compression;

    interface Leds;
    interface GlobalTime;

    interface CollectionInfo;
#ifdef ROUTING_MONITOR
    interface CollectionDebug;
#endif
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {  
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcAccelConf;
  }
}

implementation {

  enum {
    INACTIVE,
    SENSING,
    REPORTING,
    FORMATTING
  };
  uint8_t state = INACTIVE;

  bool fw_active = FALSE;
  bool reading_from_fram = FALSE;
  bool senseperiodstarted = FALSE;

  typedef struct vibration_block_t {
    bool last; 
    uint8_t valuesWritten;
    uint8_t dataX[VIBR_BLOCK_SIZE];  
    uint8_t dataY[VIBR_BLOCK_SIZE];  
    uint8_t dataZ[VIBR_BLOCK_SIZE];  
  } vibration_block_t;
  vibration_block_t localBuffers[VIBR_BLOCKS];

  typedef struct compressed_vibration_block_t {
    uint8_t sizeX;
    uint8_t sizeY;
    uint8_t sizeZ;
  } compressed_vibration_block_t;
  compressed_vibration_block_t compressedBuffer;
  uint8_t sentDataX, sentDataY, sentDataZ;

  // If this is modified, change OPAQUE_PAYLOAD_SIZE accordingly
#define OPAQUE_PAYLOAD_SIZE TUPLE_MSG_PAYLOAD_SIZE-7
  nx_struct opaqueVibration {
    nx_uint8_t type;
    nx_uint8_t axis;
    nx_uint16_t address;
    nx_uint16_t seqNum;
    nx_uint8_t size;
    nx_uint8_t vibrData[OPAQUE_PAYLOAD_SIZE];
  };
  TLOpId_t inId;
  
  // Most recent ADC readings
  uint16_t currentReadX, currentReadY, currentReadZ;
  
  // Managing blocks in flash
  uint8_t currentBlock = 0;
  norace uint8_t storeBlockNumber; 

  // Flash address management 
  norace uint32_t currentWAddr;
  norace uint32_t currentRAddr;  

  // Flags for memory operation  
  norace bool mem_reading = FALSE;
  norace bool mem_writing = FALSE;

  // To allow for continous ADC conversion
  adc12memctl_t memctl_additional[2];
  uint16_t senseBuffer[3];
  const msp430adc12_channel_config_t configX = {
      inch: INPUT_CHANNEL_A3,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_2_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  // For battery voltage reading
  uint16_t senseBufferBattery[2];
  adc12memctl_t memctl_additional_battery[1];
  bool batteryReading = FALSE;
  uint8_t minuteTick = 0;
#ifndef ROUTING_MONITOR
  nx_struct opaqueTupleSysInfo {
    nx_uint8_t type;
    nx_uint16_t address;
    nx_uint16_t parent;
    nx_uint16_t parentCost;
    nx_uint16_t voltage;
  };
#endif 
  norace uint16_t batteryVal = 0;

  // Kept this here for reference
/*   const msp430adc12_channel_config_t configADCBattery = { */
/*       inch: SUPPLY_VOLTAGE_HALF_CHANNEL, */
/*       sref: REFERENCE_VREFplus_AVss, */
/*       ref2_5v: REFVOLT_LEVEL_1_5, */
/*       adc12ssel: SHT_SOURCE_ACLK, */
/*       adc12div: SHT_CLOCK_DIV_1, */
/*       sht: SAMPLE_HOLD_4_CYCLES, */
/*       sampcon_ssel: SAMPCON_SOURCE_SMCLK, */
/*       sampcon_id: SAMPCON_CLOCK_DIV_1 */
/*   }; */

  // Parameters of currently running sensing task (if any)
  uint16_t currentSamples;
  uint16_t currentTick, senseInterval,  totalSamples, period, numSessions;

  // Information used to adapt the sending rate
  norace uint32_t startReporting;
  uint16_t sentMsgs;  
  uint8_t slowStartState;

#ifdef ROUTING_MONITOR
  nx_struct opaqueTupleSysInfo {
    nx_uint8_t type; //1
    nx_uint16_t seq_no; //3
    nx_uint16_t address; //5
    nx_uint16_t voltage; //7
    nx_uint16_t parent; //9
    nx_uint16_t parent_cost; //11
    nx_uint16_t parent_changes; //13
    nx_uint16_t root_congestions; //15
    nx_uint16_t subtree_congestions; //17
    nx_uint16_t msg_deleted_buffer_overflow; //19
    nx_uint16_t successful_recoveries; //21
    nx_uint16_t failed_recoveries; //23
    nx_uint16_t rd_retries; //25
  };

  nx_struct opaqueTupleSysInfo page_I;

  nx_struct opaqueTupleSysAdvInfo {
    nx_uint8_t type; //1
    nx_uint16_t seq_no; //3
    nx_uint16_t address; //5
    nx_uint16_t packets_forwarded[3]; //11
    nx_uint16_t retries[3]; //17
    nx_uint16_t dropped_duplicates; //19
    nx_uint16_t out_retries; //21
    nx_uint16_t total_send; //23
    nx_uint16_t total_retxmit; //25
  };

  nx_struct opaqueTupleSysAdvInfo page_II;
  uint16_t seq_no;
#endif

/*   bool firstSession = TRUE; */

  bool memBusy() {
    return (mem_reading || mem_writing);
  }

  // The timings are tuned to so that 
  uint16_t evaluateReportRate() {

    static uint16_t previousReportRate;
    uint32_t reportRate, reportingTime = 0;
    uint16_t remainingMsgs = 0;

    // Just (re)started
    if (slowStartState == 0) {

      // SENSOR_BOOT_TIMER and senseInterval are in 32Khz
      uint16_t payloadSize = OPAQUE_PAYLOAD_SIZE; // Hack to avoid cast issues
      reportingTime = ((uint32_t)MINUTE * period) - // Total time
	((uint32_t)SENSOR_BOOT_TIMER*1000/32767 + 2*MINUTE + // Constants
	 (((uint32_t)senseInterval*1000/32767 * 
	   (uint32_t)totalSamples)) + // Sensing time
	 FLASH_TIMEOUT * (1+ ((uint32_t)totalSamples / VIBR_BLOCK_SIZE))); // Pauses times for flash 
      
      // Msgs still to be sent for this session
      atomic {
	remainingMsgs =
	  ((3*(1+((uint16_t)VIBR_BLOCK_SIZE
		  / payloadSize))) * // Msgs per block
	   (1+ ((uint32_t)totalSamples / VIBR_BLOCK_SIZE))) - // Number of blocks used
	  sentMsgs;
	reportRate = ((uint32_t)(reportingTime -
				 (call VReport.getNow()
				  -startReporting))) /
	  remainingMsgs;
      }
    } else {
      // Trying to speed up
      reportRate = previousReportRate;
    }
 
    if (reportRate > MIN_CLASS_1_REPORT_INTERVAL) {
      // Can still push
      slowStartState++;
      if (reportRate > slowStartState*SLOW_START_QUANTUM) {
	reportRate = reportRate - slowStartState*SLOW_START_QUANTUM;
      } else {
	reportRate = MIN_CLASS_1_REPORT_INTERVAL;
      }
      if (reportRate > MAX_CLASS_1_REPORT_INTERVAL)
        reportRate = MAX_CLASS_1_REPORT_INTERVAL;
      previousReportRate = reportRate;
#ifdef PRINTF_SUPPORT
      printf("ssp%drt%lurm%dt%lu\n",slowStartState, reportingTime,
      	     remainingMsgs, reportRate);
      call PrintfFlush.flush();
#endif
      return reportRate;
    } else {
      // Reached max speed
      previousReportRate = MIN_CLASS_1_REPORT_INTERVAL;
#ifdef PRINTF_SUPPORT
      printf("sss%drt%lurm%dt%lu\n",slowStartState, reportingTime,
      	     remainingMsgs, reportRate);
      call PrintfFlush.flush();
#endif
      return MIN_CLASS_1_REPORT_INTERVAL;
    }
  }
  
  void reinitBlock(uint8_t block) {
    
    uint8_t i;
    
    atomic {
      localBuffers[block].last = FALSE; 
      localBuffers[block].valuesWritten = 0;
      
      for (i=0; i<VIBR_BLOCK_SIZE; i++) { 
	localBuffers[block].dataX[i] = 0;
	localBuffers[block].dataY[i] = 0;  
	localBuffers[block].dataZ[i] = 0;  
      }
    }
  }

  event void FRAMResource.granted() {

    if (mem_reading) {
      if (call FRAM.read(currentRAddr, (uint8_t*)&(localBuffers[0]),
			 sizeof(vibration_block_t)) != SUCCESS) {
	call Leds.led0On();
#ifdef PRINTF_SUPPORT
	printf("RE\n");
	call PrintfFlush.flush();
#endif
      }      
    } else {
	if (call FRAM.pageProgram(currentWAddr, 
				  (uint8_t*)&(localBuffers[storeBlockNumber]), 
				  sizeof(vibration_block_t)) != SUCCESS) {
	  call Leds.led0On();
#ifdef PRINTF_SUPPORT
	  printf("WE\n");
	  call PrintfFlush.flush();
#endif
	}
    }
  }

  task void readCurrentBlock() {
    mem_reading = TRUE;
    call FRAMResource.request();
  }  

  task void shutRadioOff() {
    call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF);
  }
  
  task void turnRadioOn() {
    // Restarts radio
    call Tuning.set(KEY_RADIO_CONTROL, RADIO_ON);
  }

  async event void FlashReadDelay.fired() {
    post shutRadioOff();
  }

  event void Tuning.setDone(uint8_t key, uint16_t value){

    uint8_t currentState;    
    atomic currentState = state;

    if (key == KEY_RADIO_CONTROL) {
      if (value == RADIO_ON && currentState == REPORTING) {

	atomic {
	  compressedBuffer.sizeX = call Compression.compressX(localBuffers[0].dataX,
							      localBuffers[0].valuesWritten,
							      localBuffers[1].dataX);
	  compressedBuffer.sizeY = call Compression.compressY(localBuffers[0].dataY,
							      localBuffers[0].valuesWritten,
							      localBuffers[1].dataY);
	  compressedBuffer.sizeZ = call Compression.compressZ(localBuffers[0].dataZ,
							      localBuffers[0].valuesWritten,
							      localBuffers[1].dataZ);
	}
	sentDataX = 0; 
	sentDataY = 0;
	sentDataZ = 0;
	reading_from_fram = FALSE;

  if (fw_active)
	call VReport.startOneShot(FLASH_TIMEOUT);

#ifdef PRINTF_SUPPORT
	/*       printf("X%d-%d\n",bufferLen, compressedBuffer.sizeX); */
	call PrintfFlush.flush();
#endif	
      } else if (value == RADIO_OFF && currentState == FORMATTING) {
	// Proceeds to sensing 
	call Leds.led1On();
	call Leds.led2Off();
	currentRAddr = 0;
	currentWAddr = 0;
	// Configures and starts the ADC conversion
	call AccelRead.configure(&configX, memctl_additional,
				 2, senseBuffer, 3, 0);
	call AccelRead.getData();
	atomic state = SENSING;
      } else if (value == RADIO_OFF && currentState == REPORTING) {
	post readCurrentBlock();
      }
    }
  }

  event void Boot.booted() {

    uint8_t i;
#ifdef ROUTING_MONITOR
    seq_no = 0;
    page_I.type = ROUTING_INFO_TYPE_I;
    page_I.seq_no = 0;
    page_I.address = TL_LOCAL;
    page_I.voltage = 0;
    page_I.parent = TL_LOCAL;
    page_I.parent_cost = 0;
    page_I.parent_changes = 0;
    page_I.root_congestions = 0;
    page_I.subtree_congestions = 0;
    page_I.msg_deleted_buffer_overflow = 0;
    page_I.successful_recoveries = 0;
    page_I.failed_recoveries = 0;
    page_I.rd_retries = 0;
    
    page_II.type = ROUTING_INFO_TYPE_II;
    page_II.seq_no = 0;
    page_II.address = TL_LOCAL;
    page_II.packets_forwarded[0] = 0;
    page_II.packets_forwarded[1] = 0;
    page_II.packets_forwarded[2] = 0;
    page_II.retries[0] = 0;
    page_II.retries[1] = 0;
    page_II.retries[2] = 0;
    page_II.dropped_duplicates = 0;
    page_II.out_retries = 0;
    page_II.total_send = 0;
    page_II.total_retxmit = 0;
#endif

    TOSH_ASSIGN_PIN(ADC5, 6, 5);
    // Configure acceleration sensor
    TOSH_MAKE_GIO2_OUTPUT();
    TOSH_MAKE_ADC5_OUTPUT();
    // Power up acceleration sensor
    TOSH_SET_GIO2_PIN();
    TOSH_SET_ADC5_PIN();

    // Y axis
    memctl_additional[0].inch = INPUT_CHANNEL_A2;
    memctl_additional[0].sref = REFERENCE_VREFplus_AVss;
    memctl_additional[0].eos = 0;

    // Z axis
    memctl_additional[1].inch = INPUT_CHANNEL_A4;
    memctl_additional[1].sref = REFERENCE_VREFplus_AVss;
    memctl_additional[1].eos = 1;

    // Battery
    memctl_additional_battery[0].inch = SUPPLY_VOLTAGE_HALF_CHANNEL;
    memctl_additional_battery[0].sref = REFERENCE_VREFplus_AVss;
    memctl_additional_battery[0].eos = 1;
    
    call ResourceAccelRead.request();

    for (i=0; i<VIBR_BLOCKS; i++) {
      reinitBlock(i);
    } 

    call GlobalTime.startTimer();    
    call BatteryMonitor.startPeriodic(MINUTE);
  
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator){
    
    uint32_t temp;
    uint16_t msgs = 0;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t>
      *rcv;

    PROCESS_OP(inId,
               rcv = (tuple<uint8_t, uint8_t, uint16_t, uint16_t, 
                      uint16_t> *) call TS.nextTuple(operationId,iterator);
	       if (rcv != NULL) {
		 /*  Hack to avoid cast issues */
		 uint16_t payloadSize = OPAQUE_PAYLOAD_SIZE; 
		 
		 /* A new task description arrived */
		 if (call VSensePeriod.isRunning()) {
		   /* Cancel the previous task */
		   call VSensePeriod.stop();
		 } 
		 		 
		 temp = ((uint32_t)32767)*((uint32_t)1000000/rcv->value2);
		 senseInterval = (uint16_t)(temp/1000000);
		 totalSamples = rcv->value2 * rcv->value3; 
		 
		 currentTick = 0;
		 msgs = ((3*(1+((uint16_t)VIBR_BLOCK_SIZE
				/ payloadSize))) * 
			 (1+ ((uint16_t)totalSamples / VIBR_BLOCK_SIZE)));

		 /* Total task period in MINUTE */
		 period =  ((uint32_t)msgs * 2 * MIN_CLASS_1_REPORT_INTERVAL / MINUTE) + /*  Estimated reporting time */
		   ((uint32_t)SENSOR_BOOT_TIMER*1000/(32767*(uint32_t)MINUTE)) + /* Constants */
		   ((uint32_t)EPOCH_RATE * SYNCH_PERIOD / MINUTE) + /* TimeSynch period */ 
		   (((uint32_t)senseInterval*totalSamples*1000/(32767*(uint32_t)MINUTE))) + /* Sensing time */
		    (((1 + ((uint32_t)totalSamples / VIBR_BLOCK_SIZE))*(uint32_t)FLASH_TIMEOUT) / MINUTE ); /* Pauses times for flash */
	 
		 numSessions = rcv->value4; 
      
		 call TS.nextTuple(operationId,iterator);
		 senseperiodstarted = TRUE;
		 call VSensePeriod.start(MINUTE);
	       });
 
#ifdef PRINTF_SUPPORT
    printf("M%dTp%d\n",msgs,period);
    call PrintfFlush.flush();
#endif
  }
  
  task void searchNewTasks() {

    uint8_t currentState;
    atomic currentState = state;

    // Look for a new task only when it's INACTIVE
    if (currentState == INACTIVE) {
      tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t>
	taskPattern;
      taskPattern = newTuple(
			     actualField(TASK_TYPE),
			     actualField(VIBRATION_TASK),
			     dontCare(),
			     dontCare(),
			     dontCare());
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
    }
  }

  async event void GlobalTime.timeEvent(){
    post searchNewTasks();
  }

  task void startNewSession() {

    uint8_t currentState;
    atomic currentState = state;

    // Init a new session if INACTIVE, otherwise skip 
    if (currentTick % period == 0 && currentState == INACTIVE) { 
            
      atomic{

	currentSamples = 0;
	sentMsgs = 0;
	
	// Starts formatting
	call Leds.led1On();
	call Leds.led2On();

	// Triggers sensing
	call VSenseSample.start(SENSOR_BOOT_TIMER);
	
	// Turns the radio off while formatting
	state = FORMATTING;
	post shutRadioOff();
	/* 	  call Leds.led0On(); */
	/* 	  call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF); */
      }
    } else if (currentTick % period == 0 && currentState != INACTIVE) {
      // Skipping sensing: realign the report rate to a new session
      startReporting = call VReport.getNow();
    }

    currentTick++;    
    if (currentTick == (numSessions*period) 
	&& numSessions != INFINITE_OP_TIME) {
      // Stop the task
      currentTick = 0; 
    } else {
      call VSensePeriod.start(MINUTE);
    }

  }

  async event void VSensePeriod.fired() {
    if (senseperiodstarted)
      post startNewSession();
  }
 
  task void storeData() {
    
    if (!memBusy()) {
      mem_writing = TRUE;
      call FRAMResource.request();
    } else {
      post storeData();
    }
  }
    
  async event void FRAM.pageProgramDone( Fm25lc_addr_t addr, uint8_t* buf, 
					 Fm25lc_len_t len, error_t error ){

    if (error != SUCCESS) {
      call Leds.led0On();
    } else {
      bool lastBlock;
      atomic lastBlock = localBuffers[storeBlockNumber].last;

      mem_writing = FALSE;
      call FRAMResource.release();

      currentWAddr += len;  

      // If the block I just wrote is the last one, 
      // let's start reporting      
      if (lastBlock) {
	
	// Start reporting
	atomic state = REPORTING;
	startReporting = call VReport.getNow();
	
	call FlashReadDelay.start(FLASH_TIMEOUT);
      }
    }
  }
  
  
  void dump(uint8_t values, uint8_t block, bool last){

    atomic{
      storeBlockNumber = block; 
      localBuffers[block].last = last;
      localBuffers[block].valuesWritten = values;  
      post storeData();
    }
  }

  async event void FRAM.readDone( Fm25lc_addr_t addr, uint8_t* buf, 
				  Fm25lc_len_t len, error_t error ){
  
    if (error != SUCCESS) {
      call Leds.led0On();      
    } else {

      mem_reading = FALSE;
      currentRAddr += len;

      call FRAMResource.release();

      call Leds.led1Off();
      call Leds.led2On();      

      post turnRadioOn();
    }
  }

  bool sendDataAxis(uint8_t* sentData, uint8_t bufferSize, 
		    uint8_t* buffer, uint8_t axis, bool *done, 
		    nx_struct opaqueVibration* ot) {

    if (*sentData < bufferSize) { 
      if (bufferSize - *sentData > OPAQUE_PAYLOAD_SIZE) {
	// Message completely filled up, and still not done
	memcpy (&ot->vibrData, buffer, OPAQUE_PAYLOAD_SIZE);
	ot->size = OPAQUE_PAYLOAD_SIZE;
	*sentData += OPAQUE_PAYLOAD_SIZE;
      } else {
	// Last message
	memcpy (&ot->vibrData, buffer, bufferSize - *sentData);
	ot->size = bufferSize - *sentData;
	*sentData = bufferSize;
	*done = TRUE;
      }
      ot->axis = axis;
      return TRUE; 
    }
    return FALSE; 
  }

  event void VReport.fired() {

    // TODO: Flags and sendAxis may be packed in a single byte

    // Data for generating messages
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> vibrReading;
    nx_struct opaqueVibration* ot;
    TLOpId_t outId;
    bool lastBlock;

    // Decides what axis data is to be sent
    static uint8_t sendAxis = X_AXIS;
    static uint16_t msgSeqNum = 0;

    // Session handling 
    static bool doneX = FALSE;
    static bool doneY = FALSE;
    static bool doneZ = FALSE;
    bool sent = FALSE;

    vibrReading = newTuple(
			   actualField(MSG_TYPE),
			   actualField(TL_LOCAL),
			   actualField(RELIABLE_DELIVERY),
			   arrayField());    
    ot = (nx_struct opaqueVibration*) vibrReading.value3;      
    
    while (!sent && !(doneX && doneY && doneZ)) {
      
      switch (sendAxis) {
	
      case X_AXIS:
	sent = sendDataAxis(&sentDataX, compressedBuffer.sizeX, 
			    &(localBuffers[1].dataX[sentDataX]), X_AXIS, &doneX, ot);
	sendAxis = Y_AXIS;
	break;
	
      case Y_AXIS:
	sent = sendDataAxis(&sentDataY, compressedBuffer.sizeY, 
			    &(localBuffers[1].dataY[sentDataY]), Y_AXIS, &doneY, ot);
	sendAxis = Z_AXIS;
	break;
	
      case Z_AXIS:
	sent = sendDataAxis(&sentDataZ, compressedBuffer.sizeZ, 
			    &(localBuffers[1].dataZ[sentDataZ]), Z_AXIS, &doneZ, ot);
	sendAxis = X_AXIS;
	break;
      }
    }
    
    // Deciding on msg type 
    atomic lastBlock = localBuffers[0].last;
    if (lastBlock && doneX && doneY && doneZ) {
      ot->type = VIBRATION_END_SESSION;
/*       firstSession = !firstSession; */
    } else {
      ot->type = VIBRATION_TYPE;
    }    
    ot->address = TOS_NODE_ID;
    ot->seqNum = msgSeqNum++;
    sentMsgs++;
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &vibrReading);
    
    if (!doneX || !doneY || !doneZ) {
      // Possily more messages need to be sent for this block
      if (fw_active) {
	call VReport.startOneShot(evaluateReportRate()); 
      }
    } else if (doneX && doneY && doneZ && !lastBlock) {
      // If the current block is not the last, proceed to the next block
      doneX = FALSE; doneY = FALSE; doneZ = FALSE;   

      reading_from_fram = TRUE;
      call FlashReadDelay.start(FLASH_TIMEOUT);
    } else { 
      // No more messages to send, reset in preparation for next session     
      sendAxis = X_AXIS;
      doneX = FALSE; doneY = FALSE; doneZ = FALSE;   
      call Leds.led2Off();      
      atomic state = INACTIVE;
    }
  }
  
  async event void VSenseSample.fired() {
    
    static bool completedPadding;
    static uint8_t currentDataBlock = 0;

    // Flash not ready yet
    if (state != SENSING) {
      call VSenseSample.start(SENSOR_BOOT_TIMER);
      return;
    }

    // Rescheduling timer
    currentSamples++;    
    if (currentSamples < totalSamples) {
      call VSenseSample.start(senseInterval);
    } 

    if (currentDataBlock == 0) { 
      completedPadding = FALSE;
    }
    

    // Concatenate 12-bits values
    if (!completedPadding) {
      /* #ifdef PRINTF_SUPPORT */
      /* 	printf("R%u-%u-%u", currentReadX, */
      /* 	       currentReadX & 0x00FF, currentReadX & 0x0F00); */
      /* #endif */
      atomic {
	/// FAKE: simulating node 144!!!!!
/* 	if (firstSession) { */
/* 	  currentReadX = 2013; */
/* 	  currentReadY = 1963; */
/* 	  currentReadZ = 2917; */
/* 	} else { */
/* 	  currentReadX = 1024; */
/* 	  currentReadY = 2048; */
/* 	  currentReadZ = 4095; */
/* 	} */
	  /// FAKE!!!!!
	localBuffers[currentBlock].dataX[currentDataBlock] = (currentReadX & 0x00FF);
	localBuffers[currentBlock].dataX[currentDataBlock+1] = 0;
	localBuffers[currentBlock].dataX[currentDataBlock+1] = (currentReadX & 0x0F00) >> 8;
	localBuffers[currentBlock].dataY[currentDataBlock] = currentReadY & 0x00FF;
	localBuffers[currentBlock].dataY[currentDataBlock+1] = 0;
	localBuffers[currentBlock].dataY[currentDataBlock+1] = (currentReadY & 0x0F00) >> 8;
	localBuffers[currentBlock].dataZ[currentDataBlock] = currentReadZ & 0x00FF;
	localBuffers[currentBlock].dataZ[currentDataBlock+1] = 0;
	localBuffers[currentBlock].dataZ[currentDataBlock+1] = (currentReadZ & 0x0F00) >> 8;

      }
      currentDataBlock += 1;
      completedPadding = TRUE;
    } else {
      /* #ifdef PRINTF_SUPPORT */
      /* 	printf("R%u-%u-%u", currentReadX, */
      /* 	       currentReadX & 0x000F, currentReadX & 0x0FF0); */
      /* #endif */
      atomic {
	/// FAKE: simulating node 144!!!!!
/* 	if (firstSession) { */
/* 	  currentReadX = 2008; */
/* 	  currentReadY = 1963; */
/* 	  currentReadZ = 2917; */
/* 	} else { */
/* 	  currentReadX = 2410; */
/* 	  currentReadY = 2048; */
/* 	  currentReadZ = 4095; */
/* 	} */
	/// FAKE!!!!!
	localBuffers[currentBlock].dataX[currentDataBlock] |= (currentReadX & 0x000F) << 4;
	localBuffers[currentBlock].dataX[currentDataBlock+1] = (currentReadX & 0x0FF0) >> 4;
	localBuffers[currentBlock].dataY[currentDataBlock] |= (currentReadY & 0x000F) << 4;
	localBuffers[currentBlock].dataY[currentDataBlock+1] = (currentReadY & 0x0FF0) >> 4;
	localBuffers[currentBlock].dataZ[currentDataBlock] |= (currentReadZ & 0x000F) << 4;
	localBuffers[currentBlock].dataZ[currentDataBlock+1] = (currentReadZ & 0x0FF0) >> 4;
      }
      /* #ifdef PRINTF_SUPPORT */
      /* 	printf("S%u-%u", localBuffers[currentBlock].dataX[currentDataBlock], */
      /* 	       localBuffers[currentBlock].dataX[currentDataBlock+1]); */
      /* #endif */
      currentDataBlock += 2;
      completedPadding = FALSE;
    }
    
    // Concatenate 12-bits values - different way
    /*       if (!completedPadding) { */
    /* 	localBuffers[currentBlock].dataX[currentDataBlock] = (currentReadX & 0x00FF); */
    /* 	localBuffers[currentBlock].dataX[currentDataBlock+2] = 0; */
    /* 	localBuffers[currentBlock].dataX[currentDataBlock+2] = (currentReadX & 0x0F00) >> 8; */
    /* 	localBuffers[currentBlock].dataY[currentDataBlock] = currentReadY & 0x00FF; */
    /* 	localBuffers[currentBlock].dataY[currentDataBlock+2] = 0; */
    /* 	localBuffers[currentBlock].dataY[currentDataBlock+2] = (currentReadY & 0x0F00) >> 8; */
    /* 	localBuffers[currentBlock].dataZ[currentDataBlock] = currentReadZ & 0x00FF; */
    /* 	localBuffers[currentBlock].dataZ[currentDataBlock+2] = 0; */
    /* 	localBuffers[currentBlock].dataZ[currentDataBlock+2] = (currentReadZ & 0x0F00) >> 8; */
    /* #ifdef PRINTF_SUPPORT */
    /* 	printf("S%u-%u", localBuffers[currentBlock].dataX[currentDataBlock], */
    /* 	       localBuffers[currentBlock].dataX[currentDataBlock+1]); */
    /* #endif */
    /* 	currentDataBlock += 1; */
    /* 	completedPadding = TRUE; */
    /*       } else { */
    /* 	localBuffers[currentBlock].dataX[currentDataBlock] = (currentReadX & 0x00FF); */
    /* 	localBuffers[currentBlock].dataX[currentDataBlock+1] |= (currentReadX & 0x0F00) >> 4; */
    /* 	localBuffers[currentBlock].dataY[currentDataBlock] = (currentReadY & 0x00FF); */
    /* 	localBuffers[currentBlock].dataY[currentDataBlock+1] |= (currentReadY & 0x0F00) >> 4; */
    /* 	localBuffers[currentBlock].dataZ[currentDataBlock] = (currentReadZ & 0x00FF); */
    /* 	localBuffers[currentBlock].dataZ[currentDataBlock+1] |= (currentReadZ & 0x0F00) >> 4; */
    /* #ifdef PRINTF_SUPPORT */
    /* 	printf("S%u-%u", localBuffers[currentBlock].dataX[currentDataBlock], */
    /* 	       localBuffers[currentBlock].dataX[currentDataBlock+1]); */
    /* #endif */
    /* 	currentDataBlock += 2; */
    /* 	completedPadding = FALSE; */
    /*       } */
    
    if (currentSamples == totalSamples) {
      
      // Power down acceleration sensor
/*       TOSH_CLR_GIO2_PIN(); */
      
      dump (currentDataBlock, currentBlock, TRUE); // Posts a task
      currentDataBlock = 0;
      currentBlock = (currentBlock + 1) % VIBR_BLOCKS;

    } else if (currentDataBlock >= VIBR_BLOCK_SIZE) {

      dump (currentDataBlock, currentBlock, FALSE); // Posts a task
      currentDataBlock = 0;
      currentBlock = (currentBlock + 1) % VIBR_BLOCKS;
    } 
  }

  event void CollectionInfo.forwardingStatus(uint8_t status) {

    switch (status) {

    case FORWARDING_ACTIVE:
      atomic {
	if (!fw_active) {
	  fw_active = TRUE;
	  if (state == REPORTING && !call VReport.isRunning() && !reading_from_fram) {
	    call VReport.startOneShot(evaluateReportRate());
	  }
	}
      }
      break;

    case FORWARDING_INACTIVE:
      atomic{ 
	if (fw_active) {
	  slowStartState = 0;
	  fw_active = FALSE;
	  if (call VReport.isRunning()) {
	    call VReport.stop();
	  }
	}    
      }  
      break;
    }
  }

  task void sendBatteryData() {

    TLOpId_t outId;
#ifndef ROUTING_MONITOR
    nx_struct opaqueTupleSysInfo* ot; 
#endif
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tMonitor;

#ifdef ROUTING_MONITOR
    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(UNRELIABLE_DELIVERY),
                        arrayField());
    seq_no++;
    page_I.seq_no = seq_no;
    page_I.voltage = batteryVal;
    memcpy(&(tMonitor.value3), &page_I, sizeof(nx_struct opaqueTupleSysInfo));
    if (fw_active)
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);

    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(UNRELIABLE_DELIVERY),
                        arrayField());
    seq_no++;
    page_II.seq_no = seq_no;
    page_II.total_send = call CollectionDebug.getTotalSend();
    page_II.total_retxmit = call CollectionDebug.getTotalRetxmit();
    memcpy(&(tMonitor.value3), &page_II, sizeof(nx_struct opaqueTupleSysAdvInfo)); 
    if (fw_active)
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);
#else
    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(UNRELIABLE_DELIVERY),
                        arrayField());
    ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3;

    ot->type = NODE_INFO_TYPE;
    ot->address = TL_LOCAL;
    ot->parent = call CollectionInfo.currentParent();
    ot->parentCost = call CollectionInfo.parentCost();
    ot->voltage = batteryVal;
    if (fw_active)
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);
#endif
  }

  async event void AccelRead.dataReady(uint16_t* buffer, 
				       uint16_t numSamples) { 

    if (numSamples == 2) {
      // I'm reading the battery voltage level
      batteryReading = FALSE;
      batteryVal = buffer[1] * 5 / 3; // Necessary to convert the raw ADC 
                                      // to the right reference voltage 
                                      // for battery readings
      post sendBatteryData();
    } else {
      // Reading acceleration
      currentReadX = buffer[0];
      currentReadY = buffer[1];
      currentReadZ = buffer[2];
      // If still sensing, keep going
      if (state == SENSING) {
	call AccelRead.getData();
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
  }
  
  async command const msp430adc12_channel_config_t* AdcAccelConf.getConfiguration() {
    return &configX;
  }

  // This is processing to read the battery status
  event void BatteryMonitor.fired() {

    uint8_t currentState;
    atomic currentState = state;

    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0 
	&& currentState == INACTIVE) {    
      call AccelRead.configure(&configX, memctl_additional_battery, 
			       1, senseBufferBattery, 2, 0);
      call AccelRead.getData();
    }
  }

  event void ResourceAccelRead.granted() {
  }

  async event error_t BatteryReadADC.singleDataReady(uint16_t data) {
    return SUCCESS;
  }

  async event uint16_t* BatteryReadADC.multipleDataReady(uint16_t buffer[], 
							 uint16_t numSamples) {
    return NULL;
  }

  async event void FRAM.computeCrcDone( uint16_t crc, Fm25lc_addr_t addr,
					Fm25lc_len_t len, error_t error ) {
  }

  async event void FRAM.sectorEraseDone( uint8_t sector, error_t error ) {
  }

  async event void FRAM.bulkEraseDone( error_t error ) {

  }

#ifdef ROUTING_MONITOR
  event void CollectionDebug.parentUpdated(uint16_t parent, uint16_t cost){
    page_I.parent_changes++;
    page_I.parent = parent;
    page_I.parent_cost = cost;
  }

  event void CollectionDebug.packetForwarded(uint8_t traffic_class, 
                                             uint8_t retries,
                                             uint16_t child){
    page_II.packets_forwarded[traffic_class]++;
    page_II.out_retries += retries;
  }

  event void CollectionDebug.transmissionFailed(uint8_t traffic_class,
                                                uint8_t retries,
                                                uint16_t child){
    page_II.retries[traffic_class]++;
    page_II.out_retries += retries;
  }

  event void CollectionDebug.treeCongested(bool root){
    if (root){
      page_I.root_congestions++;
    } else {
      page_I.subtree_congestions++;
    }
  }

  event void CollectionDebug.bufferOverflow(uint8_t deletedMessages){
    page_I.msg_deleted_buffer_overflow += deletedMessages;
  }

  event void CollectionDebug.messageRecovery(bool success, 
                                             uint8_t retries,
                                             uint16_t child){
    if (success){
      page_I.successful_recoveries++;
    } else {
      page_I.failed_recoveries++;
    }
    page_I.rd_retries += retries;
  }

  event void CollectionDebug.droppedDuplicate(uint16_t child){
    page_II.dropped_duplicates++;
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

