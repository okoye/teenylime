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


/**
 * A node with a reactive behavior (triggers reactions).
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

#define TIMER 1024
#define BOOT 1024

module TestNewTuple {

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
  int counter = 0;
  tuple neighborTuple;
  tuple template;
  TLOpId_t reaction;


  tuple t;
  event void Boot.booted() {
    volatile field f,g;
    volatile int j = 9;

    _asm("copyField0:");
    f.type = 1;
    f.value.int16 = 2;
    _asm("copyField1:");
    j++;

    g = f;

    j++;



    mydbg(DBG_ERROR, "ERROR: Message NOT sent\n");
    call TSControl.start();
    neighborTuple = newTuple(2,
           actualField_uint16(call AMPacket.address()),
           actualField_uint16(REACTIVE_NODE));

    uart_puts("Reactive node!\n");

        template = newTuple(2, actualField_uint16(REACTIVE_NODE), formalField(TYPE_UINT16_T));

    call Timer.startPeriodic(BOOT);
  }

//  command result_t StdControl.start() {
//    uart_puts("Starting reactive node!\n");
//    PeriodicTimer.startOneShot(BOOT);
//  }
//
//  command result_t StdControl.stop() {
//    return call PeriodicTimer.stop ();
//  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, tuple *tuples, uint8_t number) {
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    _asm("tupleready0:");
    if (number == 100) {
      uart_puts("tr\n");
    }
    if (number != 0) {
      _asm("tupleready1:");
      counter++;
    }
//    uart_puts("tr");
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }


  task void newTupleTask() {
    volatile int l=0;
    volatile field f1;
    volatile tuple r;

    _asm("newTuple0:");
    fastNewTuple(&t, 3,
           fastActualField_uint16(222),
           fastActualField_uint16(66),
           fastActualField_uint16(44));
    _asm("newTuple1:");
    if (t.fields[0].value.int16 != 222) {
      exit(0);
    }
    l++;
    _asm("newField0:");
    f1 = actualField_uint16(222);
    _asm("newField1:");
    l++;
    _asm("copyTuple0:");
    r = t;
    _asm("copyTuple1:");

//    _asm("newTuple0:");
    t = newTuple(3,
           actualField_uint16(222),
           actualField_uint16(66),
           actualField_uint16(44));
//    _asm("newTuple1:");
  }

  event void Timer.fired() {
    post newTupleTask();
  }
}
