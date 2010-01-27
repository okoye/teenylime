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
 * *	$Id: PingPongPushRadioControl.nc 856 2009-06-03 13:23:36Z sguna $
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

#include "TMoteTuning.h"
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
 * again later on. This version turns the radio ON and OFF between
 * different operations to check the functioning of the Tuning
 * interface. As such, this test is TMote specific.
 *
 * Use two nodes only. The blue led should be on and off alternatively
 * on the two nodes.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 10000
#define SEC 1000

module PingPongPushRadioControl {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface AMPacket;

    interface Random;

    interface Leds;

    interface Tuning;

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

  event void Boot.booted() {

    p = newTuple(dontCare(), dontCare());
    neighborTuple = newTuple(actualField(call AMPacket.address()));

    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(TIMER);
    } else {
      call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    }
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TimerApp.fired() {

    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    call Leds.led2Toggle();
    call Tuning.set(KEY_RADIO_CONTROL,RADIO_ON);

#ifdef PRINTF_SUPPORT
    printf ("TA\n");
#endif
  }

  event void Tuning.setDone(uint8_t key, uint16_t value) {

#ifdef PRINTF_SUPPORT
    printf ("SD\n");
    call PrintfFlush.flush();
#endif

    if (key == KEY_RADIO_CONTROL) {
      if (value == RADIO_ON) {
	tuple<uint16_t, uint16_t> t = newTuple(
					       actualField(FAKE_DATA),
					       actualField(call AMPacket.address()));
	if (call AMPacket.address() == PEER_A_ID) {
#ifdef PRINTF_SUPPORT
	  printf ("O\n");
#endif
	  call TS.out(&outId, TRUE, PEER_B_ID, RAM_TS, (tuple *) &t);
	} else {
#ifdef PRINTF_SUPPORT
	  printf ("O\n");
#endif
	  call TS.out(&outId, TRUE, PEER_A_ID, RAM_TS, (tuple *) &t);    
	}    
      } else if (value == RADIO_OFF) {
	// Waits for next push
	call TimerApp.startOneShot(TIMER);      
      } else {
	call Leds.led0On();
      }
    } else {
      call Leds.led0On();
    }
  }
  
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint16_t, uint16_t> *rcv;
    TLOpId_t removeId;
    
    rcv = 
        (tuple<uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator); 

    PROCESS_OP(reactionId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
	       }); 

    PROCESS_OP(inId,
	       if (rcv != NULL
		   && rcv->value0 == FAKE_DATA) {
		 call Leds.led2Toggle();
		 call TS.removeReaction(&removeId, reactionId);
		 call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF);
	       });
    
#ifdef PRINTF_SUPPORT
    printf ("TR\n");
#endif

    if (call TS.nextTuple(operationId, iterator) != NULL) {
      call Leds.led0On();
    }
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

