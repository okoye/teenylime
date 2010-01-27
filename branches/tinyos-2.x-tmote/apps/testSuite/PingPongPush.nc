/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 290 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 05:34:07 -0600 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: PingPongPush.nc 290 2008-02-19 11:34:07Z lmottola $
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
 * Test for remote out, local reactions and in operations. The nodes
 * periodically exchange a tuple using a "push" pattern, i.e., using
 * out. Local reactions notify the node when receiving a tuple. This
 * is removed from the local tuple space using in. Later it will be
 * pushed again.
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

module PingPongPush {

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

  tuple neighborTuple, p;
  TLOpId_t reactionId, outId, rdId, inId;

  event void Boot.booted() {

    p = newTuple(2,
		       formalField(TYPE_UINT16_T),
		       formalField(TYPE_UINT16_T));

    neighborTuple = newTuple(1, actualField_uint16(call AMPacket.address()));

    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(TIMER);
    } else {
      call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p);
    }
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple t = newTuple(2,
		       actualField_uint16(FAKE_DATA),
		       actualField_uint16(call AMPacket.address()));
 
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p);
    call Leds.led2Toggle();
    if (call AMPacket.address() == PEER_A_ID) {
      call TS.out(&outId, TRUE, PEER_B_ID, &t);
    } else {
      call TS.out(&outId, TRUE, PEER_A_ID, &t);    
    }
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {

    tuple temp;
    TLOpId_t removeId;

    if (opIdCmp(&operationId, &reactionId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA) {
      copyTuple(&temp,&(tuples[0]));
      call TS.in(&inId, FALSE, TL_LOCAL, &temp);
    } else if (opIdCmp(&operationId, &inId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(SEC);      
      call TS.removeReaction(&removeId, reactionId);
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

