/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 42 $
 * * DATE
 * *    $LastChangedDate: 2007-05-30 16:28:04 +0200 (Wed, 30 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *  $Id: ReactiveNode.nc 42 2007-05-30 14:28:04Z lmottola $
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


#define TIMER 1024
#define BOOT 1024
#define NR_REACTS 10
#define TEMPERATURE_READING 1

volatile uint16_t counter = 0;

module TestBenchmark {

  uses {
    interface Timer<TMilli> as Timer;
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface Boot;
    interface AMPacket;
    interface StdControl as TSControl;
    interface Leds;
  }
}


implementation {

  TLOpId_t out_id;

  event void Boot.booted() {
    dbg(DBG_USR3, "Pure local.\n");
    dbg(DBG_USR3, "Perform a set of operations and measure total response time.\n");

    call TSControl.start();
    call Timer.startOneShot(BOOT);
    srand(8);
  }

  event void Timer.fired() {
    int i = 0;
    volatile int j = 0;
    declareTuple(t4, TUPLE_4_FMT);
    declareTuple(t3, TUPLE_3_FMT);
    declareTuple(t2, TUPLE_2_FMT);
    declareQuery(q3, 3);
    declareQuery(q2, 2);
    TLOpId_t opID, reaction;
    declareQuery(q1, 1);
    declareQuery(q0, 0);

    dbg(DBG_USR3, "Timer fired\n");


    j++;
    asm("time0:");
    for (i = 0; i < 10; i++) {
      newTuple_TUPLE_3_FMT(t3, 1, 1, i);
      call TS.out(&opID, FALSE, TL_LOCAL, t3);
      newTuple_TUPLE_4_FMT(t4, 1, 1, 1, i);
      call TS.out(&opID, FALSE, TL_LOCAL, t4);
    }
    newQuery(q3, TUPLE_2_FMT, 2, eqCond(0,1), eqCond(1, 80));

    call TS.addReaction(&reaction, FALSE, TL_LOCAL, q3);

    call TS.addReaction(&opID, FALSE, TL_LOCAL, q3);
    call TS.addReaction(&opID, FALSE, TL_LOCAL, q3);
    call TS.removeReaction(&reaction);
    call TS.addReaction(&opID, FALSE, TL_LOCAL, q3);

    newQuery(q3, TUPLE_3_FMT, 3, eqCond(0,1), eqCond(1, 1), eqCond(2, 1));
    newTuple_TUPLE_4_FMT(t4, 4, 4, 4, 4);
    newTuple_TUPLE_3_FMT(t3, 1, 1, 1);
    newTuple_TUPLE_2_FMT(t2, 1, 1);

    // Perform 5 Out operations with an increasing nr of reactions installed
    // The reactions do not match the tuple being output.
    for (i = 0; i < 5; i++) {
      call TS.out(&opID, FALSE, TL_LOCAL, t3);
      newQuery(q3, TUPLE_3_FMT, 3, eqCond(0,1), eqCond(1, 1), eqCond(2, 1));
      call TS.in(&opID, FALSE, TL_LOCAL, q3);
      newQuery(q3, TUPLE_3_FMT, 3, eqCond(0,1), eqCond(1, 1), eqCond(2, 0));
      call TS.addReaction(&opID, FALSE, TL_LOCAL, q3);
    }

    // Remove the 4-field tuples we added in the beginning
    // This creates some holes in dynamic memory.
    for (i = 0; i < 10; i++) {
      newQuery(q1, TUPLE_4_FMT, 1, eqCond(3, i));
      call TS.in(&opID, FALSE, TL_LOCAL, q1);
    }

    newQuery(q3, TUPLE_3_FMT, 3, eqCond(0,1), eqCond(1, 1), eqCond(2, 1));
    newTuple_TUPLE_3_FMT(t3, 1, 1, 16);

    // Perform a few distributed operations
    for (i = 0; i < 4; i++) {
      call TS.out(&opID, FALSE, TL_NEIGHBORHOOD, t3);
      call TS.rd(&opID, FALSE, TL_NEIGHBORHOOD, q3);
      call TS.addReaction(&reaction, FALSE, TL_NEIGHBORHOOD, q3);
      call TS.removeReaction(&reaction);
    }

    newTuple_TUPLE_3_FMT(t3, 1, 1, 16);
    newQuery(q2, TUPLE_2_FMT, 2, eqCond(0,1), eqCond(1, 80));
    newQuery(q1, TUPLE_4_FMT, 1, eqCond(0,4));

    for (i = 0; i < 14; i++) {
      if (i % 2 == 0) {
        call TS.in(&opID, FALSE, TL_LOCAL, q1);
      }
      call TS.in(&opID, FALSE, TL_LOCAL, q3);
      call TS.rd(&opID, FALSE, TL_LOCAL, q2);
      newTuple_TUPLE_3_FMT(t3, 1, 1, 1);
      call TS.out(&opID, FALSE, TL_LOCAL, t3);
      call TS.out(&opID, FALSE, TL_LOCAL, t2);
      newTuple_TUPLE_4_FMT(t4, 4, 4, 4, 4);
      call TS.out(&opID, FALSE, TL_LOCAL, t4);
    }

    // Delete all tuples from the tuple space
    for (i = 0; i < 1; i++) {
      newQuery(q0, TUPLE_2_FMT, 0);
      call TS.ing(&opID, FALSE, TL_LOCAL, q0);
      newQuery(q0, TUPLE_3_FMT, 0);
      call TS.ing(&opID, FALSE, TL_LOCAL, q0);
      newQuery(q0, TUPLE_4_FMT, 0);
      call TS.ing(&opID, FALSE, TL_LOCAL, q0);
    }

    asm("time1:");
    // Call stop, because we made LTL to print the current number of tuples when it stops.
    // In this way we check the end result, and compare it with the result of this program
    // running in the original teenylime version.
    call TSControl.stop();
    j++;
  }

   event result_t TS.reifyCapabilityTuple(Tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t *operationId, Tuple *tuples[], uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    return SUCCESS;
  }
}
