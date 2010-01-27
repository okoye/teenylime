/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 320 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:38:54 -0500 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: VibrSenseTask.nc 320 2008-03-13 11:38:54Z ben_christian $
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
#include "TupleSpace.h"

/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define MAX_VIBR_BLOCKS 2
#define VIBR_BLOCK_SIZE 50 

#define FAKE_REPORT_INTERVAL 1000

module VibrSenseTask {
  
  uses {
    
    interface Boot;
    
    interface TupleSpace as TS;
    
    interface Alarm<TMilli, uint16_t> as VSensePeriod;
    interface Alarm<TMilli, uint16_t> as VSenseSample;
    interface Timer<TMilli> as VReport;

    interface BlockRead;
    interface BlockWrite;
    
    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {
  
  typedef struct vibration_block_t {
    bool last;
    uint8_t initialTstamp;
    uint8_t valuesWritten;
    uint16_t data[VIBR_BLOCK_SIZE];
  } vibration_block_t;
  
  vibration_block_t localBuffers[MAX_VIBR_BLOCKS];
  vibration_block_t read;

  TLOpId_t roundReactId,inId;
  
  bool memBusy = FALSE;
  uint8_t currentBlock = 0;
  uint8_t currentDataBlock = 0;
  norace uint8_t storeBlockNumber; 

  uint32_t currentWAddr = 0;
  uint32_t currentRAddr = 0;  

  uint8_t readDataBlock = 0;

  uint16_t testCounter=0;

  // Parameters of currently running sensing task (if any)
  norace uint16_t currentSamples;
  uint16_t currentTick, rate,  totalSamples, period, operatingTime;

  event void Boot.booted() {

    tuple roundReaction = newTuple(2, 
 				   actualField_uint8(ROUND_TYPE), 
				   formalField(TYPE_UINT16_T)); 
    call TS.addReaction(&roundReactId, FALSE, TL_LOCAL, &roundReaction);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
    atomic{
      tuple taskPattern = newTuple(6,
 				   actualField_uint8(TASK_TYPE),
 				   actualField_uint8(VIBRATION_TYPE),
 				   formalField(TYPE_UINT16_T),
 				   formalField(TYPE_UINT16_T),
				   formalField(TYPE_UINT16_T),
				   formalField(TYPE_UINT16_T));
      
      if (opIdCmp(&operationId, &roundReactId)) {
	
	// A new round tuple was output: check if new tasks arrived
	call TS.in(&inId, FALSE, TL_LOCAL, &taskPattern);
	
      } else if (opIdCmp(&operationId, &inId) && number == 1) {
	
	// A new task description arrived
	if (call VSensePeriod.isRunning()) {
	  // Cancel the previous task
	  call VSensePeriod.stop();
	} 
	
	rate = tuples[0].fields[2].value.int16;
	totalSamples = rate * tuples[0].fields[3].value.int16;  
	
	currentTick = 0;
	period = tuples[0].fields[4].value.int16;
	operatingTime = tuples[0].fields[5].value.int16;
	
	call VSensePeriod.start((uint32_t)MINUTE);
	
#ifdef PRINTF_SUPPORT
	printf ("T %u O %u Ts %u\n", period, operatingTime, totalSamples);
	call PrintfFlush.flush();
#endif    
      }else if (opIdCmp(&operationId, &inId) && number == 0) {
	//Task is running
	if ((currentTick > 0) && (call VSensePeriod.isRunning()==FALSE)) {
	  call VSensePeriod.start((uint32_t)MINUTE);
	}
      }
    }
  }
  
  async event void VSensePeriod.fired() {
    atomic{
      if (currentTick % period == 0) { 
	currentSamples = 0;
	currentWAddr = 0;
	currentRAddr = 0;
	call VSenseSample.start(period);
	if (call BlockWrite.erase() != SUCCESS) {
#ifdef PRINTF_SUPPORT
	  printf("RER\n");
	  call PrintfFlush.flush();
#endif
	}
	
	if (currentTick == operatingTime && operatingTime != INFINITE_OP_TIME) {
	  call VSensePeriod.stop();
	  currentTick = 0; 
	}
      }
      currentTick++;    
    }
  }
  
  task void storeData() {
    
    if (!memBusy) {
      memBusy = TRUE;
#ifdef PRINTF_SUPPORT
      printf("WI\n");
      call PrintfFlush.flush();
#endif
      atomic{
	if (call BlockWrite.write(currentWAddr, 
				  &(localBuffers[storeBlockNumber]), 
				  sizeof(vibration_block_t)) != SUCCESS) {
	  call Leds.led2On();
#ifdef PRINTF_SUPPORT
	  printf("WE\n");
	  call PrintfFlush.flush();
#endif
	  memBusy = FALSE;
	}
      }
    } else {
      call Leds.led2On();
#ifdef PRINTF_SUPPORT
      printf("MB\n");
      call PrintfFlush.flush();
#endif
    }
  }
  
  void report() {
    atomic{
      if (call BlockRead.read(currentRAddr, &read, 
			      sizeof(vibration_block_t)) != SUCCESS) {
#ifdef PRINTF_SUPPORT
	printf("RE\n");
	call PrintfFlush.flush();
#endif
      }
    }
  }
  event void BlockWrite.writeDone(storage_addr_t addr, 
				  void* buf, storage_len_t len, 
				  error_t error) {
    
    if (error != SUCCESS || len != sizeof(vibration_block_t)) {
      call Leds.led2On();
#ifdef PRINTF_SUPPORT
      printf("AE\n");
      call PrintfFlush.flush();     
#endif
    }
    atomic currentWAddr += len;
    memBusy = FALSE;
    // If the block I just wrote is the last one, I need to start reporting
    if (((vibration_block_t*) buf)->last) {
      call BlockWrite.sync();
    }
  }
  
  event void BlockWrite.syncDone(error_t err) {
    report();
  }
  
  void dump(uint8_t values, uint8_t block, bool last){
    atomic{
      storeBlockNumber = block; 
      localBuffers[block].last = last;
      localBuffers[block].valuesWritten = values;  
      post storeData();
    }
  }
  
  event void BlockRead.readDone(storage_addr_t addr, 
				void* buf, storage_len_t len, 
				error_t error){
    
    if (error == FAIL) {
#ifdef PRINTF_SUPPORT
      printf("RDE\n");
      call PrintfFlush.flush();
#endif
    } else {
      readDataBlock = 0;
      atomic currentRAddr += len; 
      call VReport.startOneShot(FAKE_REPORT_INTERVAL);
    }
  }
  
  event void VReport.fired() {
#ifdef PRINTF_SUPPORT
    printf("R%d\n",read.valuesWritten);
    call PrintfFlush.flush();
#endif
    if (!read.last) {
      report();
    }
  }
  
  async event void VSenseSample.fired() {
    atomic{
      currentSamples++;
      // Fake data
      localBuffers[currentBlock].data[currentDataBlock++] = testCounter++;
      
      if (currentSamples == totalSamples) {
	dump (currentDataBlock, currentBlock, TRUE);
	currentDataBlock = 0;
	currentBlock = (currentBlock + 1) % MAX_VIBR_BLOCKS;
	call Leds.led2Toggle();
      } else if (currentDataBlock == VIBR_BLOCK_SIZE) {
	dump (currentDataBlock, currentBlock, FALSE);
	currentDataBlock = 0;
	currentBlock = (currentBlock + 1) % MAX_VIBR_BLOCKS;
	call VSenseSample.start(1000/rate);
	call Leds.led2Toggle();
      } else {
	call VSenseSample.start(1000/rate);
      }
    }
  }
  
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }
  
  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
  }
  
  event void BlockWrite.eraseDone(error_t err) {
    // Beginning sensing
#ifdef PRINTF_SUPPORT
    printf ("Rp %u\n", Rperiod);
    call PrintfFlush.flush();
#endif    
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len,
				      uint16_t crc, error_t error){
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

