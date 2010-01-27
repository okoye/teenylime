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
 * *	$Id: PingPongPull.nc 290 2008-02-19 11:34:07Z lmottola $
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
 * nodes periodically exchange a tuple using a "pull"
 * approach. Distributed reactions are setup which are triggered when
 * a tuple is locally output. After receiving the notification, the
 * remote node removes the tuple using a distributed in.
 *
 * Use two nodes only. The blue led should toggle alteratively
 * on the two nodes.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 10000
#define STEP 2000

module PingPongPull {

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

  NeighborTuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, outId, rdId, inId;

  event void Boot.booted() {

    tuple<uint16_t, uint16_t> p = newTuple(dontCare(), dontCare());

    call TS.addReaction(&reactionId, TRUE, TL_NEIGHBORHOOD, RAM_TS, 
            (tuple *) &p);
    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led1Toggle();
      dbg("app", "I have the tuple\n");
      call TimerApp.startOneShot(TIMER);
    }

    neighborTuple = newTuple(actualField(call AMPacket.address()));

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple<uint16_t, uint16_t> t = newTuple(
		       actualField(FAKE_DATA),
		       actualField(call AMPacket.address()));

    call Leds.led1Toggle();
    dbg("app", "Sending the tuple\n");
    call TS.out(&outId, TRUE, TL_LOCAL, RAM_TS, (tuple *) &t);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint16_t, uint16_t> *rcv;
    rcv = (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);

    if (rcv != NULL)
        dbg("app", "o%dv%dv%d\n", operationId.commandId, rcv->value0, rcv->value1);
    else
      if (reactionId.commandId == operationId.commandId)
        dbg("app", "1st reaction\n");
      else
        dbg("app", "1st in\n");

#ifdef PRINTF_SUPPORT
    if (rcv != NULL)
        printf("o%dv%dv%d\n", operationId.commandId, rcv->value0, rcv->value1);
    else
      if (reactionId.commandId == operationId.commandId)
        printf("1st react\n");
      else
        printf("1st in\n");
#endif

    PROCESS_OP(reactionId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call TS.in(&inId, TRUE, rcv->value1, RAM_TS, (tuple *) rcv);
	       });

    PROCESS_OP(inId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call Leds.led1Toggle();
		 dbg("app", "I have the tuple\n");
		 call TimerApp.startOneShot(STEP);
	       });    
    
    rcv = (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
    if (rcv != NULL) {
      call Leds.led0On();
#ifdef PRINTF_SUPPORT      
      if (reactionId.commandId == operationId.commandId)
        printf("2nd react\n");
      else
        printf("2nd in\n");
#endif
    }
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

