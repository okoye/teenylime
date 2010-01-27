/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 296 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:31:13 -0600 (Tue, 26 Feb 2008) $
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
#include "TupleSpace.h"

/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define FAKE_DEFORM 10

module TempSenseTask {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as ReadTemp;
    interface Read<uint16_t> as ReadHumidity;
    interface Timer<TMilli> as TSensePeriod;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t roundReactId,inId;

  // Parameters of currently running sensing task (if any)
  uint16_t currentTick, period, operatingTime;

  // Temporary var needed for split-phase operations across
  // temperature and humidity sensing
  uint16_t currentTemperature;

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

    tuple taskPattern = newTuple(6,
 				   actualField_uint8(TASK_TYPE),
 				   actualField_uint8(TEMP_DEFORM_TYPE),
				   formalField(TYPE_UINT16_T),
				   formalField(TYPE_UINT16_T),
				   formalField(TYPE_UINT16_T),
				   formalField(TYPE_UINT16_T));

    if (opIdCmp(&operationId, &roundReactId)) {

      // A new round tuple was output: check if new tasks arrived
      call TS.in(&inId, FALSE, TL_LOCAL, &taskPattern);

    } else if (opIdCmp(&operationId, &inId)
	       && number == 1) {

      // A new task description arrived
      if (call TSensePeriod.isRunning()) {
	// Cancel the previous task
	call TSensePeriod.stop();
      } 
      currentTick = 0;
      period = tuples[0].fields[4].value.int16;
      operatingTime = tuples[0].fields[5].value.int16;
      call TSensePeriod.startPeriodic((uint32_t)MINUTE);

#ifdef PRINTF_SUPPORT
      printf ("T%uO%u\n", period, operatingTime);
      call PrintfFlush.flush();
#endif
    }
  }

  event void TSensePeriod.fired() {
    
    currentTick++;
    
    if (currentTick % period == 0) {
      
      call ReadTemp.read();

      if (currentTick == operatingTime && operatingTime != INFINITE_OP_TIME) {
        call TSensePeriod.stop();
      }
    }
  }

  event void ReadTemp.readDone(error_t result, uint16_t val) {  

    currentTemperature = val;
    call ReadHumidity.read();
  }

  event void ReadHumidity.readDone(error_t result, uint16_t val) {

    TLOpId_t outId;
    tuple tempReading = newTuple(5,
			   actualField_uint8(TEMP_DEFORM_TYPE),
			   actualField_uint16(call AMPacket.address()),
			   actualField_uint16(currentTick/period),
			   actualField_uint16(currentTemperature),
			   actualField_uint16(val));
    call TS.out(&outId, FALSE, TL_LOCAL, &tempReading);

#ifdef PRINTF_SUPPORT
    printf ("Sensed %u\n", val);
    call PrintfFlush.flush();
#endif    
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
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

