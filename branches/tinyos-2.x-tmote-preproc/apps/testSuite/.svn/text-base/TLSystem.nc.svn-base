/**
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 12:42:42 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TLSystem.nc 289 2008-02-19 10:42:42Z lmottola $
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
    interface TLObjects;

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

  NeighborTuple<uint16_t, lqi, rssi> neighborTuple;
  tuple<uint16_t, lqi, rssi> neighborReact;
  TLOpId_t reactionId, remoteReactionId, rdgId;
  bool turn;

  event void Boot.booted() {

    tuple<uint8_t, uint8_t> remoteReact = newTuple(
						   dontCare(),
						   dontCare());
    
    neighborReact = newTuple(
			     dontCare(),
			     lqiRead(),
			     rssiRead());

    neighborTuple = newTuple(
			     actualField(call AMPacket.address()),
			     lqiRead(),
			     rssiRead());
    
    call TS.addReaction(&remoteReactionId, FALSE, TL_NEIGHBORHOOD, RAM_TS, 
            (tuple *) &remoteReact);
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS,
            (tuple *) &neighborReact);

    call TimerApp.startPeriodic(TIMER);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    tuple<uint16_t, lqi, rssi> p = newTuple(
					    dontCare(),
					    lqiRead(),
					    rssiRead());
            
#ifdef PRINTF_SUPPORT
    call PrintfFlush.flush();
#endif

    call Leds.led1Toggle();
    call TS.rdg(&rdgId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }

  void reactionResult(TLOpId_t operationId, TupleIterator *iterator) {

    // All returned tuples are of the same type and size
#ifdef PRINTF_SUPPORT
    TLOpId_t remReact;
    bool local = TRUE;

    tuple<uint16_t, lqi, rssi> *res;

    while ((res = (tuple<uint16_t, lqi, rssi> *) call TS.nextTuple(operationId,
                    iterator)) != NULL) {
      if (res->value0 != TL_LOCAL) {
        printf ("Re%d %d %d/",
                  res->value0,
                  res->value1,
                  res->value2);
        local = FALSE;

      }
    }
    if (!local) {
      printf("\n");
      call PrintfFlush.flush();
      turn = FALSE;
      call TS.removeReaction(&remReact, reactionId);
    }
#endif
    
  }

  void rdgResult(TLOpId_t operationId, TupleIterator *iterator) {

    // All returned tuples are of the same type and size
#ifdef PRINTF_SUPPORT

    tuple<uint16_t, lqi, rssi> *res;

    while ((res = (tuple<uint16_t, lqi, rssi> *) call TS.nextTuple(operationId,
                    iterator))
            != NULL) {
      printf ("Rd%d %d %d/", res->value0, res->value1, res->value2);
    }
    printf("\n");
    
    call PrintfFlush.flush();
#endif
     if (!turn) {
      turn = TRUE;
      call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, 
              (tuple *) &neighborReact);
    }
   
    
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 
    
    PROCESS_OP(rdgId, rdgResult(operationId, iterator); );

    PROCESS_OP(reactionId, reactionResult(operationId, iterator); );
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

