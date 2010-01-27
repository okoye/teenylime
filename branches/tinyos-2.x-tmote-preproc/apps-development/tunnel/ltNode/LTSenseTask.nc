/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1020 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 03:30:52 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: LTSenseTask.nc 1020 2010-01-11 09:30:52Z mceriotti $
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
#include "CollectionTuning.h"
#include "TupleSpace.h"
#include "ISL29004.h"

#define MAX_STINT_SAMPLES 10
#define LIGHT_SENSORS 4
#define DEFAULT_GW 0
#define NO_ALARM 0

// The sampling period in ms
#define DEFAULT_SENSE_PERIOD 5000
// Samples in a stint
#define DEFAULT_STINT_SAMPLES 6
// LPL
#define DEFAULT_LPL REMOTE_LPL_INTERVAL
// OMEGA
#define DEFAULT_OMEGA 0
// ALPHA
#define DEFAULT_ALPHA 50

// The maximum number of IR samples fitting one message (average and variance
// are counted separately)
#define MAX_IR_SAMPLES 26

//DEFINE ERROR RATE
#define ERR_RATE 65300


/**
 * The component in charge of parsing task tuples, and to perform the
 * task.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module LTSenseTask {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface Tuning as TLTuning;

    interface Timer<TMilli> as TSensePeriod;

    interface Leds;
    interface GlobalTime;

#ifndef FAKE_LIGHT
    interface ISL29004Control;
    interface ISL29004Read;
#endif

    interface CollectionTuning;

    interface SystemMonitorCtrl;

    interface Random;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides interface StdControl as SamplingControl;
}

implementation {

  TLOpId_t inId, inTkId, inNotId, reactionId;

  // Parameters of currently running sensing task (if any)
  uint16_t stintSamples, currentSamples, sensePeriod;
  uint16_t omega, alpha;

  uint16_t numSaturations;

  // Sensed data
  uint16_t lightSamples[LIGHT_SENSORS][MAX_STINT_SAMPLES];
  uint16_t avgSamples[MAX_STINT_SAMPLES];
  uint8_t sensorStatus[LIGHT_SENSORS];
  uint8_t lightSampleIx = 0;
  /*
  bool NodeConfig[25][18] = 
  {
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,0,1,1, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,0,1,1,0,1,1, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,0, 1,1,0,1,1,0,1,1, 1,0,0,0,0,0,0,0},
  {1,1,1,1,0,1,1,0, 1,1,0,1,1,0,1,1, 1,0,0,0,0,0,0,0},
  {1,0,1,1,0,1,1,0, 1,1,0,1,1,0,1,1, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,0, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,0,0,1,0, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,0,0,1,0,0,1,0, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,0,0, 1,0,0,1,0,0,1,0, 1,0,0,0,0,0,0,0},
  {1,1,1,0,0,1,0,0, 1,0,0,1,0,0,1,0, 1,0,0,0,0,0,0,0},
  {0,0,1,0,0,1,0,0, 1,0,0,1,0,0,1,0, 1,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,0,1, 1,1,1,1,1,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,0,0, 1,1,1,1,1,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,0,0, 0,1,1,1,1,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,0,1,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,0,0,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,0,0,0,1,1,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,1,0,1, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,1,0,0, 1,1,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1, 1,1,1,1,1,0,0,0, 1,1,0,0,0,0,0,0},
  {1,0,1,0,1,0,1,0, 1,0,1,0,1,0,1,0, 0,1,0,0,0,0,0,0},
  {1,0,0,1,0,0,1,0, 0,1,0,0,1,0,0,1, 0,0,0,0,0,0,0,0},
  {1,0,0,0,1,0,0,0, 1,0,0,0,1,0,0,0, 0,1,0,0,0,0,0,0}
  };*/
  const uint8_t NodeConfig[24][3] = 
  {{255,255,128},
   {255,251,128},
   {255,219,128},
   {254,219,128},
   {246,219,128},
   {182,219,128},
   {255,254,128},
   {255,242,128},
   {255,146,128},
   {252,146,128},
   {228,146,128},
   {36,146,128},
   {253,255,192},
   {252,255,192},
   {252,127,192},
   {255,239,192},
   {255,231,192},
   {255,199,192},
   {255,253,192},
   {255,252,192},
   {255,248,192},
   {170,170,64},
   {146,73,0},
   {136,136,64}
};
  uint8_t testSeq[8] = {6,6,3,3,3,1,1,1};
  uint8_t testSeqOff[8] = {0,6,12,15,18,21,22,23};
  uint16_t testDeltaTime = 300;//5Minutes
  uint16_t testSession;
  uint8_t testTickCounter, testTickSession;
  bool triggerUnBoard = FALSE;
  bool triggerReadFail = FALSE;
  bool reboot = TRUE;

  

  // Session handling
  norace uint8_t msgType;
  nx_struct opaqueTupleLT {
    nx_uint16_t sample_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t alarm_flag;
    nx_uint16_t average_light_value;
    nx_uint16_t variance_light_value;
    nx_uint16_t average_temp_value;
    nx_uint16_t variance_temp_value;
  };

  nx_struct opaqueTupleIR {
    nx_uint16_t sample_type_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t samples[MAX_IR_SAMPLES];
  };
  
  nx_struct opaqueTupleSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t target_gw_id;
    nx_uint16_t node_id;
    nx_uint16_t seq_num;
    nx_uint16_t info_id;
    nx_uint16_t value;
  };

  bool tkReactActive, alarmToSend;
  bool stopped_sampling = FALSE;
  uint8_t total_reading_failures = 0, total_unreliable_sensors = 0;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> token;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
    ltReading;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tNotify;  
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> 
    irReading;
  uint16_t buffer_ir[MAX_IR_SAMPLES];
  uint8_t index_ir;
  uint16_t irCount, irintSamples;
  bool booting = FALSE;

