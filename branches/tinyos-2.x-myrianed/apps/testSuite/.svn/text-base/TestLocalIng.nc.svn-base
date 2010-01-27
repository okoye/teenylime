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

volatile uint16_t counter = 0;

module TestLocalIng {

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

  event void Boot.booted() {
    dbg(DBG_USR3, "Pure local test.\n");
    dbg(DBG_USR3, "Test ING to find maximum stack size.\n");

    call TSControl.start();
    call Timer.startOneShot(BOOT);
  }

  event result_t TS.reifyCapabilityTuple(Tuple *ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t *opId, Tuple *tuples[], uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    return SUCCESS;
  }


  event void Timer.fired() {
    declareTuple(t, TUPLE_4_FMT);
    declareQuery(my_query, 4);
    uint8_t i; TLOpId_t opID;

    dbg3("Timer fired\n");
    newTuple_TUPLE_4_FMT(t, 1, 1, 1, 1);

    for (i = 0; i < 11; i++) {

      call TS.out(&opID, FALSE, TL_LOCAL, t);
    }
    newQuery(my_query, TUPLE_4_FMT, 4, eqCond(0,1), eqCond(1,1), eqCond(2,1), eqCond(3,1));

    _asm("in0:");
    call TS.ing(&opID, FALSE, TL_LOCAL, my_query);
    _asm("in1:");
    call TS.ing(&opID, FALSE, TL_LOCAL, my_query);
  }
}

