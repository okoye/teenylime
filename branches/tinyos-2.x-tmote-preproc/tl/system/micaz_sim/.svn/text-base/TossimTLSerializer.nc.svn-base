/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 787 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 14:12:42 +0200 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TossimTLSerializer.nc 787 2009-04-29 12:12:42Z mceriotti $
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

module TossimTLSerializer {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }

  uses {
    interface QueueControl as TossimQueueControl;
    interface AMPacket;
    interface ReliableSend;
    interface Receive;
    interface TLDebug;
    interface TLObjects;
   }
}

implementation {

  void packTuples(TLTarget_t target, tuple *tuples, 
		  uint8_t tupleNumber, uint8_t operation, 
		  TLOpId_t operationId) {

    int i;
    bool reliable = FALSE;
    TupleMsg *tupleMsg;
    nx_uint8_t *pos;
    uint8_t totalSize = 0;

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
        totalSize += size;
        pos += size;
        tuples = (tuple *) ((char *) tuples + size);
      }
      tupleMsg->header.tupleNumber = i;
      
      if (operation != REACT) {
        reliable = operationId.reliable;
      }

      call ReliableSend.send(target, &serializeMsg, sizeof(TupleMsg), reliable);
      
      if (tupleNumber > tupleMsg->header.tupleNumber) {
        packTuples(target, tuples, tupleNumber - tupleMsg->header.tupleNumber, 
                operation, operationId);	
      }
    }    
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

  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len){

    TupleMsg* recvMsg;
    tuple *nghTuple, *result;
    TLOpId_t tlOperationId;

    dbg("TL", "low level receive\n");

    atomic {
      recvMsg = (TupleMsg*) payload;

      tlOperationId.msgOrigin = call AMPacket.source(msg);
      tlOperationId.commandId = recvMsg->header.commandId;
      tlOperationId.componentId = recvMsg->header.reliable_componentId & 0x7F;
      tlOperationId.reliable = 
          (recvMsg->header.reliable_componentId & 0x80) >> 7;

      nghTuple = (tuple *) recvMsg->data;
      result = (tuple *) NEXT_TUPLE(nghTuple);

      signal NeighborSystem.update(tlOperationId.msgOrigin, nghTuple);
      signal ReceiveTuple.receive(result, recvMsg->header.tupleNumber,
              recvMsg->header.operation, tlOperationId);
    }
    return msg;
  }

  event void ReliableSend.sendDone(message_t* msg, error_t error, 
          bool reliableSendFailed) {

  }
}
