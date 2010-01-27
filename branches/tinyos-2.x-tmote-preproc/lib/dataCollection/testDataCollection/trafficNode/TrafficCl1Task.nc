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
 * *	$Id: TrafficCl1Task.nc 848 2009-05-21 07:47:27Z dfacchin $
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
#include "CollectionInfo.h"
#include "TupleSpace.h"

/**
 * The component in charge of parsing task tuples, and to generate class 2 
 * traffic.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */
  
#define SLOW_START_QUANTUM 25
#define REBUILD_TREE_TIME 30000

module TrafficCl1Task {

  uses {
    interface Boot;
    interface TupleSpace as TS;
    interface Timer<TMilli> as ReportPeriod;
    interface Timer<TMilli> as SessionPeriod;
    interface Timer<TMilli> as TimerSearchTask;
    interface Leds;
    interface CollectionInfo;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  enum {
    INACTIVE,
    REPORTING
  };
  uint8_t state = INACTIVE;

  bool fw_active = FALSE;

  nx_struct opaqueTuple {
    nx_uint8_t type;
    nx_uint16_t address;
    nx_uint16_t seqNum;
  };

  TLOpId_t inId;

  uint16_t min_report_interval;

  uint16_t currentTick, burst_msgs, period, numSessions;

  // Information used to adapt the sending rate
  uint32_t startReporting;
  uint16_t sentMsgs;  
  uint8_t slowStartState;

  // The timings are tuned to so that 
  uint16_t evaluateReportRate() {

    static uint16_t previousReportRate;
    uint32_t reportRate, reportingTime = 0;
    uint16_t remainingMsgs = 0;

    // Just (re)started
    if (slowStartState == 0) {
      // Msgs still to be sent for this session
      reportingTime = ((uint32_t)period*MINUTE) - REBUILD_TREE_TIME;
      atomic {
        remainingMsgs = burst_msgs - sentMsgs;
        if (call SessionPeriod.getNow() >= startReporting){
          reportRate = (reportingTime -
                         (call SessionPeriod.getNow()
                          - startReporting)) /
            remainingMsgs;
        } else {
           reportRate = (reportingTime -
                         (call SessionPeriod.getNow() 
                          + 0xFFFFFFFF - startReporting)) /
            remainingMsgs;
        }
      }
    } else {
      // Trying to speed up
      reportRate = previousReportRate;
    }
 
    if (reportRate > min_report_interval) {
      // Can still push
      slowStartState++;
      if (reportRate > slowStartState*SLOW_START_QUANTUM) {
        reportRate = reportRate - slowStartState*SLOW_START_QUANTUM;
      } else {
        reportRate = min_report_interval;
      }
      if (reportRate > MAX_CLASS_1_REPORT_INTERVAL){
        reportRate = MAX_CLASS_1_REPORT_INTERVAL;
      }

      previousReportRate = reportRate;
#ifdef PRINTF_SUPPORT
      printf("p%um%ut%lu\n",slowStartState,
      	     remainingMsgs, reportRate);
      /* call PrintfFlush.flush(); */
#endif
      return reportRate;
    } else {
      // Reached max speed
      previousReportRate = min_report_interval;
#ifdef PRINTF_SUPPORT
      printf("s%um%ut%lu\n",slowStartState,
      	     remainingMsgs, reportRate);
      /* call PrintfFlush.flush(); */
#endif
      return min_report_interval;
    }
  }

  event void Boot.booted() {
    call TimerSearchTask.startPeriodic(5000);
    slowStartState = 0;
    min_report_interval = MIN_CLASS_1_REPORT_INTERVAL;
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTask(tuple<uint8_t, uint8_t, uint16_t, 
                 uint16_t, uint16_t, uint16_t, uint16_t> *taskTuple) {
    if (call SessionPeriod.isRunning()) {
      call SessionPeriod.stop();
    }
    if (TL_LOCAL % taskTuple->value6 == 0){
      currentTick = 0;
      burst_msgs = taskTuple->value2;
      period = taskTuple->value3;
      numSessions = taskTuple->value4;
      min_report_interval = taskTuple->value5;
      call SessionPeriod.startPeriodic((uint32_t)MINUTE);
    }      
#ifdef PRINTF_SUPPORT
    printf ("CL1B%uP%uS%uM%uC%u\n", burst_msgs, period, 
            numSessions, min_report_interval, taskTuple->value6);
    call PrintfFlush.flush();
#endif   

  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator){
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, 
      uint16_t> *rcv;

    PROCESS_OP(inId,
               rcv = (tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t,
                      uint16_t, uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (rcv != NULL) {
                 startTask(rcv);
                 call TS.nextTuple(operationId, iterator);
               });
  }

  event void SessionPeriod.fired() {
    uint8_t currentState;
    atomic currentState = state;
    if (currentTick % period == 0 && currentState == INACTIVE) { 
      atomic{
        sentMsgs = 0;
        state = REPORTING;
        startReporting = call SessionPeriod.getNow();
        call Leds.led2On();
        call Leds.led1Toggle();
        if (fw_active)
          call ReportPeriod.startOneShot(evaluateReportRate());
      }
    } if (currentTick % period == 0 && currentState != INACTIVE) { 
      startReporting = call SessionPeriod.getNow();
    }
    currentTick++;
    if (currentTick == (numSessions*period) 
        && numSessions != INFINITE_OP_TIME) {
      call SessionPeriod.stop();
    }
  }

  event void ReportPeriod.fired() {
    tuple<uint8_t, uint16_t, uint16_t, 
      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> class1msg;
    nx_struct opaqueTuple* ot;
    TLOpId_t outId;
    static uint16_t msgSeqNum = 0;

    class1msg = newTuple(
                         actualField(MSG_TYPE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());    
    ot = (nx_struct opaqueTuple*) class1msg.value3;      
    
    sentMsgs++;
    if (sentMsgs == burst_msgs){
      ot->type = CLASS_1_END_SESSION;
    } else {
      ot->type = CLASS_1_TYPE;
    }    
    ot->address = TOS_NODE_ID;
    ot->seqNum = msgSeqNum++;
    call Leds.led1Toggle();
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &class1msg);

    if (sentMsgs != burst_msgs){
      if (fw_active) {
        call ReportPeriod.startOneShot(evaluateReportRate()); 
      }
    } else {
      call Leds.led1Off();
      call Leds.led2Off();      
      atomic state = INACTIVE;
    }
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
    uint8_t currentState;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>
      taskPattern;
    atomic currentState = state;
    if (currentState == INACTIVE){
      taskPattern = newTuple(
                             actualField(TASK_TYPE),
                             actualField(CLASS_1_TASK),
                             dontCare(),
                             dontCare(),
                             dontCare(),
                             dontCare(),
                             dontCare());
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
    }
  }
  
  event void TimerSearchTask.fired(){
    post searchNewTasks();
  }

  event void CollectionInfo.forwardingStatus(uint8_t status) {
    switch (status) {
    case FORWARDING_ACTIVE:
      atomic {
        if (!fw_active) {
          fw_active = TRUE;
          if (state == REPORTING && !call ReportPeriod.isRunning()) {
            call ReportPeriod.startOneShot(evaluateReportRate());
          }
        }
      }
      break;
    case FORWARDING_INACTIVE:
      atomic{ 
        if (fw_active) {
          slowStartState = 0;
          fw_active = FALSE;
#ifdef PRINTF_SUPPORT
          printf ("FI!\n");
          call PrintfFlush.flush();
#endif 
          if (call ReportPeriod.isRunning()) {
            call ReportPeriod.stop();
          }
        }    
      }  
      break;
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

