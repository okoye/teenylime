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
 * *	$Id: RemoteBulkOps.nc 856 2009-06-03 13:23:36Z sguna $
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
 * Test remote bulk operations and the corresponding
 * operationCompleted event. When the remote operation is reliably
 * executed, the green led blinks on correct completion, the red led
 * blinks otherwise. No operationCompleted event is signaled for
 * unreliable ops.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

#define TIMER 15000
#define NUM_TUPLES 6

module RemoteBulkOps {

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

  NeighborTuple<uint16_t, lqi, uint16_t> neighborTuple;

  TLOpId_t rdgId, outId;
  bool readingRem;
  bool firstRound;

  void startRemRdg(uint16_t destination){

    tuple<uint16_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t> rem;
    readingRem = TRUE;
    rem = newTuple(
                   dontCare(),
                   dontCare(),                           
                   dontCare(),
                   dontCare(),
                   dontCare(),
                   dontCare());
    call TS.rdg(&rdgId, TRUE, destination, RAM_TS, (tuple *) &rem);

#ifdef PRINTF_SUPPORT
    printf("Rem Rdg %u", destination);
    call PrintfFlush.flush();
#endif
  }

  void startLocRdg(){
    tuple<uint16_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t> loc;
    loc = newTuple(
                   dontCare(),
                   dontCare(),                           
                   dontCare(),
                   dontCare(),
                   dontCare(),
                   dontCare());
    call TS.rdg(&rdgId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &loc);

#ifdef PRINTF_SUPPORT
    printf("Loc Rdg");
#endif
  }


  void insertTuples(){

    uint8_t i;
    tuple<uint16_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t> temp;
    
    for (i=0; i<NUM_TUPLES; i++) {
      temp = newTuple(
		      actualField(i),
		      actualField(FAKE_DATA),
		      actualField(FAKE_DATA),
		      actualField(FAKE_DATA),
		      actualField(FAKE_DATA),
		      actualField(FAKE_DATA));
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
    }  

#ifdef PRINTF_SUPPORT
    printf("Out\n");
    call PrintfFlush.flush();
#endif
  }

  event void Boot.booted() {

    firstRound = TRUE;
    readingRem = FALSE;
    call TimerApp.startPeriodic(TIMER);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    if (call AMPacket.address() == PEER_A_ID){
      if (firstRound){
        insertTuples();
        firstRound = FALSE;
      }
      else
        startLocRdg();
    } else {
      if (!readingRem){
        startRemRdg(PEER_A_ID);
      } else {
#ifdef PRINTF_SUPPORT
        printf("Rem Rdg progress\n");
        call PrintfFlush.flush();
#endif
      }
    }
  }

  void printResults(TLOpId_t operationId, TupleIterator *iterator) {

    tuple<uint16_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t>
      *rcv;

#ifdef PRINTF_SUPPORT
    printf("{");
    for (rcv = (tuple<uint16_t, uint8_t, uint16_t, uint16_t,
		uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
	 rcv != NULL;
	 rcv = (tuple<uint16_t, uint8_t, uint16_t, uint16_t,
		uint16_t, uint16_t> *) call
	   TS.nextTuple(operationId, iterator)){
      printf("<%u>", rcv->value0);
    }
    printf("}\n");
    call PrintfFlush.flush();
#endif

  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 


    PROCESS_OP(rdgId,
	       printResults(operationId, iterator);
               readingRem = FALSE;
	       );
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    neighborTuple = newTuple(
                             actualField(call AMPacket.address()),
                             lqiRead(),                             
                             actualField(FAKE_DATA));
    return (tuple *) &neighborTuple;
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,
                   TLTupleSpace_t ts,
				   tuple* returningTuple) {

    CHECK_OP(rdgId, RELIABLE_OP_FAIL,
	     readingRem = FALSE;
	     call Leds.led0Toggle();
	     );

    CHECK_OP(rdgId, QUERY_SENT_OK,
	     call Leds.led1Toggle();
	     );

    CHECK_OP(rdgId, OP_COMPLETED_OK,
	     call Leds.led2Toggle();
	     );
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
