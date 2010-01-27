/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 12:42:42 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: PendingOps.nc 289 2008-02-19 10:42:42Z lmottola $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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
#include "TLConf.h"

/**
 * Test for multiple (unreliable) distributed operations: see if the
 * tupleReady events are triggered in the right order.
 *
 * Under correct execution, the green led blinks while the operations are
 * being performed. With no other nodes around, the operationCompleted event is 
 * signaled with completionCode == OP_TIMEOUT, and the blue led toggles.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 100

#define OP_TIMEOUT 10000

module PendingOps {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface AMPacket;

    interface Random;

    interface Leds;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple<uint16_t> neighborTuple;
  TLOpId_t opIds[MAX_PENDING_OPS];
  tuple<char, char> p;
  uint8_t i = 0; 
  uint8_t j = 0;

  event void Boot.booted() {

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    p = newTuple(dontCare(), dontCare());
 
    call TimerApp.startOneShot(TIMER*100);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();    
#endif
  }

  event void TimerApp.fired() {

    if (i<MAX_PENDING_OPS) {
      call Leds.led1Toggle();
      call TS.rd(&(opIds[i++]), FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &p);  
      call TimerApp.startOneShot(TIMER);
    }    
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 
    call Leds.led0On();
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return (tuple *) &neighborTuple;
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,
                   TLTupleSpace_t ts,
				   tuple* returningTuple) {

    if (completionCode != OP_TIMEOUT) {
	call Leds.led0On();
	return;
    }
    
    PROCESS_OP(opIds[j++], call Leds.led2Toggle(); );
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

