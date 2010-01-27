/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 232 $
 * * DATE
 * *    $LastChangedDate: 2007-12-06 08:14:46 +0100 (Thu, 06 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalOpsCompB.nc 232 2007-12-06 07:14:46Z lmottola $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * Test for local operations across different components on the same
 * node. Use with LocalOpsCompA on the same node.
 *
 * Under correct operations, the blue and green leds should blink
 * alternatively and together.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module LocalOpsCompB {

  uses {
    interface Boot;

    interface TupleSpace as TS;
    
    interface AMPacket;

    interface Leds;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t reactionId, inId, outId, rdId;

  event void Boot.booted() {
    tuple<uint16_t, uint8_t> p = newTuple(dontCare(), dontCare());
    
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 
    tuple<uint16_t, uint8_t> *rcv =
        (tuple<uint16_t, uint8_t> *) call TS.nextTuple(operationId, iterator);

    tuple<uint8_t, uint16_t> t = newTuple(
		       actualField(FAKE_DATA), 
		       actualField(FAKE_DATA));

    PROCESS_OP(reactionId,
	       if(rcv != NULL
		  && rcv->value0 == FAKE_DATA
		  && rcv->value1 == FAKE_DATA) {
		 call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv);
		 call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
		 call Leds.led2Toggle();
	       });
    call TS.nextTuple(operationId, iterator);
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,  
                   TLTupleSpace_t ts,
				   tuple* returningTuple) {
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}

