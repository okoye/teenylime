/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1025 $
 * * DATE
 * *    $LastChangedDate: 2010-01-15 09:31:19 -0600 (Fri, 15 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: VibrSenseTaskFlash.nc 1025 2010-01-15 15:31:19Z mceriotti $
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

module VibrSenseTaskFlash {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Alarm<TMilli, uint16_t> as VSensePeriod;
    interface Alarm<T32khz, uint16_t> as VSenseSample;
    interface Timer<TMilli> as VReport;
    interface /* Alarm<TMilli, uint16_t> */ Timer<TMilli> as FlashReadDelay;

    // For battery monitoring
    interface Timer<TMilli> as BatteryMonitor;

    interface Tuning;

    interface DirectStorage;
    interface VolumeSettings;

    interface Msp430Adc12MultiChannel as AccelRead;
    interface Msp430Adc12SingleChannel as BatteryReadADC;
    interface Resource as ResourceAccelRead;

    interface Compression;

    interface Leds;
    interface GlobalTime;

    interface CollectionInfo;

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
  bool reading_from_flash = FALSE;
  bool senseperiodstarted = FALSE;

  typedef struct vibration_block_t {
    bool last; 
    uint8_t valuesWritten;
    uint8_t dataX[VIBR_BLOCK_SIZE];  
    uint8_t dataY[VIBR_BLOCK_SIZE];  
    uint8_t dataZ[VIBR_BLOCK_SIZE];  
  } vibration_block_t;
  norace vibration_block_t localBuffers[VIBR_BLOCKS];

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
  uint32_t currentWAddr;
  norace uint32_t currentRAddr;  
  uint32_t currentEraseUnit;  

  // Flags for memory operation  
  bool mem_reading = FALSE;
  bool mem_writing = FALSE;
  bool mem_flushing = FALSE;
  bool turning_on = FALSE;
  bool turning_off = FALSE;

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

  nx_struct opaqueTupleSysInfo {
    nx_uint8_t type;
    nx_uint16_t address;
    nx_uint16_t parent;
    nx_uint16_t parentCost;
    nx_uint16_t voltage;
  };

  uint16_t batteryVal = 0;

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
  norace uint16_t currentSamples;
  uint16_t currentTick, senseInterval,  totalSamples, period, numSessions;
  uint16_t globalPeriod;

  /* uint16_t count_blocks = 0; */

  // Information used to adapt the sending rate
  uint16_t sentMsgs;  
  uint32_t startReporting;
  uint8_t slowStartState;


  bool memBusy() {
    return (mem_reading || mem_writing || mem_flushing);
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
	 FLASH_TIMEOUT * (1+ ((uint16_t)totalSamples / VIBR_BLOCK_SIZE))); // Pauses times for flash 
      
      // Msgs still to be sent for this session
      atomic {
	remainingMsgs =
	  ((3*(1+((uint16_t)VIBR_BLOCK_SIZE
		  / payloadSize))) * // Msgs per block
	   (1+ ((uint16_t)totalSamples / VIBR_BLOCK_SIZE))) - // Number of blocks used
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
/* #ifdef PRINTF_SUPPORT */
/*       printf("ssp%drt%lurm%dt%lu\n",slowStartState, reportingTime, */
/*       	     remainingMsgs, reportRate); */
/*       call PrintfFlush.flush(); */
/* #endif */
      return reportRate;
    } else {
      // Reached max speed
      previousReportRate = MIN_CLASS_1_REPORT_INTERVAL;
/* #ifdef PRINTF_SUPPORT */
/*       printf("sss%drt%lurm%dt%lu\n",slowStartState, reportingTime, */
/*       	     remainingMsgs, reportRate); */
/*       call PrintfFlush.flush(); */
/* #endif */
      return MIN_CLASS_1_REPORT_INTERVAL;
    }
  }
  
  void reinitBlock(uint8_t block) {
    
    uint8_t i;
    
    localBuffers[block].last = FALSE; 
    localBuffers[block].valuesWritten = 0;

    for (i=0; i<VIBR_BLOCK_SIZE; i++) { 
      localBuffers[block].dataX[i] = 0;
      localBuffers[block].dataY[i] = 0;  
      localBuffers[block].dataZ[i] = 0;  
    }
  }

  // Loop through all sectors and erase them
  task void eraseAll() {
    atomic {
      if(currentEraseUnit < call VolumeSettings.getTotalEraseUnits()) {
	if(SUCCESS != call DirectStorage.erase(currentEraseUnit)) {
	  post eraseAll();
	}    
      } else {
	call DirectStorage.flush();
      }
    }
  }

  task void readCurrentBlock() {
/*     call Leds.led1Toggle(); */
    mem_reading = TRUE;
    if (call DirectStorage.read(currentRAddr, &(localBuffers[0]),
				sizeof(vibration_block_t)) != SUCCESS) {
      call Leds.led0On();
#ifdef PRINTF_SUPPORT
      printf("RE\n");
      call PrintfFlush.flush();
#endif
    }
  }  

  task void shutRadioOff() {
    // This is essentially a no-op if the readio is already off, 
    // as it happens right after formatting; yet, 
    // the setDone event is signalled nonetheless
    atomic{
        call Leds.led0On();
        turning_off = TRUE;
        call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF);
     } 
  }
  
  /* async */ event void FlashReadDelay.fired() {
    atomic{
      call Leds.led0On();
      turning_off = TRUE;
      call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF);
    } 
    /*     post shutRadioOff(); */
  }

  event void Tuning.setDone(uint8_t key, uint16_t value){

    uint8_t currentState;    
    atomic {
      currentState = state;
      if (key == KEY_RADIO_CONTROL) {
        if (value == RADIO_ON) {
          if (!turning_on)
            return;
          turning_on = FALSE;
        } else if (value == RADIO_OFF){
          if (!turning_off)
            return;
          turning_off = FALSE;
        }
      }
    }

    if (key == KEY_RADIO_CONTROL) {
      if (value == RADIO_ON && currentState == REPORTING) {

	compressedBuffer.sizeX = call Compression.compressX(localBuffers[0].dataX,
							    localBuffers[0].valuesWritten,
							    localBuffers[1].dataX);
	compressedBuffer.sizeY = call Compression.compressY(localBuffers[0].dataY,
							    localBuffers[0].valuesWritten,
							    localBuffers[1].dataY);
	compressedBuffer.sizeZ = call Compression.compressZ(localBuffers[0].dataZ,
							    localBuffers[0].valuesWritten,
							    localBuffers[1].dataZ);
	sentDataX = 0; 
	sentDataY = 0;
	sentDataZ = 0;
  reading_from_flash = FALSE;
	
#ifdef PRINTF_SUPPORT
	/*       printf("X%d-%d\n",bufferLen, compressedBuffer.sizeX); */
	call PrintfFlush.flush();
#endif
	if (fw_active)
	call VReport.startOneShot(FLASH_TIMEOUT);
      } else if (value == RADIO_OFF && currentState == FORMATTING) {
	post eraseAll();
      } else if (value == RADIO_OFF && currentState == REPORTING) {
	post readCurrentBlock();
      }
    }
  }

  event void Boot.booted() {

    uint8_t i;

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

    atomic{
      state = INACTIVE;
      fw_active = FALSE;
      reading_from_flash = FALSE;
      senseperiodstarted = FALSE;
      currentBlock = 0;
      mem_reading = FALSE;
      mem_writing = FALSE;
      mem_flushing = FALSE;
      batteryReading = FALSE;
      minuteTick = 0;
    }
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startSensePeriod(){
#ifdef TEST_VIBR
     call VSensePeriod.start(MINUTE);
#else
     call VSensePeriod.start(EPOCH_RATE);
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

	         /* Total task period */
		 period =  ((uint32_t)msgs * 2 * MIN_CLASS_1_REPORT_INTERVAL / MINUTE) + /*  Estimated reporting time */
		   ((uint32_t)SENSOR_BOOT_TIMER*1000/(32767*(uint32_t)MINUTE)) + /* Constants */
		   ((uint32_t)EPOCH_RATE * SYNCH_PERIOD / MINUTE) + /* TimeSynch period */ 
		   (((uint32_t)senseInterval*totalSamples*1000/(32767*(uint32_t)MINUTE))) + /* Sensing time */
		    (((1 + ((uint32_t)totalSamples / VIBR_BLOCK_SIZE))*(uint32_t)FLASH_TIMEOUT) / MINUTE ); /* Pauses times for flash */

     globalPeriod = ((uint32_t) (period  + TREE_REBUILDING_PERIOD) * MINUTE) / (uint32_t) EPOCH_RATE; 
       
		 numSessions = rcv->value4; 
      
		 call TS.nextTuple(operationId,iterator);
		 senseperiodstarted = TRUE;
     startSensePeriod();
	       });
 
