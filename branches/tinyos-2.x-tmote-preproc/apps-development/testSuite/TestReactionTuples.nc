/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 528 $
 * * DATE
 * *    $LastChangedDate: 2008-06-27 15:24:38 +0100 (ven, 27 giu 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: ReactionTuples.nc 528 2008-06-27 14:24:38Z lmottola $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "TupleSpace.h"

/**
 * Complex test for removing reactions in the reaction handler.
 * Under normal conditions, the tuple space should not get full.
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

#define TIMERA 1000
#define TIMERB 300

module TestReactionTuples {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;
    interface Timer<TMilli> as TokenTimer;
    
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
  TLOpId_t reactionId, outId, inId, remreactionId, rdTkn;
  int zz;

  event void Boot.booted() {
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());
    
    neighborTuple = newTuple(actualField(call AMPacket.address()));
    p = newTuple(actualField(1), actualField(2));
    
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
    zz = 1;              
    call TimerApp.startPeriodic(TIMERA);
    
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif  
  }

  event void TimerApp.fired() {
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare());
    
    p = newTuple(actualField(1), actualField(2));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);	                   
    call TokenTimer.startOneShot(TIMERB);
  }

  event void TokenTimer.fired() {
    tuple<uint8_t, uint16_t> a;

    if (zz == 1){
      a = newTuple(actualField(1), actualField(2));
      call TS.rd(&rdTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      zz = 2;
      call TokenTimer.startOneShot(TIMERB);
      call PrintfFlush.flush();
      return;
    } 
    call PrintfFlush.flush();
    zz = 1;
  }


  task void pippo()
  {
    call TS.removeReaction(&remreactionId,reactionId);
  }


  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    tuple<uint8_t, uint16_t> b, *rec;
   
    PROCESS_OP(rdTkn,
      rec = 
        (tuple<uint8_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
      if (rec == NULL) {
 	    b = newTuple(actualField(1), actualField(2));
        call Leds.led2Toggle();
        call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &b);
      }
	);   
	
    PROCESS_OP(inId,
      rec = 
        (tuple<uint8_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
      if (rec != NULL) {
        call TS.nextTuple(operationId, iterator);
        /*post pippo();*/
        call TS.removeReaction(&remreactionId, reactionId);
      } 
	);   
   
    PROCESS_OP(reactionId, 
      call Leds.led2Toggle();
      rec = 
        (tuple<uint8_t, uint16_t> *) call TS.nextTuple(operationId, iterator); 
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rec);       
    );
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
    CHECK_OP(remreactionId, OP_COMPLETED_OK,
	     call Leds.led2On();				   
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

