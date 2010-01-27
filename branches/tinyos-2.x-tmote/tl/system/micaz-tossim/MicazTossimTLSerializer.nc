/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 256 $
 * * DATE
 * *    $LastChangedDate: 2008-01-28 12:20:56 -0600 (Mon, 28 Jan 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MicazTossimTLSerializer.nc 256 2008-01-28 18:20:56Z lmottola $
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

module MicazTossimTLSerializer {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }

  uses {
    interface AMPacket;
    interface AMSend;
    interface ReliableSend;
    interface Receive as Receive;
    interface TLDebug;
   }
}

implementation {

  // Buffer for outgoing data
  message_t tosMsg;
  // Buffer for received data
  bool deliveringToApp = FALSE;
  TupleMsg tlMsg;

  command error_t SendTuple.send(TLTarget_t target, tuple* tuples, 
				  uint8_t tupleNumber, uint8_t operation, 
				  TLOpId_t operationId) {

    int i;
    TupleMsg *tupleMsg = (TupleMsg *)tosMsg.data;

    dbg ("DBG_USR1", "TupleMsg size is %d\n",sizeof(TupleMsg));

    tupleMsg->tupleNumber = tupleNumber;
    tupleMsg->operation = operation;
    tupleMsg->operationId.reliable = operationId.reliable;
    tupleMsg->operationId.componentId = operationId.componentId;
    tupleMsg->operationId.commandId = operationId.commandId;

    // TODO: Signal overflow...
    copyTuple(&(tupleMsg->nghTuple), signal NeighborSystem.getNeighborTuple());
    for (i=0; i<tupleNumber && i<MAX_TUPLES_MSG; i++){
      copyTuple(&(tupleMsg->tuples[i]), &(tuples[i]));
    } 
    tupleMsg->operationId.msgOrigin = call AMPacket.address();

    if (call ReliableSend.send(target, &tosMsg, 
		       sizeof(TupleMsg), operationId.reliable) == SUCCESS) {
      return SUCCESS;     
    } else {
      return FAIL;     
    }
  }

  task void receiveTask() {

    signal NeighborSystem.update(tlMsg.operationId.msgOrigin,
			       tlMsg.nghTuple);
    signal ReceiveTuple.receive(tlMsg.tuples, tlMsg.tupleNumber,
				tlMsg.operation, tlMsg.operationId);
    deliveringToApp = FALSE;
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

  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len){

    uint8_t i;
    TupleMsg* recvMsg = (TupleMsg*) msg->data;

    // Copying message in temporary buffer
    if (!deliveringToApp) { 
      deliveringToApp = TRUE;
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
      // In TOSSIM simulations, these are always set to 0 if found 
      for (i=0; i<MAX_FIELDS; i++) {
	if (isFormalField(&(tlMsg.nghTuple.fields[i]))
	    && getFieldType(&(tlMsg.nghTuple.fields[i])) == TYPE_LQI) {
	  tlMsg.nghTuple.fields[i].value.int8 = 0;
	  tlMsg.nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_LQI);
	} else if (isFormalField(&(tlMsg.nghTuple.fields[i]))
	    && getFieldType(&(tlMsg.nghTuple.fields[i])) == TYPE_RSSI) {
	  tlMsg.nghTuple.fields[i].value.int8 = 0;
	  tlMsg.nghTuple.fields[i].type = (TYPE_ACTUAL | TYPE_RSSI);
	} 
      }
      post receiveTask();
    } 
    return msg;
  }

  event void AMSend.sendDone(message_t* msg, error_t success) {
  }
}
