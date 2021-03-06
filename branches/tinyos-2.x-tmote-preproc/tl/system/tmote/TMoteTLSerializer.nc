/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 894 $
 * * DATE
 * *    $LastChangedDate: 2009-09-07 12:03:39 -0500 (Mon, 07 Sep 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TMoteTLSerializer.nc 894 2009-09-07 17:03:39Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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
#include "tl_objs.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define RESET_TIMER 3000

module TMoteTLSerializer {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }

  uses {
    interface Alarm<TMilli,uint16_t> as AlarmReset;
    interface QueueControl as TMoteQueueControl;
    interface AMPacket;
    interface ReliableSend;
    interface Receive;
    interface Receive as Snoop;
    interface CC2420Packet;
    interface TLDebug;
    interface TLObjects;
 
#ifdef TL_CONTROLLER_NODE
    interface Boot;
    interface SplitControl as SerialAMControl;
    interface Receive as SerialReceive;    
#endif
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
   }
}

implementation {

  // Fletcher coding
  void fletcher16(uint8_t *checkA, uint8_t *checkB, uint8_t *data, size_t len) {

    uint16_t sum1 = 0xff, sum2 = 0xff;
    
    while (len) {
      size_t tlen = len > 21 ? 21 : len;
      len -= tlen;
      do {
	sum1 += *data++;
	sum2 += sum1;
      } while (--tlen);
      sum1 = (sum1 & 0xff) + (sum1 >> 8);
      sum2 = (sum2 & 0xff) + (sum2 >> 8);
    }
    
    sum1 = (sum1 & 0xff) + (sum1 >> 8);
    sum2 = (sum2 & 0xff) + (sum2 >> 8);
    *checkA = (uint8_t)sum1;
    *checkB = (uint8_t)sum2;
  }

  void packTuples(TLTarget_t target, tuple *tuples, 
		  uint8_t tupleNumber, uint8_t operation, 
		  TLOpId_t operationId) {

    int i;
    bool reliable = FALSE;
    TupleMsg *tupleMsg;
    nx_uint8_t *pos;
    uint8_t fletcher1, fletcher2, totalSize = 0;
#ifdef SECURE_TL
    bool reconf = FALSE;
#endif

    // Buffer for outgoing data
    message_t serializeMsg;

    atomic {

      tupleMsg = (TupleMsg *) call ReliableSend.getPayload(&serializeMsg);
            
      tupleMsg->header.operation = operation;

      tupleMsg->header.commandId = operationId.commandId;
      tupleMsg->header.reliable_componentId = 
	((operationId.reliable & 0x01) << 7) | (operationId.componentId & 0x7F) ;
    
      // TODO: Signal overflow...
      pos = (nx_uint8_t *) tupleMsg->data;

      totalSize += call TLObjects.copy_tuple((tuple *) pos, 
					   signal NeighborSystem.getNeighborTuple());
      pos = (nx_uint8_t *) (((char *) pos) + totalSize);

      for (i = 0;
           i < tupleNumber && 
           (char *) pos - (char *) tupleMsg +
                call TLObjects.tuple_sizeof(tuples) <= sizeof(TupleMsg);
           i++) {
        int size = call TLObjects.copy_tuple((tuple *) pos, tuples);
#ifdef SECURE_TL
        if ((tuples->flags & FLAG_SECURE_RECONF) != 0)
          reconf = TRUE;
#endif
        totalSize += size;
        pos += size;
        tuples = (tuple *) ((char *) tuples + size);
      }
      tupleMsg->header.tupleNumber = i;
      
      if (operation != REACT) {
	reliable = operationId.reliable;
      }

      // Computing and embedding Fletcher codes
      fletcher16(&fletcher1,&fletcher2,(uint8_t*)tupleMsg->data,TUPLE_MSG_DATA_SIZE);

#ifdef PRINTF_SUPPORT
/*       printf("%d-%d\n", fletcher1, fletcher2); */
/*       call PrintfFlush.flush(); */
#endif
      tupleMsg->header.fletcher1 = fletcher1;
      tupleMsg->header.fletcher2 = fletcher2;

#ifdef SECURE_TL
      call ReliableSend.send(target, &serializeMsg, sizeof(TupleMsg), reliable,
              reconf);
#else
      call ReliableSend.send(target, &serializeMsg, sizeof(TupleMsg), reliable);
#endif

      if (tupleNumber > tupleMsg->header.tupleNumber) {
        packTuples(target, tuples, tupleNumber - tupleMsg->header.tupleNumber, 
                operation, operationId);	
      }
    }    
  }

  // For system-wide reset
  task void systemReset() {

    TLOpId_t fake;
    
/*     call TLDebug.ledToggle(0); */
    packTuples(TL_NEIGHBORHOOD, NULL, 0, CTRL_RESET, fake);
    call TMoteQueueControl.close();
    call AlarmReset.start(RESET_TIMER);
  }

  async event void AlarmReset.fired() {
    WDTCTL = WDT_ARST_1_9; 
    while(1);
  }

  command error_t SendTuple.send(TLTarget_t target, tuple *tuples, 
				 uint8_t tupleNumber, uint8_t operation, 
				 TLOpId_t operationId) {

    packTuples(target, tuples, tupleNumber, operation, operationId);
    return SUCCESS;
  }
  
  
  void *get_field(tuple *t, int id) {

    uint8_t *field_types = (uint8_t *) t->contents;
    int field_count = call TLObjects.field_count(t->type);
    char *field_iterator;
    int i;

    if (field_count & 1)
      field_count++;

    field_iterator = field_types + field_count;

    for (i = 0; i < id; i++)
      field_iterator +=
        call TLObjects.get_field_size(t->type, i); 

    return (void *) field_iterator;
  }


  event message_t* Snoop.receive(message_t* msg, void *payload, uint8_t len){

    uint16_t origin;
    TupleMsg* recvMsg;
    tuple* nghTuple;
    uint8_t fletcher1, fletcher2;

    atomic {
      
      if ((call CC2420Packet.getLqi(msg) > MIN_LQI 
	   || call AMPacket.destination(msg) == call AMPacket.address()) 
	  && len == TUPLE_MSG_DATA_SIZE + sizeof(TL_header)) {
	
	recvMsg = (TupleMsg*) payload;

	// Checking Fletcher codes
	fletcher16(&fletcher1,&fletcher2,(uint8_t*)recvMsg->data,TUPLE_MSG_DATA_SIZE);

#ifdef PRINTF_SUPPORT
/* 	printf("%d-%d\n", fletcher1, fletcher2); */
/* 	call PrintfFlush.flush(); */
#endif

	if (recvMsg->header.fletcher1 != fletcher1 ||
	    recvMsg->header.fletcher2 != fletcher2) {
	  return msg;
	}

	origin = call AMPacket.source(msg);
	
	nghTuple = (tuple *) recvMsg->data;   
	call TLObjects.replace_indicator(nghTuple, call CC2420Packet.getLqi(msg),
					 call CC2420Packet.getRssi(msg));
	
	signal NeighborSystem.update(origin, nghTuple);
      } 
      return msg;
    }
  }
  
  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len){

    TupleMsg* recvMsg;
    tuple *nghTuple, *result;
    TLOpId_t tlOperationId;
    uint8_t fletcher1, fletcher2;

    atomic {

      if ((call CC2420Packet.getLqi(msg) > MIN_LQI 
	   || call AMPacket.destination(msg) == call AMPacket.address()) 
	  && len == TUPLE_MSG_DATA_SIZE + sizeof(TL_header)) {
	
	recvMsg = (TupleMsg*) payload;

	// Checking Fletcher codes
	fletcher16(&fletcher1,&fletcher2,(uint8_t*)recvMsg->data,TUPLE_MSG_DATA_SIZE);

#ifdef PRINTF_SUPPORT
/* 	printf("%d-%d\n", fletcher1, fletcher2); */
/* 	call PrintfFlush.flush(); */
#endif
	
	if (recvMsg->header.fletcher1 != fletcher1 ||
	    recvMsg->header.fletcher2 != fletcher2) {
	  // Did not pass Fletcher checks
	  return msg;
	}

	if (recvMsg->header.operation == CTRL_RESET) {
	  post systemReset();
	} else {	  
	  tlOperationId.msgOrigin = call AMPacket.source(msg);
	  tlOperationId.commandId = recvMsg->header.commandId;
	  tlOperationId.componentId = recvMsg->header.reliable_componentId & 0x7F;
	  tlOperationId.reliable = (recvMsg->header.reliable_componentId & 0x80) >> 7;
	  
	  nghTuple = (tuple *) recvMsg->data;
	  
	  call TLObjects.replace_indicator(nghTuple, call CC2420Packet.getLqi(msg),
					   call CC2420Packet.getRssi(msg));
	  
	  result = (tuple *) NEXT_TUPLE(nghTuple);
	  
	  signal NeighborSystem.update(tlOperationId.msgOrigin, nghTuple);
	  signal ReceiveTuple.receive(result, recvMsg->header.tupleNumber,
				      recvMsg->header.operation, tlOperationId);
	}
      } 
      return msg;
    }
  }

  event void ReliableSend.sendDone(message_t* msg, error_t error, 
				   bool reliableSendFailed){

    TupleMsg* tupleMsg = ((TupleMsg*) call ReliableSend.getPayload(msg));
    TLOpId_t opId;
    tuple *nghTuple, *first_tuple;

    nghTuple = (tuple *) tupleMsg->data;
    first_tuple = (tuple *) (tupleMsg->data + 
            call TLObjects.tuple_sizeof(nghTuple));
    
    opId.msgOrigin = call AMPacket.source(msg);
    opId.commandId = tupleMsg->header.commandId;
    opId.componentId = tupleMsg->header.reliable_componentId & 0x7F;
    opId.reliable = (tupleMsg->header.reliable_componentId & 0x80) >> 7;

    if (opId.reliable 
	&& tupleMsg->header.operation != QUERY_RESULT
	&& tupleMsg->header.operation != REACT
	&& tupleMsg->header.operation != REACTION_FIRING) {

      switch (tupleMsg->header.operation) {
	
      case OUT_OP:
	if (reliableSendFailed) {
	  signal SendTuple.operationCompleted(RELIABLE_OP_FAIL, opId, 
					      (TLTarget_t)call AMPacket.destination(msg), 
					      first_tuple);
	} else {
	  signal SendTuple.operationCompleted(OP_COMPLETED_OK, opId, 
					      (TLTarget_t)call AMPacket.destination(msg), 
					      first_tuple);
	}
	break;

      case RD_OP: 
      case IN_OP: 
      case RDG_OP: 
      case ING_OP: 
	if (reliableSendFailed) {
	  signal SendTuple.operationCompleted(RELIABLE_OP_FAIL, opId, 
					      (TLTarget_t)call AMPacket.destination(msg), 
					      first_tuple);
	} else {
	  signal SendTuple.operationCompleted(QUERY_SENT_OK, opId, 
					      (TLTarget_t)call AMPacket.destination(msg), 
					      first_tuple);
	}

	break;

      default: 
	break;	
      }
    }
  }

#ifdef TL_CONTROLLER_NODE
  event void Boot.booted() {
    call SerialAMControl.start();
  }

  event void SerialAMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call SerialAMControl.start();
    }
  }

  event message_t* SerialReceive.receive(message_t* msg_uart_rx, 
					 void* payload, uint8_t len) {

    TL_header* serialPayload = (TL_header*) payload;

    // Luca: This shall be moved to a diff component if it grows 
    if (serialPayload->operation == CTRL_RESET) {
      post systemReset();
    }

    return msg_uart_rx;
  }

  event void SerialAMControl.stopDone(error_t err) {}
#endif  

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}
