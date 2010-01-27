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
#define NR_MALLOCS 2
#define MALLOC_SIZE 10

volatile uint16_t counter = 0;

module TestMallocFree {

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

  TLOpId_t opID;

  event void Boot.booted() {
    // Declare tuple variable (pointer to)
    declareTuple(t, TUPLE_3_FMT);
    // Declare query with zero conditions (verify tuple format only)
    declareQuery(q, 0);

    int i,k; void *m; volatile int j = 0;
    void *p[NR_MALLOCS*2];
    dbg(DBG_USR3, "Test malloc() and free() execution time.\n");


    newTuple_TUPLE_3_FMT(t, 1, 1, 1);
    newQuery(q, TUPLE_3_FMT, 0);

    j++;
    asm("malloc0:");
    m = call Mem.malloc(MALLOC_SIZE);
    asm("malloc1:");
    j++;
    asm("free0:");
    call Mem.free(m, MALLOC_SIZE);
    asm("free1:");
    j++;
//    _asm("out0:");
//    call TS.out(&opID, FALSE, TL_LOCAL, t);
//    _asm("out1:");
//    j++;
//    _asm("in0:");
//    call TS.in(&opID, FALSE, TL_LOCAL, q);
//    _asm("in1:");

    for (i = 0; i < NR_MALLOCS; i++) {
      dbg3("allocate %d\n",i+2);
      for (k = 0; k < i+2; k++) {
        p[k] = call Mem.malloc(MALLOC_SIZE+4*k);
      }
      dbg3("free %d\n",i+1);
      for (k = 0; k < i+1; k++) {
        call Mem.free(p[k],MALLOC_SIZE+4*k);
      }
      dbg3("test\n");
      asm("malloc2:");
      m = call Mem.malloc(MALLOC_SIZE+4*i);
      asm("malloc3:");
      j++;
      asm("free2:");
      call Mem.free(m, MALLOC_SIZE+4*i);
      asm("free3:");

      j++;
//      _asm("out2:");
//      call TS.out(&opID, FALSE, TL_LOCAL, t);
//      _asm("out3:");
//      j++;
//      _asm("in2:");
//      call TS.in(&opID, FALSE, TL_LOCAL, q);
//      _asm("in3:");
    }
    call TSControl.start();
  }

  event result_t TS.reifyCapabilityTuple(Tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t *operationId, Tuple *tuples[], uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    counter++;
    return SUCCESS;
  }

  event void Timer.fired() {
  }

}



