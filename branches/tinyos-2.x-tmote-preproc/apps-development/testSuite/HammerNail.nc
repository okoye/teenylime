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
 * *	$Id: HammerNail.nc 289 2008-02-19 10:42:42Z lmottola $
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

/**
 * Test application for TL PacketLink layer.
 */

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define TIMER 2000

module HammerNail {

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

  uint16_t count = 0;
  tuple<uint16_t> neighborTuple;
  TLOpId_t reactionId, outId, rdId, inId;

  event void Boot.booted() {

    tuple<uint16_t, uint16_t> p = newTuple(
            dontCare(),
            dontCare());

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    if (call AMPacket.address() == PEER_A_ID) { 
      call TimerApp.startPeriodic(TIMER);
    } else {
      call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    }
    
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  // Only executed on PEER_A_ID
  event void TimerApp.fired() {

    tuple<uint16_t, uint16_t> t = newTuple(
					   actualField(FAKE_DATA),
					   actualField(count++));
    call TS.out(&outId, TRUE, PEER_B_ID, RAM_TS, (tuple *) &t);
  }

  void readTupleReceived(tuple<uint16_t, uint16_t>* t) {

#ifdef PRINTF_SUPPORT      
      printf ("C %d\n",  t->value1);
      call PrintfFlush.flush();
#endif
  }
  
  // Only executed on PEER_B_ID 
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint16_t, uint16_t> *rcv = 
        (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);

    PROCESS_OP(reactionId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
	       }); 

    PROCESS_OP(inId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 if (rcv->value1 != count) {
		   call Leds.led0Toggle();
		 } else {
		   call Leds.led1Toggle();
		 }
		 readTupleReceived(rcv);
		 count = rcv->value1 + 1;
	       });     

    rcv = (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
    if (rcv != NULL)
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
    
    tuple<uint16_t, uint16_t> *failed =
        (tuple<uint16_t, uint16_t> *) returningTuple;

    // In case the reliable out failed, we re-send the old value
    if (completionCode == RELIABLE_OP_FAIL) {
      count = failed->value1; 
      call Leds.led0Toggle();
#ifdef PRINTF_SUPPORT
      printf ("C %d %d\n", failed->value1, count);
      call PrintfFlush.flush();
#endif
    }
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

