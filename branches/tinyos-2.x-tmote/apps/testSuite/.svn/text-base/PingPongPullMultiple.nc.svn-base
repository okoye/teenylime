/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 245 $
 * * DATE
 * *    $LastChangedDate: 2007-12-22 22:00:50 +0100 (Sat, 22 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: PingPongPull.nc 245 2007-12-22 21:00:50Z lmottola $
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
 * Test for local out, and remote rd, in and reaction operations. The
 * nodes periodically exchange a tuple using a "pull"
 * approach. Distributed reactions are setup which are triggered when
 * a tuple is locally output. After receiving the notification, the
 * remote node removes the tuple using a distributed in.
 *
 * Use two nodes only. The blue led should be on and off alteratively
 * on the two nodes.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 30000
#define STEP 30000 // Must be greater than EPOCH in TLConf.h

module PingPongPullMultiple {

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

  uint16_t counter = 0;
  tuple neighborTuple;
  TLOpId_t reactionId, outId, inId;

  event void Boot.booted() {

    tuple p;

    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led2Toggle();
      call TimerApp.startPeriodic(TIMER);
    } else {
      p = newTuple(2, 
		   formalField(TYPE_UINT16_T), 
		   actualField_uint16(PEER_A_ID));
      call TS.addReaction(&reactionId, TRUE, TL_NEIGHBORHOOD, &p);
    }

    neighborTuple = newTuple(1, actualField_uint16(call AMPacket.address()));

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple t1 = newTuple(2,
		       actualField_uint16(FAKE_DATA),
		       actualField_uint16(call AMPacket.address()));

    tuple t2 = newTuple(2,
		       actualField_uint16(FAKE_DATA),
		       actualField_uint16(counter++));

#ifdef PRINTF_SUPPORT
    printf("c%u", counter);
#endif
    call Leds.led2Toggle();
    call TS.out(&outId, FALSE, TL_LOCAL, &t1);
    call TS.out(&outId, FALSE, TL_LOCAL, &t2);
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {

    tuple ingPattern = newTuple(2, 
				formalField(TYPE_UINT16_T),
				formalField(TYPE_UINT16_T));
#ifdef PRINTF_SUPPORT
    uint8_t i;
    for (i=0; i<number; i++) {
      printf("%u-%u",
	     tuples[i].fields[0].value.int16,
	     tuples[i].fields[1].value.int16);
    }
#endif

#ifdef PRINTF_SUPPORT
    printf("r");
#endif
    if (opIdCmp(&operationId, &inId)) {
      call Leds.led0Toggle();
#ifdef PRINTF_SUPPORT
      printf("I");
#endif
    } else if (opIdCmp(&operationId, &reactionId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA) {
#ifdef PRINTF_SUPPORT
      printf("R");
#endif
      call TS.ing(&inId, TRUE, tuples[0].fields[1].value.int16, &ingPattern);
    }      
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

