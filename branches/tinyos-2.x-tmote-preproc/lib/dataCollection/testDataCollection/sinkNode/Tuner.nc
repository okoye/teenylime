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
 * *	$Id: Tuner.nc 848 2009-05-21 07:47:27Z dfacchin $
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
#include "Configuration.h"
#include "TupleSpace.h"
#include "CollectionTuning.h"

/**
 * The component in charge of tuning the parameters for the tests.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module Tuner {

  uses {
    interface Boot;
    interface TupleSpace as TS;
    interface Timer<TMilli> as TimerSearchTask;
    interface Leds;
    interface Tuning;
    interface CollectionTuning;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId;

  event void Boot.booted() {
    call TimerSearchTask.startPeriodic(5000);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void tune(tuple<uint8_t, uint8_t, uint16_t, uint16_t,
            uint16_t, uint16_t, uint16_t> *taskTuple) {
    call Tuning.setImmediate(KEY_REMOTE_LPL_SLEEP, taskTuple->value2);
    call Tuning.setImmediate(KEY_REMOTE_OP_TIMEOUT, taskTuple->value2 + 50);
    call CollectionTuning.setImmediate(KEY_RECOVERY_RETRIES, taskTuple->value4);
    call CollectionTuning.setImmediate(KEY_REBUILDING_FREQUENCY, 
                                       taskTuple->value6);
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator){
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, 
      uint16_t> *rcv;

    PROCESS_OP(inId,
               rcv = (tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t,
                      uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (rcv != NULL) {
                 tune(rcv);
                 call TS.nextTuple(operationId, iterator);
               });
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }
  
  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

  task void searchNewTasks() {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>
      taskPattern;
    taskPattern = newTuple(
                           actualField(TASK_TYPE),
                           actualField(TUNING_TASK),
                           dontCare(),
                           dontCare(),
                           dontCare(),
                           dontCare(),
                           dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }
  
  event void TimerSearchTask.fired(){
    post searchNewTasks();
  }

  event void Tuning.setDone(uint8_t key, uint16_t value){}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }
  
  event void PrintfControl.stopDone(error_t error) {
  }
  
  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 

}

