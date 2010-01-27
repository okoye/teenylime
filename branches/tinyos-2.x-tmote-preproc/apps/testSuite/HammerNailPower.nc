/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 863 $
 * * DATE
 * *    $LastChangedDate: 2009-06-18 09:26:53 -0500 (Thu, 18 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: HammerNailPower.nc 863 2009-06-18 14:26:53Z lmottola $
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
#include "TMoteTuning.h"

/**
 * Test application for TL PacketLink layer.
 */

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define TIMER 2000

module HammerNailPower {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface Tuning;

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

  // Only executed on PEER_AD_ID
  event void TimerApp.fired() {

    uint16_t power;
    tuple<uint16_t, uint16_t> t;

    count++;
    power = (count % 27)+1;
    t = newTuple(actualField(count), actualField(power));
    call Tuning.setImmediate(KEY_TX_POWER, power);
    call TS.out(&outId, TRUE, PEER_B_ID, RAM_TS, (tuple *) &t);
  }

  void readTupleReceived(tuple<uint16_t, uint16_t>* t) {

#ifdef PRINTF_SUPPORT      
    printf ("C%dP%d\n", t->value0,t->value1);
    call PrintfFlush.flush();
#endif
  }
  
  // Only executed on PEER_B_ID 
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint16_t, uint16_t> *rcv = 
        (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);

    PROCESS_OP(reactionId,
	       if (rcv != NULL) {
		 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
	       }); 

    PROCESS_OP(inId,
	       if (rcv != NULL) {
		 call Leds.led1Toggle();
		 readTupleReceived(rcv);
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

    // In case the reliable out failed, we are going to re-send the old value
    if (completionCode == RELIABLE_OP_FAIL) {
      count = failed->value1; 
      call Leds.led0Toggle();
    }
  }

  event void Tuning.setDone(uint8_t key, uint16_t value) {
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

