/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 297 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:33:24 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: FakeDataDisseminationVibr.nc 297 2008-02-26 18:33:24Z mceriotti $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "TupleSpace.h"

/**
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module FakeDataDisseminationVibr {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple neighborTuple;

  event void Boot.booted() {

    TLOpId_t outId;
    tuple taskTuple = newTuple(6,
 				   actualField_uint8(TASK_TYPE),
 				   actualField_uint8(VIBRATION_TYPE),
 				   actualField_uint16(VIBRATION_RATE),
 				   actualField_uint16(VIBRATION_SAMPLING),
 				   actualField_uint16(VIBRATION_PERIOD),
 				   actualField_uint16(VIBRATION_OP_TIME));
    neighborTuple = newTuple(3,
                             actualField_uint16(call AMPacket.address()),
                             formalField(TYPE_LQI),
                             actualField_uint16(0));
    call TS.out(&outId, FALSE, TL_LOCAL, &taskTuple);
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
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

