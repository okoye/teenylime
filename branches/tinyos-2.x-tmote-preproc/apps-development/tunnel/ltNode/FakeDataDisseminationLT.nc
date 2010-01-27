/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 893 $
 * * DATE
 * *    $LastChangedDate: 2009-07-24 10:53:48 -0500 (Fri, 24 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: FakeDataDisseminationLT.nc 893 2009-07-24 15:53:48Z mceriotti $
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


// The sampling period in ms
#define DEFAULT_SENSE_PERIOD 10000
// Samples in a stint
#define DEFAULT_STINT_SAMPLES 1
// LPL
#define DEFAULT_LPL REMOTE_LPL_INTERVAL
// OMEGA
#define DEFAULT_OMEGA 0
// ALPHA
#define DEFAULT_ALPHA 50

module FakeDataDisseminationLT {

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

  NeighborTuple<uint16_t, lqi, uint16_t>  neighborTuple;

  event void Boot.booted() {

    TLOpId_t outId;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t,
      uint16_t> taskTuple;
    taskTuple = newTuple(
                         actualField(TASK_TYPE),
                         actualField(TUNING),
                         actualField(DEFAULT_SENSE_PERIOD),
                         actualField(DEFAULT_STINT_SAMPLES),
                         actualField(DEFAULT_OMEGA),
                         actualField(DEFAULT_ALPHA),
                         actualField(DEFAULT_LPL));
    neighborTuple = newTuple(
                             actualField(call AMPacket.address()),
                             lqiRead(),
                             actualField(0));
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

