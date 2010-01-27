/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 297 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 20:33:24 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: FakeDataDisseminationVibr.nc 297 2008-02-26 18:33:24Z mceriotti $
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
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

/* Vibration Node configuration */

// The sampling rate (R) for acceleration tasks (in Hz)
#define VIBRATION_RATE 100

// The sampling duration (S) for acceleration tasks (in secs)
#define VIBRATION_SAMPLING 1 // The number of samples must be a multiple of 3

// Number of sessions
#define VIBRATION_SESSIONS 1

// To avoid installing the task immeditately
#define FAKE_STARTUP_TL_EPOCHS 2

module FakeDataDisseminationVibr {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface TLObjects;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  NeighborTuple<uint16_t, lqi, uint16_t> neighborTuple;

  event void Boot.booted() {

    neighborTuple = newTuple(
                             actualField(call AMPacket.address()),
                             lqiRead(),                             
                             actualField(0));
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator){
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {

    static uint8_t fakeCounter = 0;
    static bool installed = FALSE;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t> taskTuple;
    TLOpId_t outId;

    if (fakeCounter > FAKE_STARTUP_TL_EPOCHS && !installed) {
      taskTuple = newTuple(
			   actualField(TASK_TYPE),
			   actualField(VIBRATION_TASK),
			   actualField(VIBRATION_RATE),
			   actualField(VIBRATION_SAMPLING),
			   actualField(VIBRATION_SESSIONS));
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskTuple);
      installed = TRUE;
    } else if (!installed) {
      fakeCounter++;
    }

    return (tuple *) &neighborTuple;
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
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

