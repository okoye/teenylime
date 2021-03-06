/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 848 $
 * * DATE
 * *    $LastChangedDate: 2009-05-21 02:47:27 -0500 (Thu, 21 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: dfacchin $
 * *
 * *	$Id: FakeDataDissemination.nc 848 2009-05-21 07:47:27Z dfacchin $
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
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

#define CLASS_1_BURST_MSGS 100
#define CLASS_1_PERIOD 900
#define CLASS_1_NUM_SESSIONS INFINITE_OP_TIME

#define CLASS_2_PERIOD 60
#define CLASS_2_NUM_SAMPLES INFINITE_OP_TIME

#define CLASS_RATIO 4

module FakeDataDissemination {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface TLObjects;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple<uint16_t, lqi, uint16_t>  neighborTuple;

  event void Boot.booted() {

    TLOpId_t outId;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t> taskTuple;
    neighborTuple = newTuple(
                             actualField(call AMPacket.address()),
                             lqiRead(),
                             actualField(0));
    taskTuple = newTuple(
                         actualField(TASK_TYPE),
                         actualField(CLASS_1_TASK),
                         actualField(CLASS_1_BURST_MSGS),
                         actualField(CLASS_1_PERIOD),
                         actualField(CLASS_1_NUM_SESSIONS),
                         actualField(CLASS_RATIO));
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskTuple);
    taskTuple = newTuple(
                         actualField(TASK_TYPE),
                         actualField(CLASS_2_TASK),
                         actualField(0),
                         actualField(CLASS_2_PERIOD),
                         actualField(CLASS_2_NUM_SAMPLES),
                         actualField(CLASS_RATIO));
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskTuple);
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return (tuple *) &neighborTuple;
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
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

