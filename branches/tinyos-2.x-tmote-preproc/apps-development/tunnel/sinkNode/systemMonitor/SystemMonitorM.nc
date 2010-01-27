/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1017 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:32:29 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SystemMonitorM.nc 1017 2010-01-11 08:32:29Z mceriotti $
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
    interface CollectionDebug;

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
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tAggMonitor;
  uint16_t msgSeqNum = 0;

  nx_struct opaqueTupleAggSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t parent;
    nx_uint16_t parent_quality;
    nx_uint16_t voltage;
    nx_uint16_t temperature;
    nx_uint16_t gateway; //20
    nx_uint16_t gateway_changes; //22
    nx_uint16_t parent_cost; //24
    nx_uint16_t parent_changes; //26
    nx_uint16_t root_congestions; //28
    nx_uint16_t subtree_congestions; //30
    nx_uint16_t msg_deleted_buffer_overflow; //32
    nx_uint16_t successful_recoveries; //34
    nx_uint16_t failed_recoveries; //36
    nx_uint16_t rd_retries; //38
    nx_uint16_t packets_forwarded[3]; //44
    nx_uint16_t retries[3]; //50
    nx_uint16_t dropped_duplicates; //52
    nx_uint16_t out_retries; //54
    nx_uint16_t total_send; //56
    nx_uint16_t total_retxmit; //58
  };

  nx_struct opaqueTupleAggSysInfo* oat;

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

    tAggMonitor = newTuple(
                           actualField(MSG_TYPE),
                           actualField(TL_LOCAL),
                           actualField(UNRELIABLE_DELIVERY),
                           arrayField());

    oat = (nx_struct opaqueTupleAggSysInfo*) tAggMonitor.value3;

    oat->info_type_id = INFO_TYPE_IDENTIFIER;
    oat->info_id = AGGREGATED_PERIODIC_INFO;
    oat->target_gw_id = call AMPacket.address();
    oat->node_id = call AMPacket.address();
    oat->seq_num = msgSeqNum;
    oat->parent = call AMPacket.address();
    oat->parent_quality = 0;
    oat->voltage = 0;
    oat->temperature = 0;
    oat->parent_changes = 0;
    oat->root_congestions = 0;
    oat->subtree_congestions = 0;
    oat->msg_deleted_buffer_overflow = 0;
    oat->successful_recoveries = 0;
    oat->failed_recoveries = 0;
    oat->rd_retries = 0;
    oat->packets_forwarded[0] = 0;
    oat->packets_forwarded[1] = 0;
    oat->packets_forwarded[2] = 0;
    oat->retries[0] = 0;
    oat->retries[1] = 0;
    oat->retries[2] = 0;
    oat->dropped_duplicates = 0;
    oat->out_retries = 0;
    oat->total_send = 0;
    oat->total_retxmit = 0;

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
/*     nx_struct opaqueTupleSysInfo* ot; */

    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0) {
/*       call ReadVoltage.read(); */

      tAggMonitor = newTuple(
                             actualField(MSG_TYPE),
                             actualField(TL_LOCAL),
                             actualField(UNRELIABLE_DELIVERY),
                             arrayField());
      
      oat->info_type_id = INFO_TYPE_IDENTIFIER;
      oat->info_id = AGGREGATED_PERIODIC_INFO;
      oat->target_gw_id = call AMPacket.address();
      oat->node_id = call AMPacket.address();
      oat->seq_num = msgSeqNum;
      oat->total_send = call CollectionDebug.getTotalSend();
      oat->total_retxmit = call CollectionDebug.getTotalRetxmit();
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tAggMonitor);

      msgSeqNum += 4;

/*       tMonitor = newTuple( */
/*                           actualField(MSG_TYPE), */
/*                           actualField(TL_LOCAL), */
/*                           actualField(RELIABLE_DELIVERY), */
/*                           arrayField()); */
/*       ot = (nx_struct opaqueTupleSysInfo*) tMonitor.value3; */
/*       ot->info_type_id = INFO_TYPE_IDENTIFIER; */
/*       ot->target_gw_id = call AMPacket.address(); */
/*       ot->node_id = call AMPacket.address(); */
/*       ot->seq_num = msgSeqNum++; */
/*       ot->info_id = ROUTING_PARENT; */
/*       ot->value = call AMPacket.address(); */
/*       call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor); */
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

  event void CollectionDebug.treeBuilt(){
    oat->parent_changes++;
  }

  event void CollectionDebug.packetReceived(uint8_t traffic_class, 
                             uint16_t child){
    oat->packets_forwarded[traffic_class]++;
  }

  event void CollectionDebug.treeCongested(){
    oat->root_congestions++;
  }

  event void CollectionDebug.bufferOverflow(uint8_t deletedMessages){
    oat->msg_deleted_buffer_overflow += deletedMessages;
  }

  event void CollectionDebug.messageRecovery(bool success, 
                                             uint8_t retries,
                                             uint16_t child){
    if (success){
      oat->successful_recoveries++;
    } else {
      oat->failed_recoveries++;
    }
    oat->rd_retries += retries;
  }

  event void CollectionDebug.droppedDuplicate(uint16_t child){
    oat->dropped_duplicates++;
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

