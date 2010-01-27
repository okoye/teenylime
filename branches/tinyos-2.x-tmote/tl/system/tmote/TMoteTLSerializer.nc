/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 304 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 04:35:11 -0600 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TMoteTLSerializer.nc 304 2008-03-04 10:35:11Z lmottola $
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

#include "TupleSpace.h"
#include "TupleMsg.h"
#include "TLDebug.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

module TMoteTLSerializer {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }

  uses {
    interface AMPacket;
    interface AMSend;
    interface ReliableSend;
    interface Receive;
    interface Receive as Snoop;
    interface CC2420Packet;
    interface TLDebug;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
   }
}

implementation {

  // Buffer for outgoing data
  message_t serializeMsg;

  // Buffer for received data
  TupleMsg tlMsg;

  void packTuples(TLTarget_t target, tuple* tuples, 
		  uint8_t tupleNumber, uint8_t operation, 
		  TLOpId_t operationId) {

    int i;
    bool reliable = FALSE;
    TupleMsg *tupleMsg;

    atomic {
      tupleMsg = ((TupleMsg *) call AMSend.getPayload(&serializeMsg));
            
      tupleMsg->operation = operation;
      tupleMsg->operationId.reliable = operationId.reliable;
      tupleMsg->operationId.componentId = operationId.componentId;
      tupleMsg->operationId.commandId = operationId.commandId;
      
      // TODO: Signal overflow...
      copyTuple(&(tupleMsg->nghTuple), signal NeighborSystem.getNeighborTuple());
      for (i=0; i<tupleNumber && i<MAX_TUPLES_MSG; i++){
	copyTuple(&(tupleMsg->tuples[i]), &(tuples[i]));
      } 
      tupleMsg->tupleNumber = i;
      tupleMsg->operationId.msgOrigin = call AMPacket.address();
      
      if (operation != REACT) {
	reliable = operationId.reliable;
      }

      call ReliableSend.send(target, &serializeMsg, sizeof(TupleMsg), reliable);
      
      if (tupleNumber > MAX_TUPLES_MSG) {
	packTuples(target, &tuples[MAX_TUPLES_MSG], (tupleNumber-MAX_TUPLES_MSG), 
		   operation, operationId);	
      }
    }    
  }

  command error_t SendTuple.send(TLTarget_t target, tuple* tuples, 
				 uint8_t tupleNumber, uint8_t operation, 
				 TLOpId_t operationId) {

    packTuples(target, tuples, tupleNumber, operation, operationId);
    return SUCCESS;
  }
  
  event message_t* Snoop.receive(message_t* msg, void *payload, uint8_t len){

    uint8_t i;
    uint16_t origin;
    TupleMsg* recvMsg;
    tuple nghTuple;

    atomic {

      if (call CC2420Packet.getLqi(msg) > MIN_LQI 
	  || call AMPacket.destination(msg) == call AMPacket.address()) {

	call TLDebug.ledToggle(2);
	
	recvMsg = (TupleMsg*) payload;
	origin = recvMsg->operationId.msgOrigin;
	copyTuple(&nghTuple, &(recvMsg->nghTuple));

	// Check if the neighbor tuple contains TYPE_LQI or TYPE_RSSI fields
	for (i=0; i<MAX_FIELDS; i++) {
	  if (isFormalField(&(nghTuple.fields[i]))
	      && getFieldType(&(nghTuple.fields[i])) == TYPE_LQI) {
	    nghTuple.fields[i].value.int8 = call CC2420Packet.getLqi(msg);
	    nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_LQI);
	  } else if (isFormalField(&(nghTuple.fields[i]))
		     && getFieldType(&(nghTuple.fields[i])) == TYPE_RSSI) {
	    nghTuple.fields[i].value.int8 = call CC2420Packet.getRssi(msg);
	    nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_RSSI);
	  } 
	}

	signal NeighborSystem.update(origin, nghTuple);
      } 
      return msg;
    }
  }

  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len){

    uint8_t i;
    TupleMsg* recvMsg;

    atomic {

      if (call CC2420Packet.getLqi(msg) > MIN_LQI 
	  || call AMPacket.destination(msg) == call AMPacket.address()) {
	
	recvMsg = (TupleMsg*) payload;

	// Only the neighbor tuple gets possibly written
	tlMsg.tupleNumber = recvMsg->tupleNumber;
	tlMsg.operation = recvMsg->operation;
	tlMsg.operationId.commandId = recvMsg->operationId.commandId;
	tlMsg.operationId.reliable = recvMsg->operationId.reliable;
	tlMsg.operationId.componentId = recvMsg->operationId.componentId;
	tlMsg.operationId.msgOrigin = recvMsg->operationId.msgOrigin;
	for (i=0; i<recvMsg->tupleNumber; i++) {
	  copyTuple(&tlMsg.tuples[i], &(recvMsg->tuples[i]));
	} 
	copyTuple(&tlMsg.nghTuple, &(recvMsg->nghTuple));
	// Check if the neighbor tuple contains TYPE_LQI or TYPE_RSSI fields
	for (i=0; i<MAX_FIELDS; i++) {
	  if (isFormalField(&(tlMsg.nghTuple.fields[i]))
	      && getFieldType(&(tlMsg.nghTuple.fields[i])) == TYPE_LQI) {
	    tlMsg.nghTuple.fields[i].value.int8 = call CC2420Packet.getLqi(msg);
	    tlMsg.nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_LQI);
	  } else if (isFormalField(&(tlMsg.nghTuple.fields[i]))
		     && getFieldType(&(tlMsg.nghTuple.fields[i])) == TYPE_RSSI) {
	    tlMsg.nghTuple.fields[i].value.int8 = call CC2420Packet.getRssi(msg);
	    tlMsg.nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_RSSI);
	  } 
	}

	signal NeighborSystem.update(tlMsg.operationId.msgOrigin,
				     tlMsg.nghTuple);
	signal ReceiveTuple.receive(tlMsg.tuples, tlMsg.tupleNumber,
				    tlMsg.operation, tlMsg.operationId);
      } 
      return msg;
    }
  }

  event void ReliableSend.reliableSendFailed(am_addr_t addr, message_t* msg){

    TupleMsg* failedTupleMsg = ((TupleMsg*) call AMSend.getPayload(msg));
    TLOpId_t opId;
    tuple failedTuple;

    opId.commandId = failedTupleMsg->operationId.commandId;
    opId.reliable = failedTupleMsg->operationId.reliable;
    opId.componentId = failedTupleMsg->operationId.componentId;
    opId.msgOrigin = failedTupleMsg->operationId.msgOrigin;
    copyTuple(&failedTuple, &(failedTupleMsg->tuples[0]));

    if (failedTupleMsg->operation != QUERY_RESULT
	&& failedTupleMsg->operation != REACTION_FIRING) { 
      signal SendTuple.reliableOpFail(opId, (TLTarget_t)addr, &failedTuple);
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t success) {
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
