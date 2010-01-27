/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 856 $
 * * DATE
 * *    $LastChangedDate: 2009-06-03 08:23:36 -0500 (Wed, 03 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: ReactionTuples.nc 856 2009-06-03 13:23:36Z sguna $
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

/**
 * Test for the synthetic reaction tuples. Under correct execution,
 * the blue and green leds blink alternatively and the red led should never
 * turns on.
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

#define TIMER 3000

module ReactionTuples {

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
  TLOpId_t ingId, reactionId, outId, inId;
  int op;

  event void Boot.booted() {
    
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);

    call Leds.led1On();
    call TimerApp.startPeriodic(TIMER);
    op = 0;

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());
    if (op == 0) {
      tuple<uint8_t, uint16_t> a;
      a = newTuple(actualField(FAKE_DATA), actualField(FAKE_DATA));
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      op = 1;
      call Leds.led2On();
    } else if (op == 1) {
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
      op = 2;
    } else {
      call TS.ing(&ingId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
      op = 0;
    }
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    int number = 0;
    while (call TS.nextTuple(operationId, iterator) != NULL)
      number++;
    
    PROCESS_OP(reactionId, call Leds.led1Toggle(); );

    PROCESS_OP(ingId,
	       call Leds.led2Off();
	       if (number != 2) {
		 call Leds.led0On();
	       });

#ifdef PRINTF_SUPPORT
    printf("%d\n", number);
    call PrintfFlush.flush();
#endif
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

