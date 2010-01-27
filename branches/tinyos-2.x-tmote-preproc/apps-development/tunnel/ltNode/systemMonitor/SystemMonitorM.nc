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
#include "CollectionInfo.h"
#include "CollectionTuning.h"
#include "TupleSpace.h"
#include "Msp430Adc12.h"

#define DEFAULT_GW 0
#define BATTERY_THRESHOLD 0

/**
 * The component in charge of providing monitoring information on a
 * LT node status.
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

    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadVoltage;

    interface Timer<TMilli> as MonitorPeriod;

    interface StdControl as SamplingControl;

    interface CollectionInfo;
    interface CollectionTuning;
    interface CollectionDebug;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
  provides interface SystemMonitorCtrl;
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfTemp;
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfVolt;
}

implementation {

  TLOpId_t inTkId, inNotId, reactionId;

  uint8_t minuteTick = 0;
  uint16_t voltage = 0;
  uint16_t temperature = 0;
  uint16_t monitorPeriod,monitorMinute,rebootCounter;
  bool runSystemMonitor = TRUE;
  bool fakeError = FALSE;
  uint8_t nodecount = 0;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
    tMonitor;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tNotify;
  uint16_t msgSeqNum = 0;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> token;
  bool tkReactActive, alarmToSend;

  nx_struct opaqueTupleAggSysInfo {
    nx_uint16_t info_type_id; //2
    nx_uint16_t target_gw_id; //4
    nx_uint16_t node_id; //6
    nx_uint16_t seq_num; //8
    nx_uint16_t info_id; //10
    nx_uint16_t parent;  //12
    nx_uint16_t parent_quality; //14
    nx_uint16_t voltage; //16
    nx_uint16_t temperature;  //18
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
    TLOpId_t outId;
    nx_struct opaqueTupleSysInfo* ot;

    // Powering up temperature sensor
    TOSH_MAKE_HUM_PWR_OUTPUT();
    TOSH_SET_HUM_PWR_PIN();

    token = newTuple(
                     actualField(MSG_TYPE),
                     dontCare(),
                     actualField(TOKEN),
                     dontCare());

    tkReactActive = FALSE;
    fakeError = FALSE;
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &token);  

    monitorMinute = MINUTE;
    monitorPeriod = MONITOR_PERIOD;

    call MonitorPeriod.startPeriodic(monitorMinute/NODES);

    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());
    
    oat = (nx_struct opaqueTupleAggSysInfo*) tMonitor.value3;
    
    oat->info_type_id = INFO_TYPE_IDENTIFIER;
    oat->info_id = AGGREGATED_PERIODIC_INFO;
    oat->target_gw_id = DEFAULT_GW;
    oat->node_id = call AMPacket.address();
    oat->seq_num = msgSeqNum;
    oat->parent = call CollectionInfo.currentParent();
    oat->parent_quality = call CollectionInfo.parentLQI();
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

    alarmToSend = TRUE;
    tNotify = newTuple(
                       actualField(QUEUE),
                       actualField(TL_LOCAL),
                       actualField(RELIABLE_DELIVERY),
                       arrayField());
    
    ot = (nx_struct opaqueTupleSysInfo*) tNotify.value3;
    ot->info_type_id = INFO_TYPE_IDENTIFIER;
    ot->target_gw_id = DEFAULT_GW;
    ot->node_id = call AMPacket.address();
    ot->seq_num = msgSeqNum++;
    ot->info_id = NODE_STATUS;
    ot->value = REBOOT;
    
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tNotify);
    call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  command void SystemMonitorCtrl.runSystemMonitor(bool run, uint16_t nodeLimit,uint16_t xPeriod, uint16_t xMinute){
    runSystemMonitor = run;
    nodecount = 0;
    if (TL_LOCAL > nodeLimit)
      runSystemMonitor =  FALSE;
    // Keep it running so I can use it to reset the node like an error-batt
    //if (call MonitorPeriod.isRunning())
      //call MonitorPeriod.stop();
    if ((xPeriod==0)||(xMinute==0)){
      monitorMinute = MINUTE;
      monitorPeriod = MONITOR_PERIOD;
    } else {
      monitorMinute = xMinute;
      monitorPeriod = xPeriod;
    }
    if (runSystemMonitor)
      call MonitorPeriod.startPeriodic(monitorMinute/NODES);
  }

  command void SystemMonitorCtrl.sendFakeError(bool val){
    // WITH AN BATT ERROR, the NODE REBOOTS IN 10 sysMINUTES
    if (val){
      fakeError = TRUE;
      rebootCounter = 0;
    }
  }

  command void SystemMonitorCtrl.test(){
    call Leds.led2On();
  }

  const msp430adc12_channel_config_t configTemperature = {
      inch: INPUT_CHANNEL_A6,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* AdcConfTemp.
  getConfiguration() {
    return &configTemperature;
  }

  const msp430adc12_channel_config_t configVoltage = {
      inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* AdcConfVolt.
  getConfiguration() {
    return &configVoltage;
  }


  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    TLOpId_t opId;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
      *tokenTuple;

    PROCESS_OP(reactionId,
               tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
               call TS.nextTuple(operationId,iterator);
               if (tkReactActive){
                 tkReactActive = FALSE;
                 call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, 
                            (tuple *) &token);
               });

    PROCESS_OP(inTkId,
               tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
               call TS.nextTuple(operationId,iterator); 
               if (tokenTuple != NULL) {
                 call TS.nextTuple(operationId,iterator);
                 if (tMonitor.value0 == QUEUE){
                   tMonitor.value0 = MSG_TYPE;
                   call TS.out(&opId, FALSE, TL_LOCAL, RAM_TS, 
                               (tuple *) &tMonitor);
                   if (alarmToSend)
                     tkReactActive = TRUE;
                 } else {
                   tNotify = newTuple(
                                      actualField(QUEUE),
                                      actualField(TL_LOCAL),
                                      actualField(RELIABLE_DELIVERY),
                                      dontCare());
                   call TS.ing(&inNotId, FALSE, TL_LOCAL, RAM_TS, 
                              (tuple *) &tNotify);
                 }
               } else {
                 tkReactActive = TRUE;
               });

    PROCESS_OP(inNotId,
               tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
               call TS.nextTuple(operationId,iterator);
               if (tokenTuple != NULL) {
                 tokenTuple->value0 = MSG_TYPE;
                 call TS.out(&opId, FALSE, TL_LOCAL, RAM_TS, 
                             (tuple *) tokenTuple);
                 tokenTuple = (tuple<uint8_t, uint16_t, uint16_t,
                               uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *)
                 call TS.nextTuple(operationId,iterator);
               }
               if (tokenTuple == NULL)
                 alarmToSend = FALSE;
               else
                 tkReactActive = TRUE;
               );
  }

  event void MonitorPeriod.fired() {
  nodecount++;
  if (nodecount==TL_LOCAL%NODES){
    nodecount++;
    if (runSystemMonitor){
      minuteTick++;
      if (minuteTick % monitorPeriod == 0) {      
        call ReadTemperature.read();
      }
    } else if(fakeError){
      if (rebootCounter==10){
        atomic{
          WDTCTL = WDT_ARST_1_9;
            while(1);
        }
      }
        ;//REBOOT
      if (rebootCounter%2==0)
        call Leds.set(7);
      else
        call Leds.set(0);
      rebootCounter++;
    }
  }
  if (nodecount == NODES)
      nodecount = 0;
  }

  event void ReadTemperature.readDone(error_t result, uint16_t val){
    if (result == SUCCESS)
      temperature = val;
    else
      temperature = 0;
    call ReadVoltage.read();
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {

    TLOpId_t outId;

    nx_struct opaqueTupleSysInfo* ot;

    tMonitor = newTuple(
                        actualField(QUEUE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());
    
    oat->info_type_id = INFO_TYPE_IDENTIFIER;
    oat->info_id = AGGREGATED_PERIODIC_INFO;
    oat->target_gw_id = DEFAULT_GW;
    oat->node_id = call AMPacket.address();
    oat->seq_num = msgSeqNum;
    oat->parent = call CollectionInfo.currentParent();
    oat->parent_quality = call CollectionInfo.parentLQI();
    if (result == SUCCESS)
      oat->voltage = val;
    else
      oat->voltage = 0;
    oat->temperature = temperature;
    oat->total_send = call CollectionDebug.getTotalSend();
    oat->total_retxmit = call CollectionDebug.getTotalRetxmit();
    
    if (!tkReactActive){
      call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token); 
    }   

    msgSeqNum += 4;
#ifdef PRINTF_SUPPORT
    printf ("I %u %u %u %u \n", oat->parent, oat->parent_quality,
            oat->voltage, oat->temperature);
    call PrintfFlush.flush();
#endif 

    if ((result == SUCCESS && val < BATTERY_THRESHOLD)||(fakeError)){
      // BATTERY LEVEL CRITICAL 
      alarmToSend = TRUE;
      tNotify = newTuple(
                         actualField(QUEUE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
      
      ot = (nx_struct opaqueTupleSysInfo*) tNotify.value3;
      ot->info_type_id = INFO_TYPE_IDENTIFIER;
      ot->target_gw_id = DEFAULT_GW;
      ot->node_id = call AMPacket.address();
      ot->seq_num = msgSeqNum++;
      ot->info_id = NODE_STATUS;
      ot->value = CRITICAL_BATTERY;

      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tNotify);

      if (!tkReactActive)
        call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token);

      call CollectionTuning.setImmediate(KEY_FORWARDER_NODE, LEAF);

      call SamplingControl.stop();
      //I USE THE TIMER TO REBOOT THE NODE
      runSystemMonitor = FALSE;
      //call MonitorPeriod.stop();
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

  event void CollectionDebug.parentUpdated(uint16_t gateway, 
                                           uint16_t parent, 
                                           uint16_t cost){
    if (oat->gateway != gateway)
      oat->gateway_changes++;
    oat->gateway = gateway;
    if (oat->parent != parent)
      oat->parent_changes++;
    oat->parent_cost = cost;
  }

  event void CollectionDebug.packetForwarded(uint8_t traffic_class, 
                                             uint8_t retries,
                                             uint16_t child){
    oat->packets_forwarded[traffic_class]++;
    oat->out_retries += retries;
  }

  event void CollectionDebug.transmissionFailed(uint8_t traffic_class,
                                                uint8_t retries,
                                                uint16_t child){
    oat->retries[traffic_class]++;
    oat->out_retries += retries;
  }

  event void CollectionDebug.treeCongested(bool root){
    if (root){
      oat->root_congestions++;
    } else {
      oat->subtree_congestions++;
    }
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

