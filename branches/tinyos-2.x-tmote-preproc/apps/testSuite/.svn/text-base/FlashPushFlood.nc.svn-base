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
 * Program one node with ID 11 and other nodes with IDs != 11. All nodes will
 * flood node 11 with tuples. Under normal operation, node 11 should toggle
 * the blue led every 1s.
 * Warning: Tuple space fulls are expected.
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

#define TIMER 1000
#define SEC 1000

module FlashPushFlood {

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
  TLOpId_t outId, reactionId;
  int cnt;

  event void Boot.booted() {
    tuple<uint16_t, uint16_t> p = newTuple(dontCare(), dontCare());

    call TS.addReaction(&reactionId, TRUE, TL_LOCAL, FLASH_TS, (tuple *) &p);

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call Leds.set(0xf);
    call TS.clear(FLASH_TS);
    if (TOS_NODE_ID != PEER_A_ID)
      call TimerApp.startOneShot(TIMER);
    else
      call TimerApp.startPeriodic(TIMER);
    call Leds.set(0);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TimerApp.fired() {
    
    tuple<uint16_t, uint16_t> t = newTuple(
		       actualField(FAKE_DATA),
		       actualField(call AMPacket.address()));
    
    call Leds.led2Toggle();
    if (call AMPacket.address() == PEER_A_ID)
      return;
    cnt = 0;
    call TS.out(&outId, TRUE, PEER_A_ID, FLASH_TS, (tuple *) &t);
  }
  
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    call Leds.led1Toggle();
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
    tuple<uint16_t, uint16_t> t = newTuple(
		       actualField(FAKE_DATA),
		       actualField(call AMPacket.address()));
    if (++cnt == 100) {
      call TimerApp.startOneShot(TIMER);
      return;
    }
    call TS.out(&outId, TRUE, PEER_A_ID, FLASH_TS, (tuple *) &t);
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

