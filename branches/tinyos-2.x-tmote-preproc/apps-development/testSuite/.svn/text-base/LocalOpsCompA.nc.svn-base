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
 * *	$Id: LocalOpsCompA.nc 289 2008-02-19 10:42:42Z lmottola $
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

#include "Constants.h"
#include "TupleSpace.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif


/**
 * Test for local operations across different components on the same node.
 *
 * Under correct operations, the blue and green leds should blink
 * alternatively.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER_A 10000

module LocalOpsCompA {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface Random;

    interface AMPacket;

    interface Leds;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, inId, outId, rdId;

  event void Boot.booted() {

    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());
    
    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    call TimerApp.startOneShot(TIMER_A);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();    
#endif
  }

  event void TimerApp.fired() {

    tuple<uint16_t, uint8_t> t = newTuple(
            actualField(FAKE_DATA), 
            actualField(FAKE_DATA));

    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    tuple<uint8_t, uint16_t> *rcv =
        (tuple<uint8_t, uint16_t> *) call TS.nextTuple(operationId, iterator);

    PROCESS_OP(reactionId, 
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA
		   && rcv->value1 == FAKE_DATA) {      
		 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
	       });

    PROCESS_OP(inId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA
		   && rcv->value1 == FAKE_DATA) {
		 call Leds.led1Toggle();
		 call TimerApp.startOneShot(TIMER_A);
	       });
    call TS.nextTuple(operationId, iterator);
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

