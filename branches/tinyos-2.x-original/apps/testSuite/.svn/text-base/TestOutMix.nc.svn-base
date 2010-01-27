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

module TestOutMix {

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

//  tuple template;
//  TLOpId_t reactions[NR_REACTS];
  TLOpId_t out_id;

  event void Boot.booted() {
    declareTuple(nghTuple, NGH_FMT);
    dbg(DBG_USR3, "Test OUT operation for a mix of small and big tuples.\n");

    call TSControl.start();
    resetTuple(nghTuple, NGH_FMT);
    setUint16Field(nghTuple, 0, call AMPacket.address());
    setUint16Field(nghTuple, 1, OUT_NODE);
    call TeenyLIMESystem.setNeighborTuple(nghTuple);
    call Timer.startPeriodic(PRESC(BOOT));
  }

  event result_t TS.reifyCapabilityTuple(tuple_t* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t *operationId, tuple_t *tuples[], uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    _asm("tupleready0:");
    if (number == 100) {
      uart_puts("tr\n");
    }
    if (number != 0) {
      _asm("tupleready1:");
      counter++;
    }
    return SUCCESS;
  }

  event void Timer.fired() {
    uint8_t i;
    declareTuple(t2,NGH_FMT);
    declareTuple(t3,TUPLE_3_FMT);
    declareTuple(t4,MY_TUPLE_FMT);
    declareTuple(t5,TUPLE_5_FMT);

    resetTuple(t2, NGH_FMT);
    resetTuple(t3, TUPLE_3_FMT);
    resetTuple(t4, MY_TUPLE_FMT);
    resetTuple(t5, TUPLE_5_FMT);


//    dbg3("NGH_FMT %hu\n",TUPLE_SIZE(NGH_FMT));
    dbg(DBG_USR3, "Timer fired\n");
    // Out tuple
    _asm("out0:");
    for (i = 0; i < 5; i++) {
      out_id = call TS.out(FALSE, TL_LOCAL, t2);
    }
    for (i = 0; i < 5; i++) {
      out_id = call TS.out(FALSE, TL_LOCAL, t3);
    }
    for (i = 0; i < 5; i++) {
      out_id = call TS.out(FALSE, TL_LOCAL, t4);
    }
    for (i = 0; i < 5; i++) {
      out_id = call TS.out(FALSE, TL_LOCAL, t5);
    }
    _asm("out1:");
  }

}



