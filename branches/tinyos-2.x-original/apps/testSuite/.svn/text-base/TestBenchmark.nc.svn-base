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

  TLOpId_t reaction;
  TLOpId_t out_id;
  tuple neighborTuple;

  event void Boot.booted() {
    dbg(DBG_USR3, "Pure local.\n");
    dbg(DBG_USR3, "Perform a set of operations and measure total response time.\n");
    neighborTuple = newTuple(2, actualField_uint16(1),actualField_uint16(9));
    neighborTuple = newTuple(2, actualField_uint16(1),actualField_uint16(9));
    call TSControl.start();
    call Timer.startOneShot(PRESC(BOOT));
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, tuple *tuples, uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    return SUCCESS;
  }


  void randomTest() {
  }

  event void Timer.fired() {
    int i = 0;
    volatile int j = 0;
    tuple t3, t4, t2, q2, q1;
    tuple q;
    TLOpId_t opID;

    dbg(DBG_USR3, "Timer fired\n");

    j++;
    _asm("time0:");

    for (i = 0; i < 10; i++) {
      t3 = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(i));
      opID = call TS.out(FALSE, TL_LOCAL, &t3);
      t4 = newTuple(4, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1), actualField_uint16(i));
      opID = call TS.out(FALSE, TL_LOCAL, &t4);
    }

    // These OUTs and INs simulate a couple of reifyNeighborTuple() events
    // These operations are not performed by the TestBenchmark for the new TL implementation.
    for (i = 0; i < 4; i++) {
      t2 = newTuple(2, actualField_uint16(1), actualField_uint16(33));
      opID = call TS.out(FALSE, TL_LOCAL, &t2);
      opID = call TS.in(FALSE, TL_LOCAL, &t2);
    }
    q = newTuple(2, actualField_uint16(1), actualField_uint16(80));

    reaction = call TS.addReaction(FALSE, TL_LOCAL, &q);
    opID = call TS.addReaction(FALSE, TL_LOCAL, &q);
    opID = call TS.addReaction(FALSE, TL_LOCAL, &q);
    call TS.removeReaction(reaction);
    opID = call TS.addReaction(FALSE, TL_LOCAL, &q);
    q = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1));

    t4 = newTuple(4, actualField_uint16(4), actualField_uint16(4), actualField_uint16(4), actualField_uint16(4));
    t3 = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1));
    t2 = newTuple(2, actualField_uint16(1), actualField_uint16(1));

    // Perform 5 Out operations with an increasing nr of reactions installed
    for (i = 0; i < 5; i++) {
      out_id = call TS.out(FALSE, TL_LOCAL, &t3);
      q = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1));
      out_id = call TS.in(FALSE, TL_LOCAL, &q);
      q = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(0));
      reaction = call TS.addReaction(FALSE, TL_LOCAL, &q);
    }

    // Remove the 4-field tuples we added in the beginning
    // This creates some holes in dynamic memory (not here, but in the new implementation)
    for (i = 0; i < 10; i++) {
      q1 = newTuple(4, formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T), actualField_uint16(i));
      opID = call TS.in(FALSE, TL_LOCAL, &q1);
    }

    q = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1));
    t3 = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(16));

    // Perform a few distributed operations
    for (i = 0; i < 4; i++) {
      out_id = call TS.out(FALSE, TL_NEIGHBORHOOD, &t3);
      opID = call TS.rd(FALSE, TL_NEIGHBORHOOD, &q);
      reaction = call TS.addReaction(FALSE, TL_NEIGHBORHOOD, &q);
      call TS.removeReaction(reaction);
    }
    t3 = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(16));
    q2 = newTuple(2, actualField_uint16(1), actualField_uint16(80));
    q1 = newTuple(4, actualField_uint16(4), formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T));

    for (i = 0; i < 14; i++) {
      if (i % 2 == 0) {
        opID = call TS.in(FALSE, TL_LOCAL, &q1);
      }
      opID = call TS.in(FALSE, TL_LOCAL, &q);
      opID = call TS.rd(FALSE, TL_LOCAL, &q2);
      t3 = newTuple(3, actualField_uint16(1), actualField_uint16(1), actualField_uint16(1));
      opID = call TS.out(FALSE, TL_LOCAL, &t3);
      opID = call TS.out(FALSE, TL_LOCAL, &t2);
      t4 = newTuple(4, actualField_uint16(4), actualField_uint16(4), actualField_uint16(4), actualField_uint16(4));
      opID = call TS.out(FALSE, TL_LOCAL, &t4);
    }

    // Remove all tuples from the tuple space
    q1 = newTuple(4, formalField(TYPE_DONT_CARE), formalField(TYPE_DONT_CARE), formalField(TYPE_DONT_CARE), formalField(TYPE_DONT_CARE));
    for (i = 0; i < 36; i++) {
      opID = call TS.ing(FALSE, TL_LOCAL, &q1);
    }
    _asm("time1:");
    j++;
    call TSControl.stop();
  }
}