#ifdef PRINTF_SUPPORT
    printf("M%dTp%ds%d\n",msgs,period,totalSamples);
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
      call Leds.led2Toggle();
    }
  }

  async event void GlobalTime.timeEvent(){
      post searchNewTasks();
  }

  task void startNewSession() {

    // Init a new session if INACTIVE, otherwise skip
#ifdef TEST_VIBR
    if (currentTick % period == 0
#else
    if (call GlobalTime.getGlobalTime() % globalPeriod == 0
#endif
        && state == INACTIVE) {
      
      atomic{
        
        currentSamples = 0;
        sentMsgs = 0;
        
        // Starts formatting
        call Leds.led1On();
        call Leds.led2On();
        
        // Triggers sensing
        call VSenseSample.start(SENSOR_BOOT_TIMER);
        
        // Turns the radio off while formatting
        atomic {
          state = FORMATTING;
          currentEraseUnit = 0;
          post shutRadioOff();
          /* 	  call Leds.led0On(); */
          /* 	  call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF); */
        }	
      }
#ifdef TEST_VIBR
    } else if (currentTick % period == 0
#else
    } else if (call GlobalTime.getGlobalTime() % globalPeriod == 0
#endif
               && state != INACTIVE) {
      // Skipping sensing: realign the report rate to a new session
      startReporting = call VReport.getNow();
    }
    
    currentTick++;
#ifdef TEST_VIBR
    if (currentTick == (numSessions*period)
#else
    if (currentTick == (numSessions*globalPeriod)
#endif
        && numSessions != INFINITE_OP_TIME) {
      // Stop the task
      currentTick = 0; 
    }  else {
      startSensePeriod();
    } 

  }

  async event void VSensePeriod.fired() {
    if (senseperiodstarted)
      post startNewSession();
  }
 
  task void storeData() {
    
    if (!memBusy()) {
      atomic{
	mem_writing = TRUE;
	if (call DirectStorage.write(currentWAddr, 
				     &(localBuffers[storeBlockNumber]), 
				     sizeof(vibration_block_t)) != SUCCESS) {
	  call Leds.led0On();
#ifdef PRINTF_SUPPORT
	  printf("WE\n");
	  call PrintfFlush.flush();
#endif
	}
      }
    } else {
      post storeData();
    }
  }
    
  event void DirectStorage.writeDone(uint32_t addr, 
				     void* buf, storage_len_t len, 
				     error_t error) {
    /* count_blocks++; */

    if (error != SUCCESS) {
      // Repeats the write ... 
      call Leds.led0On();
      if (call DirectStorage.write(currentWAddr, 
				   &(localBuffers[storeBlockNumber]), 
				   sizeof(vibration_block_t)) != SUCCESS) {
	call Leds.led0On();
      }	
    } else {
      mem_writing = FALSE;
      atomic currentWAddr += len;  
      // If the block I just wrote is the last one, 
      // let's sync and start reporting
      if (localBuffers[storeBlockNumber].last) {
	mem_flushing = TRUE;
	if (call DirectStorage.flush() != SUCCESS) {
	  call Leds.led0On();
	}
      }
    }
  }
  
  event void DirectStorage.flushDone(error_t err) {

    uint8_t currentState;
    
    atomic {
      currentState = state;
    }

    if (err != SUCCESS) {
      call Leds.led0On();
      if (call DirectStorage.flush() != SUCCESS) {
	call Leds.led0On();
      }      
    } else if (currentState == FORMATTING) {
      // Proceeds to sensing after formatting
      call Leds.led1On();
      call Leds.led2Off();
      /* if (count_blocks != 0){ */
/*         call Leds.led2On(); */
/*       } */
/*       count_blocks = 0; */
      currentRAddr = 0;
      currentWAddr = 0;
      atomic {
	// Configures and starts the ADC conversion
	state = SENSING;
	call AccelRead.configure(&configX, memctl_additional,
				 2, senseBuffer, 3, 0);
	call AccelRead.getData();
      }
    } else {
      // Start reporting
      mem_flushing = FALSE;
      mem_reading = TRUE;
      atomic state = REPORTING;
      atomic startReporting = call VReport.getNow();
      slowStartState = 0;
      
      call FlashReadDelay.startOneShot(FLASH_TIMEOUT);
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

  event void DirectStorage.readDone(uint32_t addr, void* buf, 
				    uint32_t len, error_t error){

/*     vibration_block_t* readBlock; */

    atomic{
    if (error != SUCCESS) {
      call Leds.led0On();      
      if (call DirectStorage.read(currentRAddr, &(localBuffers[0]),
				  sizeof(vibration_block_t)) != SUCCESS) {
	call Leds.led0On();
      }
    } else {

      mem_reading = FALSE;
      call Leds.led1Off();
      call Leds.led2On();

      /* count_blocks--; */
      
      currentRAddr += len;
/*       readBlock = (vibration_block_t*) buf; */

      // Restarts radio
      call Leds.led0Off();
      turning_on = TRUE;
      call Tuning.set(KEY_RADIO_CONTROL, RADIO_ON);
      
    }
    }
  }

  // Proceeds erasing the next unit
  event void DirectStorage.eraseDone(uint16_t eraseUnitIndex, error_t error){

    if(error) {
      post eraseAll();
    } else {
      atomic currentEraseUnit++;
      post eraseAll();
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
    if (localBuffers[0].last && doneX && doneY && doneZ) {
      ot->type = VIBRATION_END_SESSION;
    } else {
      ot->type = VIBRATION_TYPE;
    }    
    ot->address = TOS_NODE_ID;
    ot->seqNum = msgSeqNum++;
    atomic sentMsgs++;
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &vibrReading);
    
    if (!doneX || !doneY || !doneZ) {
      // Possily more messages need to be sent for this block
      if (fw_active) {
	call VReport.startOneShot(evaluateReportRate()); 
      }
    } else if (doneX && doneY && doneZ && !localBuffers[0].last) {
      // If the current block is not the last, proceed to the next block
      doneX = FALSE; doneY = FALSE; doneZ = FALSE;   
/*       call Leds.led1Toggle(); */

      reading_from_flash = TRUE;
      call FlashReadDelay.startOneShot(FLASH_TIMEOUT);

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
/* 	currentReadX = 2013; */
/* 	currentReadY = 1963; */
/* 	currentReadZ = 2917; */
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
/* 	currentReadX = 2008; */
/* 	currentReadY = 1963; */
/* 	currentReadZ = 2917; */
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
	  if (state == REPORTING && !call VReport.isRunning() && !reading_from_flash) {
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
    nx_struct opaqueTupleSysInfo* ot;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tMonitor;
    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(UNRELIABLE_DELIVERY),
                        arrayField());
    ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3;
    ot->type = NODE_INFO_TYPE;
    ot->address = TL_LOCAL;
    ot->parent = call CollectionInfo.currentParent();
    ot->parentCost = call CollectionInfo.parentLQI();
    atomic ot->voltage = batteryVal;
    if (fw_active)
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);
  }

  async event void AccelRead.dataReady(uint16_t* buffer, 
				       uint16_t numSamples) { 

    if (numSamples == 2) {
      // I'm reading the battery voltage level
/*       call Leds.led0Toggle(); */
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
 
  event void DirectStorage.crcDone(uint16_t calculatedCrc, uint32_t addr, 
				   uint32_t len, error_t error){
  }
  
  async command const msp430adc12_channel_config_t* AdcAccelConf.getConfiguration() {
    return &configX;
  }

  // This is processing to read the battery status
  event void BatteryMonitor.fired() {

    minuteTick++;
    atomic {
      if (minuteTick % MONITOR_PERIOD == 0 
	  && state == INACTIVE) {    
	call AccelRead.configure(&configX, memctl_additional_battery, 
				 1, senseBufferBattery, 2, 0);
	call AccelRead.getData();
      }
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

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }
  
  event void PrintfControl.stopDone(error_t error) {
  }
  
  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 

}

