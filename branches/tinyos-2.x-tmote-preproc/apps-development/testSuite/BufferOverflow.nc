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
 * *	$Id: BufferOverflow.nc 856 2009-06-03 13:23:36Z sguna $
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
 * Check for buffer overflow for ing. Node B must be started after node A.
 * Under normal operation, the blue led turns on on node A.
 * 
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

#define TIMER 3000

module BufferOverflow {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface Random;
    
    interface AMPacket;

    interface Leds;
    interface TLObjects;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple<uint16_t> neighborTuple;
  TLOpId_t ingId, outId;
  int n;

  event void Boot.booted() {
    tuple<uint8_t> a;

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    a = newTuple(actualField(FAKE_DATA));
    n = SLAB_SIZE / call TLObjects.tuple_sizeof((tuple *) &a);


    if (call AMPacket.address() == PEER_A_ID) {
      int i;
      for (i = 0; i < n; i++) {
        a.value0 = i;
        call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      }
      a.value0 = n;
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &a);
      call Leds.led2Toggle();
    } else {
      call TimerApp.startOneShot(TIMER);
    }

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {
    tuple<uint8_t> p = newTuple(dontCare());
    if (call AMPacket.address() == PEER_A_ID)  
      call TS.ing(&ingId, FALSE, PEER_B_ID, RAM_TS, (tuple *) &p);
    else
      call TS.ing(&ingId, FALSE, PEER_A_ID, RAM_TS, (tuple *) &p);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 
    int i = 0;
    tuple<uint8_t> *rcv;

    while ((rcv = (tuple<uint8_t> *) call TS.nextTuple(operationId, iterator)) != NULL) {
#ifdef PRINTF_SUPPORT
      printf("[%d]%d; ", i, rcv->value0);
#endif
      if (rcv->value0 != i) {
        call Leds.led0On();
        call Leds.led1On();
        call Leds.led2On();
      } else {
	call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
      }
      i++;
    }

#ifdef PRINTF_SUPPORT
    printf("M%dn%d\n", n, i);
    call PrintfFlush.flush();
#endif
    if (i != n)
      call Leds.led0On();
    else
      call Leds.led2On();
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
