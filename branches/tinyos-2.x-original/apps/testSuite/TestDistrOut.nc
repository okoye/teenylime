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

module TestDistrOut {

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
    dbg(DBG_USR3, "Test distributed OUT operation.\n");

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
    declareTuple(t,MY_TUPLE_FMT);

    dbg(DBG_USR3, "Timer fired\n");
    // Out tuple
    _asm("out0:");
    resetTuple(t, MY_TUPLE_FMT);
    setUint16Field(t, 0, 1);
    setUint16Field(t, 1, 1);
    setUint16Field(t, 2, 1);
    setUint16Field(t, 3, counter++);
    call TS.out(FALSE, TL_NEIGHBORHOOD, t, &out_id);
    _asm("out1:");
  }

}



