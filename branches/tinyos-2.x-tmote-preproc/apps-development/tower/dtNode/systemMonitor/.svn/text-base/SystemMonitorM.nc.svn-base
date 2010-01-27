/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 893 $
 * * DATE
 * *    $LastChangedDate: 2009-07-24 17:53:48 +0200 (ven, 24 lug 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SystemMonitorM.nc 893 2009-07-24 15:53:48Z mceriotti $
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

    interface Read<uint16_t> as ReadVoltage;
    interface Timer<TMilli> as MonitorPeriod;

    interface CollectionInfo;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
												
//  provides interface AdcConfigure<const msp430adc12_channel_config_t*>
//  as AdcConfTemp;
												
}

implementation {

  TLOpId_t inTkId, reactionId;

  uint8_t minuteTick = 0;
  uint16_t voltage = 0;


  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
    tMonitor;
  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tNotify;
  uint16_t msgSeqNum = 0;

  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> token;
  bool tkReactActive, alarmToSend;

  nx_struct opaqueTupleAggSysInfo {
    nx_uint16_t info_type_id;
    nx_uint16_t node_id;
    nx_uint16_t parent;
    nx_uint16_t parent_quality;
    nx_uint16_t voltage;
  };

  event void Boot.booted() {

    token = newTuple(
                     actualField(MSG_TYPE),
                     dontCare(),
                     actualField(TOKEN),
                     dontCare());

    tkReactActive = FALSE;
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, 
                        (tuple *) &token);  

    call MonitorPeriod.startPeriodic(MINUTE);

    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());


#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
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
                   
                 } 
               } else {
                 tkReactActive = TRUE;
               });
												
  }
												
  event void MonitorPeriod.fired() {

    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0) {      
      call ReadVoltage.read();
    }
  }
												
  event void ReadVoltage.readDone(error_t result, uint16_t val) {

    nx_struct opaqueTupleAggSysInfo* ot;

    tMonitor = newTuple(
                        actualField(QUEUE),
                        actualField(TL_LOCAL),
                        actualField(RELIABLE_DELIVERY),
                        arrayField());

    ot = (nx_struct opaqueTupleAggSysInfo*) tMonitor.value3;

    ot->info_type_id = NODE_INFO_TYPE;
    ot->node_id = call AMPacket.address();
    ot->parent = call CollectionInfo.currentParent();
    ot->parent_quality = call CollectionInfo.parentLQI();
    if (result == SUCCESS)
      ot->voltage = val;
    else
      ot->voltage = 0;

    if (!tkReactActive){
      call TS.in(&inTkId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &token); 
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

												

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 
												
}
												
