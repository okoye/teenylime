/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 290 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 13:34:07 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalOps.nc 290 2008-02-19 11:34:07Z lmottola $
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
 * Test for local out, rd, in and reaction operations. Under correct
 * execution, all leds will blink alternatively and in sequence.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 3000

module LocalOps {

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

  uint8_t op = 0;
  tuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, inId, outId, rdId;

  event void Boot.booted() {
    
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());
    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    call TimerApp.startPeriodic(TIMER);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare()),
          t = newTuple(actualField(FAKE_DATA), actualField(FAKE_DATA));
    
    if (op % 3 == 0) {  
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
    } else if (op % 3 == 1) {
      call TS.rd(&rdId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    } else {
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    }
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint8_t, uint16_t> *res = 
        (tuple<uint8_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
    int number = 0;
    if (res != NULL)
        number++;
    if (call TS.nextTuple(operationId, iterator) != NULL)
        number++;

    PROCESS_OP(reactionId,
	       if (number == 1
		   && res->value0 == FAKE_DATA
		   && res->value1 == FAKE_DATA) {
		 call Leds.led0Toggle();
	       });
    
    PROCESS_OP(rdId,
	       if (number == 1
		   && res->value0 == FAKE_DATA
		   && res->value1 == FAKE_DATA) {
		 call Leds.led1Toggle();
	       });
	       
    PROCESS_OP(inId,
	       if( number == 1
		   && res->value0 == FAKE_DATA
		   && res->value1 == FAKE_DATA) {
		 call Leds.led2Toggle();
	       });
    
#ifdef PRINTF_SUPPORT
    if (op % 3 == 0) {
      printf ("React: ");
    } else if (op % 3 == 1) {
      printf ("Rd: ");
    } else {
      printf ("In: ");
    }

    if (number == 0) {
      printf ("no tuples\n");
      call PrintfFlush.flush();
    } else if (number == 1) {
      printf ("tuple: %u  %u\n", res->value0, res->value1);
      call PrintfFlush.flush();
    } else {
      printf ("multiple returned!\n");
      call PrintfFlush.flush();
    }
#endif
    op++;
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

