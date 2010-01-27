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
 * *	$Id: ReactiveNode.nc 42 2007-05-30 14:28:04Z lmottola $
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

module TestInReceive {

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
  tuple neighborTuple;
  TLOpId_t out_id;

  event void Boot.booted() {
    dbg(DBG_USR3, "Test IN operation on tuple received from other nodes.\n");

    call TSControl.start();

    resetTuple(&neighborTuple, FMT_NGH);
    setUint16Field(&neighborTuple, 0, call AMPacket.address());
    setUint16Field(&neighborTuple, 1, IN_NODE);

    call Timer.startOneShot(PRESC(BOOT));
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t *operationId, tuple *tuples, uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    _asm("tupleready0:");

    if (number != 0) {
      _asm("tupleready1:");
      counter++;

      uart_puthex2(getUint16Field(tuples, 2));
      uart_puts("<-TR\n");
      uart_puthex2(counter);
      uart_puts("<-cter\n");
    }
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }

  event void Timer.fired() {
    tuple t, in_t;


    dbg(DBG_USR3, "Timer fired\n");

    // IN tuple
    resetTuple(&t, FMT_MY_IN_TUPLE);
    setUint16Field(&t, 0, OUT_NODE);
    setUint16Field(&t, 1, OUT_NODE);

    _asm("in0:");
    out_id = call TS.in(FALSE, TL_LOCAL, &in_t);
    _asm("in1:");

  }

}



