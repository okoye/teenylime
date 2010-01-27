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
#define NR_MALLOCS 10
#define MALLOC_SIZE 10
//#define TIN

volatile uint16_t counter = 0;

module TestMalloc {

  uses {
    interface Timer<TMilli> as Timer;
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface Boot;
    interface AMPacket;
    interface StdControl as TSControl;
    interface Leds;
    interface TinyMalloc as Mem;
  }
}



implementation {

//  tuple template;
//  TLOpId_t reactions[NR_REACTS];
  TLOpId_t out_id;

  event void Boot.booted() {
    declareTuple(t, TUPLE_3_FMT);
    declareQuery(q, 0);
    int i,k; void *m; volatile int j = 0;
    void *p[NR_MALLOCS*2];
    dbg(DBG_USR3, "Test malloc() and free() execution time.\n");

    resetTuple(t, TUPLE_3_FMT);
    setQueryFormat(q, TUPLE_3_FMT);
    call TSControl.start();

    _asm("malloc0:");
    m = call Mem.malloc(MALLOC_SIZE+1);
    _asm("malloc1:");
    j++;
    _asm("free0:");
    call Mem.free(m, MALLOC_SIZE+1);
    _asm("free1:");
    j++;
    _asm("out0:");
    call TS.out(FALSE, TL_LOCAL, t);
    _asm("out1:");
    j++;
    _asm("in0:");
    call TS.in(FALSE, TL_LOCAL, q);
    _asm("in1:");

    for (i = 0; i < NR_MALLOCS; i++) {
      for (k = 0; k < i+2; k++) {
        p[k] = call Mem.malloc(MALLOC_SIZE);
      }
      for (k = 0; k < i+1; k++) {
        call Mem.free(p[k],MALLOC_SIZE);
      }

      _asm("malloc2:");
      m = call Mem.malloc(MALLOC_SIZE+1);
      _asm("malloc3:");
      j++;
      _asm("free2:");
      call Mem.free(m, MALLOC_SIZE+1);
      _asm("free3:");

      j++;
      _asm("out2:");
      call TS.out(FALSE, TL_LOCAL, t);
      _asm("out3:");
      j++;
      _asm("in2:");
      call TS.in(FALSE, TL_LOCAL, q);
      _asm("in3:");
    }
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
  }

}



