/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:08:41 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SystemMonitorM.nc 885 2009-07-15 16:08:41Z mceriotti $
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

// The sampling period in ms
#define DEFAULT_SENSE_PERIOD 3000
// Samples in a stint
#define DEFAULT_STINT_SAMPLES 10
// LPL
#define DEFAULT_LPL REMOTE_LPL_INTERVAL
// OMEGA
#define DEFAULT_OMEGA 0
// ALPHA
#define DEFAULT_ALPHA 0

/**
 * The component in charge of providing monitoring information on a
 * sink node status.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module SystemMonitorM {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as ReadVoltage;

    interface Timer<TMilli> as MonitorPeriod;

    interface Tuning as TLTuning;

    interface GlobalTime;

    interface AMPacket;
    interface Leds;

    interface CollectionTuning;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId;

  uint8_t minuteTick = 0;
  uint16_t voltage = 0;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tMonitor;
  uint16_t msgSeqNum = 0;

  nx_struct opaqueTupleAggSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t voltage;
    nx_uint16_t temperature;
    nx_uint16_t parent;
    nx_uint16_t parent_quality;
  };

  nx_struct opaqueTupleSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t value;
  };

  event void Boot.booted() {
    nx_struct opaqueTupleSysInfo* ot;
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

    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskTuple);

    call GlobalTime.startTimer();
    call MonitorPeriod.startPeriodic(MINUTE);

    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());
    
    ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3;
    ot->info_type_id = INFO_TYPE_IDENTIFIER;
    ot->target_gw_id = call AMPacket.address();
    ot->node_id = call AMPacket.address();
    ot->seq_num = msgSeqNum++;
    ot->info_id = NODE_STATUS;
    ot->value = REBOOT | SINK_NODE;

    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  void startTask(tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, 
		   uint16_t, uint16_t> *taskTuple) {
    
    call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, 0);
    call TLTuning.setImmediate(KEY_REMOTE_LPL_SLEEP, taskTuple->value6);
    call TLTuning.setImmediate(KEY_REMOTE_OP_TIMEOUT, taskTuple->value6 + 50);
  }

  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t> 
      *taskTuple;
    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, uint16_t, uint16_t,
                            uint16_t, uint16_t, uint16_t> *) 
               call TS.nextTuple(operationId,iterator); 
               if (taskTuple != NULL) {
                 startTask(taskTuple);
                 call TS.nextTuple(operationId,iterator);
               });
  }

  event void MonitorPeriod.fired() {
    TLOpId_t outId;
    nx_struct opaqueTupleSysInfo* ot;

    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0) {      
/*       call ReadVoltage.read(); */

      tMonitor = newTuple(
                          actualField(MSG_TYPE),
                          actualField(TL_LOCAL),
                          actualField(RELIABLE_DELIVERY),
                          arrayField());
      ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3;
      ot->info_type_id = INFO_TYPE_IDENTIFIER;
      ot->target_gw_id = call AMPacket.address();
      ot->node_id = call AMPacket.address();
      ot->seq_num = msgSeqNum++;
      ot->info_id = ROUTING_PARENT;
      ot->value = call AMPacket.address();
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);
    }
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {

/*     TLOpId_t outId; */
/*     nx_struct opaqueTupleSysInfo* ot; */

/*     tMonitor = newTuple( */
/*                         actualField(MSG_TYPE), */
/*                         actualField(TL_LOCAL), */
/*                         actualField(RELIABLE_DELIVERY), */
/*                         arrayField()); */
    
/*     ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3; */
/*     ot->info_type_id = INFO_TYPE_IDENTIFIER; */
/*     ot->target_gw_id = call AMPacket.address(); */
/*     ot->node_id = call AMPacket.address(); */
/*     ot->seq_num = msgSeqNum++; */
/*     ot->info_id = BATTERY; */
/*     ot->value = val; */
/*     call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor); */
  }

  task void searchNewTasks() {
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t>
      taskPattern;
    taskPattern = newTuple(
			   actualField(TASK_TYPE),
			   actualField(TUNING),
         dontCare(),
         dontCare(),
			   dontCare(),
			   dontCare(),
			   dontCare());
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskPattern);
  }
  
  async event void GlobalTime.timeEvent(){
    post searchNewTasks();
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

  event void TLTuning.setDone(uint8_t key, uint16_t value) {}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 
}

