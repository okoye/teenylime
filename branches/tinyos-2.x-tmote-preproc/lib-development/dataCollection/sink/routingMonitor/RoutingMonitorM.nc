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
 * *	$Id: RoutingMonitorM.nc 955 2009-11-28 22:07:05Z mceriotti $
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

/**
 * The component in charge of providing monitoring information on a
 * the routing protocol.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module RoutingMonitorM {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as ReadVoltage;
    interface Timer<TMilli> as MonitorPeriod;

    interface CollectionDebug;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint8_t minuteTick = 0;

  nx_struct opaqueTupleSysInfo {
    nx_uint16_t type; //2
    nx_uint16_t seq_no; //4
    nx_uint16_t address; //6
    nx_uint16_t gateway; //8
    nx_uint16_t gateway_changes; //10
    nx_uint16_t parent; //12
    nx_uint16_t parent_cost; //14
    nx_uint16_t parent_changes; //16
    nx_uint16_t root_congestions; //18
    nx_uint16_t subtree_congestions; //20
    nx_uint16_t msg_deleted_buffer_overflow; //22
    nx_uint16_t successful_recoveries; //24
    nx_uint16_t failed_recoveries; //26
    nx_uint16_t rd_retries; //28
    nx_uint16_t packets_forwarded[3]; //34
    nx_uint16_t retries[3]; //40
    nx_uint16_t dropped_duplicates; //42
    nx_uint16_t out_retries; //44
    nx_uint16_t total_send; //46
    nx_uint16_t total_retxmit; //48
    nx_uint16_t voltage; //50
  };

  nx_struct opaqueTupleSysInfo page_I;

  uint16_t seq_no;

  event void Boot.booted() {
    seq_no = 0;
    page_I.type = ROUTING_INFO_TYPE;
    page_I.seq_no = 0;
    page_I.address = TL_LOCAL;
    page_I.gateway = TL_LOCAL;
    page_I.gateway_changes = 0;
    page_I.parent = TL_LOCAL;
    page_I.parent_cost = 0;
    page_I.parent_changes = 0;
    page_I.root_congestions = 0;
    page_I.subtree_congestions = 0;
    page_I.msg_deleted_buffer_overflow = 0;
    page_I.successful_recoveries = 0;
    page_I.failed_recoveries = 0;
    page_I.rd_retries = 0;
    page_I.packets_forwarded[0] = 0;
    page_I.packets_forwarded[1] = 0;
    page_I.packets_forwarded[2] = 0;
    page_I.retries[0] = 0;
    page_I.retries[1] = 0;
    page_I.retries[2] = 0;
    page_I.dropped_duplicates = 0;
    page_I.out_retries = 0;
    page_I.total_send = 0;
    page_I.total_retxmit = 0;
    page_I.voltage = 0;
        
    call MonitorPeriod.startPeriodic(MINUTE);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    
  }

  event void MonitorPeriod.fired() {
    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0) {
      call ReadVoltage.read();
      
    }
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {

    TLOpId_t outId;

    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> tMonitor;

    tMonitor = newTuple(
                        actualField(MSG_TYPE),
                        actualField(TL_LOCAL),
                        actualField(UNRELIABLE_DELIVERY),
                        arrayField());
    page_I.seq_no = seq_no++;
    page_I.voltage = val;
    page_I.total_send = call CollectionDebug.getTotalSend();
    page_I.total_retxmit = call CollectionDebug.getTotalRetxmit();
    memcpy(&(tMonitor.value3), &page_I, sizeof(nx_struct opaqueTupleSysInfo));
    call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *)&tMonitor);
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

  event void CollectionDebug.treeBuilt(){
    page_I.parent_changes++;
  }

  event void CollectionDebug.packetReceived(uint8_t traffic_class, 
                             uint16_t child){
    page_I.packets_forwarded[traffic_class]++;
  }

  event void CollectionDebug.treeCongested(){
    page_I.root_congestions++;
  }

  event void CollectionDebug.bufferOverflow(uint8_t deletedMessages){
    page_I.msg_deleted_buffer_overflow += deletedMessages;
  }

  event void CollectionDebug.messageRecovery(bool success, 
                                             uint8_t retries,
                                             uint16_t child){
    if (success){
      page_I.successful_recoveries++;
    } else {
      page_I.failed_recoveries++;
    }
    page_I.rd_retries += retries;
  }

  event void CollectionDebug.droppedDuplicate(uint16_t child){
    page_I.dropped_duplicates++;
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

