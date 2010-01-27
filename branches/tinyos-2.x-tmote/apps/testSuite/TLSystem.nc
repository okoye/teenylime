/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 04:42:42 -0600 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TLSystem.nc 289 2008-02-19 10:42:42Z lmottola $
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
 * Test for the TL System, and RSSI and LQI formals.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 10000

module TLSystem {

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

  tuple neighborTuple, neighborReact;
  TLOpId_t reactionId, remoteReactionId, rdgId;
  bool turn;

  event void Boot.booted() {


    tuple remoteReact = newTuple(2, 
				   formalField(TYPE_UINT8_T),
				   formalField(TYPE_UINT8_T));

    neighborReact = newTuple(3, 
			     formalField(TYPE_UINT16_T),
			     formalField(TYPE_LQI), 
			     formalField(TYPE_RSSI));
    
    neighborTuple = newTuple(3, 
			     actualField_uint16(call AMPacket.address()),
			     formalField(TYPE_LQI), 
			     formalField(TYPE_RSSI));

    call TS.addReaction(&remoteReactionId, FALSE, 
			TL_NEIGHBORHOOD, &remoteReact);
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &neighborReact);
    call TimerApp.startPeriodic(TIMER);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple p = newTuple(3, 
		       formalField(TYPE_UINT16_T),
		       formalField(TYPE_LQI), 
		       formalField(TYPE_RSSI));

    call TS.rdg(&rdgId, FALSE, TL_LOCAL, &p);
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {
    TLOpId_t remReact;
    uint8_t i;

    if (opIdCmp(&operationId, &rdgId)) {
#ifdef PRINTF_SUPPORT
      for (i=0; i<number; i++) {
	printf ("%u %u %d\n",
		tuples[i].fields[0].value.int16,
		tuples[i].fields[1].value.int8,
		tuples[i].fields[2].value.int8);
      }
      if (!turn) {
	turn = TRUE;
	printf("A\n");
	call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &neighborReact);
      }
      call PrintfFlush.flush();
#endif
    }

    if (opIdCmp(&operationId, &reactionId)
	&& tuples[0].fields[0].value.int16 != TL_LOCAL) {
#ifdef PRINTF_SUPPORT
      for (i=0; i<number; i++) {
	printf ("Re%u %u %d\n",
		tuples[i].fields[0].value.int16,
		tuples[i].fields[1].value.int8,
		tuples[i].fields[2].value.int8);
      }
      call PrintfFlush.flush();
      turn = FALSE;
      call TS.removeReaction(&remReact, reactionId);
#endif
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

