/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 955 $
 * * DATE
 * *    $LastChangedDate: 2009-11-28 16:07:05 -0600 (Sat, 28 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Killer.nc 955 2009-11-28 22:07:05Z mceriotti $
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

module Killer {

  uses {
    interface Boot;
    interface TupleSpace as TS;
    interface Timer<TMilli> as TimerSearchTask;
    interface Timer<TMilli> as TimerKR;
    interface Leds;
    interface Tuning;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId;
  bool killing;
  uint16_t reborn_timeout, killing_timeout;
  uint16_t counter_ticks;

  event void Boot.booted() {
    call TimerSearchTask.startPeriodic(5000);
    killing = FALSE;
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void tune(tuple<uint8_t, uint8_t, uint16_t, uint16_t,
            uint16_t, uint16_t, uint16_t> *taskTuple) {
    if (taskTuple->value2 == TL_LOCAL || taskTuple->value3 == TL_LOCAL ||
        taskTuple->value4 == TL_LOCAL){
      killing = TRUE;
      killing_timeout = taskTuple->value5;
      reborn_timeout = taskTuple->value6;
      counter_ticks = 0;
      call TimerKR.startPeriodic(MINUTE);
    }
#ifdef PRINTF_SUPPORT
    printf ("KILL%u,%u,%uK%uR%u\n", taskTuple->value2, taskTuple->value3,
            taskTuple->value4, taskTuple->value5, taskTuple->value6);
    call PrintfFlush.flush();
#endif   

  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator){
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>
      *rcv;

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
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, 
      uint16_t> taskPattern;
    taskPattern = newTuple(
                           actualField(TASK_TYPE),
                           actualField(KILLING_TASK),
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

  task void radioOn(){
    if (SUCCESS != call Tuning.set(KEY_RADIO_CONTROL, RADIO_ON))
      post radioOn();
  }

  task void radioOff(){
    if (SUCCESS != call Tuning.set(KEY_RADIO_CONTROL, RADIO_OFF))
      post radioOff();
  }

  event void TimerKR.fired(){
    if (killing){
      counter_ticks++;
      if (counter_ticks >= killing_timeout){
        killing = FALSE;
        call TimerKR.stop();
        post radioOff();
      }
    } else {
      counter_ticks++;
      if (counter_ticks >= reborn_timeout){
        call TimerKR.stop();
        post radioOn();
      }
    }
  }

  event void Tuning.setDone(uint8_t key, uint16_t value){
    if (key == KEY_RADIO_CONTROL && value == RADIO_OFF){
      counter_ticks = 0;
      call TimerKR.startPeriodic(REAL_MINUTE);
    }
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

