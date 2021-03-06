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
  event void Boot.booted() {
    call TSControl.start();
    call Timer.startPeriodic(BOOT);
  }

  event result_t TS.tupleReady(TLOpId_t *operationId, Tuple *tuples[], uint8_t number) {
    volatile int counter = 0;
    dbg(DBG_USR3, "tupleReady %hhu\n", number);
    counter++;
    return SUCCESS;
  }


  task void newTupleTask() {
    volatile int c = 0;
    // Declare a tuple variable
    declareTuple(t, TUPLE_3_FMT);

    // Instead of implementing one single newTuple function for all formats,
    // specialized newTuple functions are generated by the preprocessor.
    // This allows static type checking, and
    // avoids variable parameter lists like (...) , which are much slower (about 10 times slower)
    c++;
    _asm("newTuple0:");
    newTuple_TUPLE_3_FMT(t, 222, 333, 111);
    _asm("newTuple1:");
    c++;
    // Make another call, to make sure that the previous is not inlined
    newTuple_TUPLE_3_FMT(t, 222, 333, 111);
  }

  event void Timer.fired() {
    post newTupleTask();
  }


  event result_t TS.reifyCapabilityTuple(Tuple* ct) {
    return SUCCESS;
  }

}
