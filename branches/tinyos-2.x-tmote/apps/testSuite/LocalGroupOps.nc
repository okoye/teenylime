/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 04:42:42 -0600 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalGroupOps.nc 289 2008-02-19 10:42:42Z lmottola $
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

#include "Constants.h"
#include "TupleSpace.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * Test for local out, ing, rdg and reaction operations. Under correct
 * execution, the leds should toggle according to the sequence: R R G B B.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 3000

module LocalGroupOps {

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

  uint8_t op = 0;
  tuple neighborTuple;
  TLOpId_t reactionId, inAId, inBId, outId, rdId;

  event void Boot.booted() {

    tuple p = newTuple(2,
		       formalField(TYPE_UINT8_T),
		       formalField(TYPE_UINT16_T));

    neighborTuple = newTuple(1, actualField_uint16(call AMPacket.address()));

    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p);
    call TimerApp.startPeriodic(TIMER);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple p = newTuple(2, 
		       formalField(TYPE_UINT8_T), 
		       formalField(TYPE_UINT16_T));

    tuple t = newTuple(2, 
		       actualField_uint8(FAKE_DATA), 
		       actualField_uint16(FAKE_DATA));
    
    if (op % 5 == 0) {  
      call TS.out(&outId, FALSE, TL_LOCAL, &t);
    } else if (op % 5 == 1) {
      call TS.out(&outId, FALSE, TL_LOCAL, &t);
    } else if (op % 5 == 2) {
      call TS.rdg(&rdId, FALSE, TL_LOCAL, &p);
    } else if (op % 5 == 3) {
      call TS.ing(&inAId, FALSE, TL_LOCAL, &p);
    } else {
      call TS.ing(&inBId, FALSE, TL_LOCAL, &p);
    }
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {

    if (opIdCmp(&operationId, &reactionId)
	&& number == 1
	&& tuples[0].fields[0].value.int8 == FAKE_DATA
	&& tuples[0].fields[1].value.int16 == FAKE_DATA) {      
      call Leds.led0Toggle();
    }
    
    if (opIdCmp(&operationId, &rdId)
	&& number == 2
	&& tuples[0].fields[0].value.int8 == FAKE_DATA
	&& tuples[0].fields[1].value.int16 == FAKE_DATA
	&& tuples[1].fields[0].value.int8 == FAKE_DATA
	&& tuples[1].fields[1].value.int16 == FAKE_DATA) {
      call Leds.led1Toggle();
    }

    if (opIdCmp(&operationId, &inAId)
	&& number == 2
	&& tuples[0].fields[0].value.int8 == FAKE_DATA
	&& tuples[0].fields[1].value.int16 == FAKE_DATA
	&& tuples[1].fields[0].value.int8 == FAKE_DATA
	&& tuples[1].fields[1].value.int16 == FAKE_DATA) {
      call Leds.led2Toggle();
    }

    if (opIdCmp(&operationId, &inBId)
	&& number == 0) {
      call Leds.led2Toggle();
    }
    
#ifdef PRINTF_SUPPORT
    if (op % 5 == 0 || op % 5 == 1) {  
      printf ("Rct: ");
    } else if (op % 5 == 2) {
      printf ("Rdg: ");
    } else if (op % 5 == 3) {
      printf ("IngA: ");
    } else {
      printf ("IngB: ");
    }

    if (number == 0) {
      printf ("no tuples\n");
      call PrintfFlush.flush();
    } else if (number == 1) {
      printf ("1 tuple\n");
      call PrintfFlush.flush();
    } else if (number == 2) {
      printf ("ts: %u  %u - ",
	      tuples[0].fields[0].value.int8, 
	      tuples[0].fields[1].value.int16);
      printf ("%u  %u\n",
	      tuples[1].fields[0].value.int8, 
	      tuples[1].fields[1].value.int16);
      call PrintfFlush.flush();         
    } else {
      printf ("multiples!\n");
      call PrintfFlush.flush();
    }
#endif
    op++;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
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
