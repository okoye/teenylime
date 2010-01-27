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
 * *	$Id: PingPongPull.nc 290 2008-02-19 11:34:07Z lmottola $
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

#define TIMER 10000
#define STEP 1000

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

  tuple neighborTuple;
  TLOpId_t reactionId, outId, rdId, inId;

  event void Boot.booted() {

    tuple p = newTuple(2, 
		       formalField(TYPE_UINT16_T), 
		       formalField(TYPE_UINT16_T));

    call TS.addReaction(&reactionId, TRUE, TL_NEIGHBORHOOD, &p);
    if (call AMPacket.address() == PEER_A_ID) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(TIMER);
    }

    neighborTuple = newTuple(1, actualField_uint16(call AMPacket.address()));

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple t = newTuple(2,
		       actualField_uint16(FAKE_DATA),
		       actualField_uint16(call AMPacket.address()));

    call Leds.led2Toggle();
    call TS.out(&outId, FALSE, TL_LOCAL, &t);
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {

    tuple temp;

    if (opIdCmp(&operationId, &reactionId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA) {
      copyTuple(&temp,&(tuples[0]));
      call TS.in(&inId, TRUE, temp.fields[1].value.int16, &temp);
    } else if (opIdCmp(&operationId, &inId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA) {
      call Leds.led2Toggle();
      call TimerApp.startOneShot(STEP);
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