#ifdef FAKE_LIGHT
  task void fakeReadDone();
#endif

  void notifyFailure(uint16_t error);

  void nodeLimit(uint16_t nodeLimit){
    if (TL_LOCAL < nodeLimit)
      call CollectionTuning.setImmediate(KEY_FORWARDER_NODE, FORWARDER);
    else
      call CollectionTuning.setImmediate(KEY_FORWARDER_NODE, LEAF);
  }

  command error_t SamplingControl.start(){
    stopped_sampling = FALSE;
    return SUCCESS;
  }
  
  command error_t SamplingControl.stop(){
    stopped_sampling = TRUE;
    return SUCCESS;
  }

  event void Boot.booted() {

    uint8_t i;
    nx_struct opaqueTupleIR* ot;

    token = newTuple(
                     actualField(MSG_TYPE),
                     dontCare(),
                     actualField(TOKEN),
                     dontCare());
    ltReading = newTuple(
                         actualField(MSG_TYPE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
    irReading = newTuple(
                         actualField(MSG_TYPE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
    
    ot = (nx_struct opaqueTupleIR*) irReading.value3;
    ot->sample_type_id = IR_SAMPLE_TYPE_IDENTIFIER;
    ot->node_id = TL_LOCAL;
    ot->seq_num = 0;
    index_ir = 0;

    tkReactActive = FALSE;
    alarmToSend = FALSE;
    reboot = TRUE;

    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &token);  


    for (i = 0; i < LIGHT_SENSORS; i++){
      sensorStatus[i] = WORKING_SENSOR;
    }

    call GlobalTime.startTimer();
#ifndef FAKE_LIGHT
    call ISL29004Control.start(ALL_SENSORS);
#endif

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  uint16_t computeAverage(){
    uint8_t i,s, actualS;
    uint32_t sumLight, sumAvg;
    uint16_t tempAvg;
    // Computing averages
    sumAvg = 0;
    for (i = 0; i < lightSampleIx; i++) {
      sumLight = 0;
      actualS = 0;
      for (s = 0; s < LIGHT_SENSORS; s++){
        if (sensorStatus[s] == WORKING_SENSOR && lightSamples[s][i] != 0xFFFF){
          sumLight += lightSamples[s][i];
          actualS++;
        } else if (sensorStatus[s] == WORKING_SENSOR){
          numSaturations++;
        }
      }
      if (actualS > 0){
        avgSamples[i] = (uint16_t) (sumLight / (uint32_t) actualS);
        sumAvg += avgSamples[i];
      } else {
        avgSamples[i] = 0;
      }
    }

    tempAvg = (uint16_t) (sumAvg / (uint32_t) lightSampleIx);
    
/*    sumAvg = 0;
    actualS = 0;
    for (i = 0; i < lightSampleIx; i++) {
      if (tempAvg > avgSamples[i]){
        if (tempAvg - avgSamples[i] < (alpha * tempAvg / 100)){
          sumAvg += avgSamples[i];
          actualS++;
        }
      } else {
        if (avgSamples[i] - tempAvg < (alpha * tempAvg / 100)){
          sumAvg += avgSamples[i];
          actualS++;
        }
      }
    }
*/
    sumAvg = 0;
    actualS = 0;
    for (i = 0; i < lightSampleIx; i++) {
      if (tempAvg > avgSamples[i]){
        if (tempAvg - avgSamples[i] < (50 * tempAvg / 100)){
          sumAvg += avgSamples[i];
          actualS++;
        }
      } else {
        if (avgSamples[i] - tempAvg < (50 * tempAvg / 100)){
          sumAvg += avgSamples[i];
          actualS++;
        }
      }
    }

    if (actualS == 0)
      return 0;

    return (uint16_t) (sumAvg / (uint32_t) actualS);
  }

  void processData() {

    static uint16_t msgSeqNum = 0;

    nx_struct opaqueTupleLT* ot;

    if (ltReading.value0 == MSG_TYPE)
      msgSeqNum++;    

    ltReading = newTuple(
                         actualField(QUEUE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
    
    ot = (nx_struct opaqueTupleLT*) ltReading.value3;
    
    ot->sample_type_id = SAMPLE_TYPE_IDENTIFIER;
    ot->target_gw_id = DEFAULT_GW;
    ot->node_id = TL_LOCAL;
    ot->seq_num = msgSeqNum;
    ot->alarm_flag = NO_ALARM;
    ot->average_temp_value = 0;
    ot->variance_temp_value = 0;
    ot->average_light_value = 0;
    ot->variance_light_value = numSaturations;
/*
    for (s = 0; s < LIGHT_SENSORS; s++){
      squareSumLight = 0;
      for (i = 1; i < lightSampleIx && sensorStatus[s] == WORKING_SENSOR; i++) {
        if (lightSamples[s][i-1] != lightSamples[s][i])
          break;
      }
      if (i == lightSampleIx && i > 1){
        if (lightSamples[s][i] != 0xFFFF && lightSamples[s][i] != 0){
          sensorStatus[s] = UNRELIABLE_SENSOR;
          notifyFailure(UNRELIABLE_SENSOR);
        }
      }
    }
*/
    ot->average_light_value = computeAverage();

#ifdef PRINTF_SUPPORT
    printf ("%d\n", ot->average_light_value);
    call PrintfFlush.flush();
#endif   
    
    // Resetting for next stint
    currentSamples = 0;
    lightSampleIx = 0;
    
    if (!tkReactActive){
      call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token);
    }
  }

  void startLTTask(tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, 
		   uint16_t, uint16_t> *taskTuple) {
   uint16_t val[6];

/*value5:
1 = Regular LT MODE value from tasktuple
2 = Random Error All network
3 = Random Error 18 Nodes
4 = Leandro on 18 Nodes
5 = HighTemperature sampling
> = LT-Mode with defaut value
*/
/*
    taskTuple = newTuple(
                         actualField(TASK_TYPE),
                         actualField(TUNING),
                         actualField(DEFAULT_SENSE_PERIOD),
                         actualField(DEFAULT_STINT_SAMPLES),
                         actualField(DEFAULT_OMEGA),
                         actualField(DEFAULT_ALPHA),
                         actualField(DEFAULT_LPL));
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &taskTuple);
*/
    call Leds.led2On();
    // A new task description arrived
    if (call TSensePeriod.isRunning()) {
      // Cancel the previous task
      call TSensePeriod.stop();
    } 

    alpha = taskTuple->value5;  
    val[0]=taskTuple->value2;
    val[1]=taskTuple->value3;
    val[2]=taskTuple->value4;
    val[3]=taskTuple->value5;
    val[4]=taskTuple->value6;
    irintSamples = 0;

    sensorStatus[0] = WORKING_SENSOR;
    sensorStatus[1] = WORKING_SENSOR;
    sensorStatus[2] = WORKING_SENSOR;
    sensorStatus[3] = WORKING_SENSOR;

    currentSamples = 0;




    if (taskTuple->value5 == 1){
      // REGULAR TREE BUILDER 
        nodeLimit(99);
      // REGULAR SYSTEM MONITOR
        call SystemMonitorCtrl.runSystemMonitor(TRUE,99,0,0);
      // NO ERROR
        // Done with case control on Sample.fire
      // NO LEANDRO ERROR
        // Done with case control on Sample.fire
      // TASK VALUE
        val[6]=TRUE;
    }

    if (taskTuple->value5 == 2){
      // REGULAR TREE BUILDER
      nodeLimit(99);
      // REGULAR SYS MONITOR
      call SystemMonitorCtrl.runSystemMonitor(TRUE,99,0,0);
      // ERROR
        // Done with case control on Sample.fire
      // NO LEANDRO ERROR
        // Done with case control on Sample.fire
      // REGULAR TASK 
        val[6]=TRUE;
    }

    if (taskTuple->value5 == 3){
      // REGULAR SAMPLING first 18 Nodes, stop > 18 (Light,Temp,Batt)
         // Next CASE
      // LIMIT TREE BUILDER
        nodeLimit(18);
      // REGULAR SYS MONITOR 18 NODES
        call SystemMonitorCtrl.runSystemMonitor(TRUE,18,0,0);
      // ERROR      
        // Done with case control on Sample.fire
      // NO LEANDRO ERROR
      // REGULAR TASK
        val[6]=TRUE;
    }

    if (taskTuple->value5 == 4){
      // TREE BUILDER 18 NODES
      nodeLimit(18);
      // REGULAR SYS MONITOR 18 Nodes
      call SystemMonitorCtrl.runSystemMonitor(TRUE,18,0,0);
      // NO ERROR
        // Done with case control on Sample.fire
      // LEANDRO ERROR
        //fist load test session:
        testSession = taskTuple->value4;
        testTickCounter = 0;
        testTickSession = 0;
      // REGULAR TASK
        val[6]=TRUE;
    }

    if (taskTuple->value5 == 5){
      // REGULAR TREE BUILDER
      nodeLimit(99);
      // HIGH TEMPERATURE SAMPLING ALL SYS MONITOR
      call SystemMonitorCtrl.runSystemMonitor(TRUE,99,0,0);
      // NO ERROR
      // NO LEANDRO ERROR
      val[6]=TRUE;
      irintSamples = val[0]/1000;
      val[4] = taskTuple->value5;
    }

    if (taskTuple->value5 > 5){
        nodeLimit(99);    
        call SystemMonitorCtrl.runSystemMonitor(TRUE,99,0,0);
        val[6]=TRUE;
    }

    // REGULAR SAMPLING data by Task
    if (val[6]){
      currentSamples = 0;
      lightSampleIx = 0;
      // Reporting period divided by the number of samples in a stint
      sensePeriod = val[0];
      stintSamples = val[1];
      omega = val[2];
      alpha = val[3];
      numSaturations = 0;
      call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, val[4]);
      call TLTuning.setImmediate(KEY_REMOTE_LPL_SLEEP, val[4]);
      call TLTuning.setImmediate(KEY_REMOTE_OP_TIMEOUT, 2*val[4] + 50);
      call CollectionTuning.setImmediate(KEY_LPL_UNRELIABLE_PATH,
                                         val[4]);
      call CollectionTuning.setImmediate(KEY_LPL_RELIABLE_PATH,
                                         val[4]);
      irCount = 0;
      booting = TRUE;
      reboot = FALSE;
      call TSensePeriod.startOneShot(sensePeriod*stintSamples/NODES * (TL_LOCAL%NODES));
    }


#ifdef PRINTF_SUPPORT
    printf ("S%dSt%dO%dA%dL%d\n", sensePeriod, stintSamples, omega, alpha, 
            taskTuple->value6);
    call PrintfFlush.flush();
#endif   
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    TLOpId_t opId;
    tuple<uint8_t, uint8_t, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t> 
      *taskTuple;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
      *tokenTuple;
    
    PROCESS_OP(inId,
               taskTuple = (tuple<uint8_t, uint8_t, uint16_t, uint16_t,
                            uint16_t, uint16_t, uint16_t> *) 
               call TS.nextTuple(operationId,iterator); 
               if (taskTuple != NULL) {
                 startLTTask(taskTuple);
                 call TS.nextTuple(operationId,iterator);
               });

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
                 if (ltReading.value0 == QUEUE){
                   ltReading.value0 = MSG_TYPE;
                   call TS.out(&opId, FALSE, TL_LOCAL, RAM_TS, 
                               (tuple *) &ltReading);
                   if (alarmToSend || irReading.value0 == QUEUE){
                     tkReactActive = TRUE;
                   }
                 } else if (irReading.value0 == QUEUE){
                   irReading.value0 = MSG_TYPE;
                   call TS.out(&opId, FALSE, TL_LOCAL, RAM_TS, 
                               (tuple *) &irReading);
                   if (alarmToSend){
                     tkReactActive = TRUE;
                   }
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
               else{
                 tkReactActive = TRUE;
               }
               );               
  }
 


  void eventERROR(){
    //first try a BATTERY ERROR
    uint16_t Err;
    uint16_t x = call Random.rand16();

   
    Err = ERR_RATE;

    if(x > Err){
      if (x & 1){
          call SystemMonitorCtrl.sendFakeError(TRUE);//BATTERY ERROR
      }
      else{
        if (x & 2){
          //READING FAILURE
          sensorStatus[0] = READING_FAILURE;
          notifyFailure(READING_FAILURE);      
        } else {
          //UNRELIABLE SENSOR  
          sensorStatus[1] = UNRELIABLE_SENSOR;
          notifyFailure(UNRELIABLE_SENSOR);
        }
     }
   }
  }

  event void TSensePeriod.fired() {
  if (!reboot){
    if (booting){
      booting = FALSE;
      if (irintSamples > 0)
        call TSensePeriod.startPeriodic(sensePeriod/irintSamples);
      else if (stintSamples > 0)
        call TSensePeriod.startPeriodic(sensePeriod);
      return;
    }

    if (stopped_sampling)
      return;

    call Leds.led2Off();
    irCount++;

    if (alpha == 1 || alpha > 4){
      if (irintSamples >= 0 && irCount >= irintSamples){
        currentSamples++;
      }
#ifndef FAKE_LIGHT
      call ISL29004Read.read(ALL_SENSORS);
#else
      post fakeReadDone();
#endif
    }

    if (alpha == 2 || (alpha == 3 && TL_LOCAL < 19)){
      if (irintSamples >= 0 && irCount >= irintSamples){
        currentSamples++;
        atomic {
          eventERROR();
        }
      }
      //READ SENSOR
#ifndef FAKE_LIGHT
      call ISL29004Read.read(ALL_SENSORS);
#else
      post fakeReadDone();
#endif
    }

    if (alpha == 4 && TL_LOCAL < 19){
      if (irintSamples >= 0 && irCount >= irintSamples){
        currentSamples++;
        testTickCounter++;
        if(testTickCounter==(testDeltaTime/(sensePeriod/1000))){
        //if(testTickCounter>=10){
          testTickSession++;
          testTickCounter = 0;
        }
        if (testTickSession == 0){
#ifndef FAKE_LIGHT
          call ISL29004Read.read(ALL_SENSORS);    
#else
          post fakeReadDone();
#endif    
        }
        else if (testTickSession<=testSeq[testSession]){
          if
      (NodeConfig[testTickSession-1+testSeqOff[testSession]][(TL_LOCAL-1)/8] &
       ((uint8_t) (128 >> ((TL_LOCAL - 1)%8))) ){
#ifndef FAKE_LIGHT
            call ISL29004Read.read(ALL_SENSORS);  
#else
          post fakeReadDone();
#endif
          }  else ;
        }      
        else {// IF THE SESSION IS OVER THE NODE WORKS NORMALY
#ifndef FAKE_LIGHT
          call ISL29004Read.read(ALL_SENSORS);
#else
          post fakeReadDone();
#endif
        }
      } else {
#ifndef FAKE_LIGHT
        call ISL29004Read.read(ALL_SENSORS);
#else
        post fakeReadDone();
#endif
      }
    }      
  }  
  }

#ifndef FAKE_LIGHT
  event void ISL29004Read.readDone(uint8_t result, 
                                   uint16_t val1, uint16_t val2, 
                                   uint16_t val3, uint16_t val4){
#else
  task void fakeReadDone(){
    uint8_t result = 0;
    uint16_t val1 = 300;
    uint16_t val2 = 300;
    uint16_t val3 = 300;
    uint16_t val4 = 300;
#endif
    uint16_t val[4] = {val1,val2,val3,val4};
    uint8_t Sensor = 1;
    uint8_t a;

    if (irCount >= irintSamples){
      irCount = 0;
      for (a = 0;a<4;a++){
        if ((result & Sensor) == 0) {
          lightSamples[a][lightSampleIx] = val[a];
        } else if ((result & Sensor) == 1 && sensorStatus[a] == WORKING_SENSOR){
          sensorStatus[a] = READING_FAILURE;
          notifyFailure(READING_FAILURE);
        }
        Sensor = Sensor < 1;
      }
      
/*    if (triggerReadFail){
    }
*/
/*
    if ((result & SENSOR1) == 0) {
      lightSamples[0][lightSampleIx] = val1;
    } else if ((result & SENSOR1) == 1 && sensorStatus[0] == WORKING_SENSOR){
        sensorStatus[0] = READING_FAILURE;
        notifyFailure(READING_FAILURE);
    }
    if ((result & SENSOR2) == 0) {
      lightSamples[1][lightSampleIx] = val2;
    } else if ((result & SENSOR1) == 1 && sensorStatus[1] == WORKING_SENSOR){
      sensorStatus[1] = READING_FAILURE;
      notifyFailure(READING_FAILURE);
    }
    if ((result & SENSOR3) == 0) {
      lightSamples[2][lightSampleIx] = val3;
    } else if ((result & SENSOR1) == 1 && sensorStatus[2] == WORKING_SENSOR){
      sensorStatus[2] = READING_FAILURE;
      notifyFailure(READING_FAILURE);
    }
    if ((result & SENSOR4) == 0) {
      lightSamples[3][lightSampleIx] = val4;
    } else if ((result & SENSOR1) == 1 && sensorStatus[3] == WORKING_SENSOR){
      sensorStatus[3] = READING_FAILURE;
      notifyFailure(READING_FAILURE);
    }
*/
      lightSampleIx++;
      if (currentSamples >= stintSamples) {
#ifdef PRINTF_SUPPORT
        printf ("%d %d %d %d\n", val1, val2, val3, val4);
#endif
        processData();
      } else {
#ifdef PRINTF_SUPPORT
        printf ("%d %d %d %d\n", val1, val2, val3, val4);
        call PrintfFlush.flush();
#endif  
      }   
    } 
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

  event void TLTuning.setDone(uint8_t key, uint16_t value) {}

  void notifyFailure(uint16_t error){
    
    TLOpId_t outId;
    nx_struct opaqueTupleSysInfo* ot;
    static uint16_t notificationSeqNum = 0;

    if (error == UNRELIABLE_SENSOR)
      total_unreliable_sensors++;
    else if (error == READING_FAILURE)
      total_reading_failures++;
    else
      return;

    alarmToSend = TRUE;

    tNotify = newTuple(
                        actualField(QUEUE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());
    
    ot = (nx_struct opaqueTupleSysInfo*) tNotify.value3;
    ot->info_type_id = INFO_TYPE_IDENTIFIER;
    ot->target_gw_id = DEFAULT_GW;
    ot->node_id = TL_LOCAL;
    ot->seq_num = notificationSeqNum++;
    ot->info_id = SENSORS_STATUS;
    ot->value = error;

    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tNotify);

    if (total_reading_failures + total_unreliable_sensors >= 2){
      tNotify = newTuple(
                         actualField(QUEUE),
                         actualField(TL_LOCAL),
                         actualField(RELIABLE_DELIVERY),
                         arrayField());
      
      ot = (nx_struct opaqueTupleSysInfo*) tNotify.value3;
      ot->info_type_id = INFO_TYPE_IDENTIFIER;
      ot->target_gw_id = DEFAULT_GW;
      ot->node_id = TL_LOCAL;
      ot->seq_num = notificationSeqNum++;
      ot->info_id = SENSORS_STATUS;
      ot->value = UNRELIABLE_BOARD;
      
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tNotify);
      stopped_sampling = TRUE;
      call SystemMonitorCtrl.runSystemMonitor(FALSE,0,0,0);
      call SystemMonitorCtrl.sendFakeError(TRUE);
    }
    if (!tkReactActive)
      call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token);
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

