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
 * *	$Id: PingPongPush.nc 290 2008-02-19 11:34:07Z lmottola $
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

#include "tl_objs.h"
#include "Constants.h"
#include "TupleSpace.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * Test for remote out, local reactions and in operations. The nodes
 * periodically exchange a tuple using a "push" pattern, i.e., using
 * out. Local reactions notify the node when receiving a tuple. This
 * is removed from the local tuple space using in. It will be pushed
 * again later on.
 *
 * Use two nodes only. The blue led should be on and off alternatively
 * on the two nodes.
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

#define TIMER 10000
#define SEC 1000

module FlashPingPongPush {

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

  tuple<uint16_t, uint16_t>  p;
  NeighborTuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, outId, rdId, inId;
  uint16_t cnt;

  event void Boot.booted() {

    p = newTuple(dontCare(), dontCare());

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call TS.clear(FLASH_TS);

    if (call AMPacket.address() != PEER_A_ID) {
      call TS.addReaction(&reactionId, FALSE, TL_LOCAL, FLASH_TS, (tuple *) &p);
    }
    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.set(4);
      call TimerApp.startOneShot(TIMER);
    } 

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TimerApp.fired() {
    
    tuple<uint16_t, uint16_t> t = newTuple(
		       actualField(FAKE_DATA),
		       actualField(call AMPacket.address()));
    
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, FLASH_TS, (tuple *) &p);
    call Leds.led2Toggle();
    if (call AMPacket.address() == PEER_A_ID) {
      call TS.out(&outId, TRUE, PEER_B_ID, FLASH_TS, (tuple *) &t);
    } else {
      call TS.out(&outId, TRUE, PEER_A_ID, FLASH_TS, (tuple *) &t);    
    }
  }
  
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint16_t, uint16_t> *rcv;
    TLOpId_t removeId;
    cnt++;
    
    rcv = (tuple<uint16_t, uint16_t> *) call TS.getTuple(iterator);
    if (rcv == NULL) {
      if (cnt != 2)
        call Leds.led0On();
      return;
    }

    PROCESS_OP(reactionId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
         cnt = 0;
		 call TS.in(&inId, FALSE, TL_LOCAL, FLASH_TS, (tuple *) rcv);
         return;
	       }); 

    PROCESS_OP(inId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call Leds.led2Toggle();
		 call TS.removeReaction(&removeId, reactionId);
		 call TimerApp.startOneShot(TIMER);      
	       });
    call TS.nextSplitTuple(operationId, iterator); 
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

