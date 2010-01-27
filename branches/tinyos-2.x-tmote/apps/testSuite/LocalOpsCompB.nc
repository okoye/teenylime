/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 232 $
 * * DATE
 * *    $LastChangedDate: 2007-12-06 01:14:46 -0600 (Thu, 06 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalOpsCompB.nc 232 2007-12-06 07:14:46Z lmottola $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * Test for local operations across different components on the same node.
 *
 * Under correct operations, the blue and green leds should blink
 * alternatively.
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
    tuple p = newTuple(2, 
		       formalField(TYPE_UINT16_T), 
		       formalField(TYPE_UINT8_T));
    
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p);
    call Leds.led0Toggle();
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {


    tuple t = newTuple(2, 
		       actualField_uint8(FAKE_DATA), 
		       actualField_uint16(FAKE_DATA));

    if (opIdCmp(&operationId, &reactionId)
	&& number == 1
	&& tuples[0].fields[0].value.int16 == FAKE_DATA
	&& tuples[0].fields[1].value.int8 == FAKE_DATA) {
      
      call TS.in(&inId, FALSE, TL_LOCAL, &(tuples[0]));
      call TS.out(&outId, FALSE, TL_LOCAL, &t);
      call Leds.led2Toggle();
    }
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
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

