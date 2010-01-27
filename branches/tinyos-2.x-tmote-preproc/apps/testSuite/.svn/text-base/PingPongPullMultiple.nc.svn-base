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
 * Test for local out, and remote rd, in and reaction operations. The
 * nodes periodically exchange a tuple in a "pull"
 * fashion. Distributed reactions are setup which are triggered when a
 * tuple is locally output. After receiving the notification, the
 * remote node removes the tuple using a distributed in.
 *
 * Use two nodes only. The blue led should be on and off alteratively
 * on the two nodes.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 10000
#define STEP 10000

module PingPongPullMultiple {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface Random;
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

  uint16_t counter = 0;
  tuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, outId, rdId, inId;

  event void Boot.booted() {

    tuple<uint16_t, uint16_t> p;

    p = newTuple(actualField(FAKE_DATA), dontCare());
    call TS.addReaction(&reactionId, TRUE, TL_NEIGHBORHOOD, RAM_TS, 
            (tuple *) &p);

    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(TIMER);
    } 

    neighborTuple = newTuple(actualField(call AMPacket.address()));

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {
    tuple<uint16_t, uint16_t> t1, t2;

    t1 = newTuple(actualField(FAKE_DATA),
		  actualField(TL_LOCAL));
    
    t2 = newTuple(actualField(TL_LOCAL),
		  actualField(FAKE_DATA));

    call Leds.led2Toggle();
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t1);
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t2);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {

    tuple<uint16_t, uint16_t> ingPattern, *rcv, first;
    uint8_t i = 0;
    int number;
    
    ingPattern = newTuple(dontCare(), dontCare());

#ifdef PRINTF_SUPPORT
    while ((rcv = (tuple<uint16_t, uint16_t> *) 
                call TS.nextTuple(operationId, iterator)) != NULL) {
      if (i == 0)
        call TLObjects.copy_tuple((tuple *) &first, (tuple *) rcv);

      i++;
      printf("%u-%u", rcv->value0, rcv->value1);
    }
#endif
    number = i;

    PROCESS_OP(reactionId,
	       printf("R\n");
	       if(number == 1
		  && first.value0 == FAKE_DATA) {
		 call Leds.led1Toggle();
		 call TS.ing(&inId, TRUE, first.value1, RAM_TS, (tuple *) &ingPattern);
	       }); 

    PROCESS_OP(inId,
	       printf("I\n");
	       call Leds.led2Toggle();
	       call TimerApp.startOneShot(STEP);
	       );     

#ifdef PRINTF_SUPPORT
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

