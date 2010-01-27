/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 190 $
 * * DATE
 * *    $LastChangedDate: 2007-11-05 14:31:35 -0600 (Mon, 05 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TeenyLimeSerializer.nc 190 2007-11-05 20:31:35Z bronwasser $
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
#include "TLConf.h"

module TeenyLimeSerializer {
  provides {
    interface TLSend;
    interface TLReceive;
    interface Init;
  }

  uses {
    interface AMSend as Send;
    interface Receive as Receive;
    interface NeighborSystem;
    interface Init as CommInit;
    interface AMPacket;
    interface TinyMalloc as Mem;
  }
}

implementation {

  /*
   * The most important change here has been to implement a sendQuery() function.
   * We need this because tuples and queries now have different data types.
   *
   * Another important change is that send buffers are allocated at the top of the chain.
   * Whether we use dynamic memory allocation, the buffers should be allocated here, and only
   * pointers to these buffers are passed down the network stack. No unnecessary copying to
   * buffers and message queues. The queue is merely a queue of pointers now, not a queue of
   * buffers. This style has to be implemented for ReliableGenericCommunication.nc still,
   * which should not be too hard.
   * For ReliableGenericComm, calls to Send.getPayload(tosMsg) should just return a pointer
   * to the start of the upper layer payload area. This avoids that ReliableGenericComm needs
   * to move the entire payload to be able to put its own headers in front of the payload.
   *
   */


  // Message buffers are allocated dynamically.
  // To be able to free a send buffer, we must be very sure that we
  // free the same number of bytes we allocated earlier.
  // We store the size of the allocated block in front of the tos message.
  typedef struct {
    uint8_t msgSize;
  } MetaInfo;

  typedef struct {
    MetaInfo metaInfo;
    message_header_t tosHdr;
  } SerializerMsg;

  command error_t Init.init() {
    return call CommInit.init();
  }

  message_t *getTosMsg(SerializerMsg *sMsg) {
    return (message_t*) &(sMsg->tosHdr);
  }


  /*
   * Send 0 or more tuples to over the network.
   *
   * We start by calculating the maximum payload size we can use for tuples.
   * Based on this value, we calculate how many tuples can be send in this
   * packet. We don't perform any fragmentation, tuples that don't fit are discarded.
   *
   * In case of dynamic message length,
   * The tuples are marshalled into a message buffer, together with the
   * current neighbor tuple.
   */
  command result_t TLSend.sendTuples(TLTarget_t target, Tuple *tuples[],
          uint8_t nrTuples, msg_t operation, TLOpId_t *operationId) {

    SerializerMsg *sMsg;
    uint8_t maxTuplePayload, tuplePayload = 0, i, hdrSize, mallocSize;
    TupleMsg *tupleMsg; char *bufPtr; ptr_arithm_t payloadSize;
    Tuple *nghTuple = call NeighborSystem.getNeighborTuple();

    // Calculate max payload that we can use for our tuples.
    // We rely on the lower layer providing the correct max payload.
    // Lower layers (ReliableGenericComm or MsgQ) should subtract their header sizes from the max payload length
    // they return to Send.maxPayloadLength(). This is the standard procedure in TinyOS.
    // Note that the hdrSize we calc contains all headers, including our own, and the neighbor tuple
    hdrSize = sizeof(message_t) - call Send.maxPayloadLength() + sizeof(TupleMsg) + getTupleSize(nghTuple);
    maxTuplePayload = sizeof(message_t) - hdrSize;

//    dbg3("maxTuplePayload %hu\n",maxTuplePayload);

#ifdef NO_DYNAMIC_MSG_LEN
    mallocSize = sizeof(MetaInfo) + sizeof(message_t);
#else
    // Calculate required payload. Each tuple is checked individually.
    for (i = 0; i < nrTuples; i++) {
      if (tuplePayload + getTupleSize(tuples[i]) > maxTuplePayload) {
        break;
      }
      tuplePayload += getTupleSize(tuples[i]);
    }
    mallocSize = sizeof(MetaInfo) + hdrSize + tuplePayload;
#endif

    sMsg = (SerializerMsg*) call Mem.malloc(mallocSize);
    if (sMsg == NULL) return FAIL;
    // Store the number of allocated bytes, to be able to free this buffer wen sendDone is signaled.
    sMsg->metaInfo.msgSize = (mallocSize);

    tupleMsg = call Send.getPayload(getTosMsg(sMsg));
    tupleMsg->operationId = *operationId;
    tupleMsg->operationId.msgOrigin = call AMPacket.address();
    bufPtr = copyTuple(&(tupleMsg->nghTuple[0]),nghTuple);

    // Copy tuples to msg buffer
    tuplePayload = 0;
    for (i = 0; i < nrTuples; i++) {
      if (tuplePayload + getTupleSize(tuples[i]) > maxTuplePayload) {
        err("Unable to put all %hu tuples in msg, will send only %hu.\n",nrTuples,i);
        nrTuples = i;
        break;
      }
      tuplePayload += getTupleSize(tuples[i]);
      bufPtr = copyTuple((Tuple*) bufPtr, tuples[i]);
    }

    tupleMsg->tupleNumber = nrTuples;

    payloadSize = (ptr_arithm_t)bufPtr - (ptr_arithm_t) tupleMsg;

    // Turn this on for reliable communication
//    if (call Send.send(target, payload, tosMsg, operationId.reliable) {
    if (call Send.send(target, getTosMsg(sMsg), payloadSize) == SUCCESS) {
      return SUCCESS;
    }
    // send failed...
    call Mem.free(sMsg,sMsg->metaInfo.msgSize);
    dbg (DBG_ERROR, "TeenyLimeSerializer failed to send to msg Q\n");
    return FAIL;
  }



  command result_t TLSend.sendQuery(TLTarget_t target, Query *q, msg_t operation, TLOpId_t *operationId) {
    SerializerMsg *sMsg;
    uint8_t hdrSize, mallocSize, nghTupleSize; //uint8_t reliable;
    TupleMsg *tupleMsg; char *bufPtr; ptr_arithm_t payloadSize;
    Tuple *nghTuple = call NeighborSystem.getNeighborTuple();

//    dbg3("nghTupleSize %hu\n",getTupleSize(nghTuple));

    // Calculate max payload. We rely on the lower layer providing the correct max payload.
    // Lower layers (ReliableGenericComm or MsgQ) should subtract their header sizes from payload length.
    nghTupleSize = getTupleSize(nghTuple);
    hdrSize = sizeof(message_t) - call Send.maxPayloadLength() + sizeof(TupleMsg) + nghTupleSize;

#ifdef NO_DYNAMIC_MSG_LEN
    mallocSize = sizeof(MetaInfo) + sizeof(message_t);
#else
    mallocSize = sizeof(MetaInfo) + hdrSize + getQuerySize(q);
#endif

    sMsg = (SerializerMsg*) call Mem.malloc(mallocSize);
    if (sMsg == NULL) return FAIL;
    // Store the number of allocated bytes, to be able to free wen sendDone is signaled.
    sMsg->metaInfo.msgSize = (mallocSize);
    tupleMsg = call Send.getPayload(getTosMsg(sMsg));

    tupleMsg->tupleNumber = 1;
    tupleMsg->operationId = *operationId;
    tupleMsg->operationId.msgOrigin = call AMPacket.address();
    bufPtr = copyTuple(&(tupleMsg->nghTuple[0]),nghTuple);
    bufPtr = copyQuery((Query*)bufPtr, q);

    payloadSize = (ptr_arithm_t)bufPtr - (ptr_arithm_t)tupleMsg;

    // Turn this on for reliable communication:
//    if (tupleMsg->operation == REACT) {
//      // Reactions are sent unreliably, although the response may be reliable (operationId.reliable)
//      reliable = FALSE;
//    } else {
//      reliable = operationId->reliable;
//    }
//    if (call Send.send(target, payloadSize, getTosMsg(sMsg), reliable) {

    if (call Send.send(target, getTosMsg(sMsg), payloadSize) == SUCCESS) {
      return SUCCESS;
    }
    // Oh my, send failed...
    call Mem.free(sMsg,sMsg->metaInfo.msgSize);
    dbg (DBG_ERROR, "TeenyLimeSerializer failed to send to msg Q\n");
    return FAIL;
  }


  /*
   * Handle incoming tuple message. A tuple message can be the result
   * of a query, or a remote OUT operation.
   * An array of pointers to the tuples in this message is constructed
   * and passed to the upper layer, DistributedTeenyLime.
   * Nothing is being copied here.
   */
  void handleIncomingTuples(TupleMsg* tlMsg) {
    Tuple *tuples[tlMsg->tupleNumber];
    uint8_t i; char *bufPtr;

    bufPtr = (char*) (ptr_arithm_t)&(tlMsg->nghTuple[0]) + (ptr_arithm_t)getTupleSize(&(tlMsg->nghTuple[0]));
    for (i = 0; i < tlMsg->tupleNumber; i++) {
      // Store pointer in array
      tuples[i] = (Tuple*) bufPtr;
      // Move buf pointer to next tuple in message
      bufPtr += (ptr_arithm_t) getTupleSize(tuples[i]);
    }
    signal TLReceive.receiveTuples(tuples, tlMsg->tupleNumber,
        tlMsg->operation, &(tlMsg->operationId));
  }

  /*
   * Handle incoming query message. A query message can be an incoming
   * reaction or a RD or IN operation.
   * A pointer to the query is passed to the upper layer, DistributedTeenyLime.
   * Nothing is being copied here.   *
   */
  void handleIncomingQuery(TupleMsg* tlMsg) {
    Query *q;
    q = (Query*) &(tlMsg->nghTuple[0]) + (ptr_arithm_t)getTupleSize(&(tlMsg->nghTuple[0]));
    signal TLReceive.receiveQuery(q, tlMsg->operation, &(tlMsg->operationId));
  }


  event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len){
    TupleMsg *tlMsg = (TupleMsg*) payload;

    // Refresh neighbor tuple
    call NeighborSystem.update(tlMsg->operationId.msgOrigin, &(tlMsg->nghTuple[0]));
    // Handle incoming packet
    switch (tlMsg->operation) {
      case OUT_OP:          handleIncomingTuples(tlMsg); break;
      case RD_OP:           handleIncomingQuery(tlMsg);  break;
      case RDG_OP:          handleIncomingQuery(tlMsg);  break;
      case IN_OP:           handleIncomingQuery(tlMsg);  break;
      case ING_OP:          handleIncomingQuery(tlMsg);  break;
      case QUERY_RESULT:    handleIncomingTuples(tlMsg); break;
      case REACT:           handleIncomingQuery(tlMsg);  break;
      case REACTION_FIRING: handleIncomingTuples(tlMsg); break;
    }
    return msg;
  }

  /*
   * Turn this on for reliable communication.
   * When this component is connected to ReliableGenericComm,
   * we receive a signal when an outgoing message has been acked
   * by all neighbors.
   *
   * @param msg: the message that has been acked by all neighbors
   */
//  event result_t Send.deliveredMessage(TOS_MsgPtr msg) {
//    TupleMsg* tlMsg = (TupleMsg*) msg->data;
//    signal ReceiveTuple.operationCompleted(tlMsg->operationId);
//
//    return SUCCESS;
//  }

  event void Send.sendDone(TOS_MsgPtr msg, result_t success) {
    SerializerMsg *sMsg;
    // Inform upper layer of transmitted packet
    TupleMsg* tupleMsg = (TupleMsg*) call Send.getPayload(msg);
    signal TLSend.sendDone(&(tupleMsg->operationId), success);
    // Free the msg buffer
    sMsg = (SerializerMsg*) ((ptr_arithm_t)msg - sizeof(MetaInfo));
    call Mem.free(sMsg,sMsg->metaInfo.msgSize);
  }

/* #ifndef mica2 */
/*   command result_t SendTuple.sendSimMsg() { */
/*     int i; */
/*     TupleMsg *tlMsg = (TupleMsg *)tosMsg.data; */

/*     tlMsg->nghTuple = *(call NeighborSystem.getNeighborTuple()); */

/*     tlMsg->operation = SIM_MSG; */
/*     tlMsg->operationId.reliable = FALSE; */
/*     tlMsg->operationId.msgOrigin = TOS_LOCAL_ADDRESS; */

/*     return call ReliableSend.send(TOS_BCAST_ADDR,  */
/* 				  sizeof(TupleMsg),  */
/* 				  &tosMsg,  */
/* 				  tlMsg->operationId.reliable); */

/*     return SUCCESS; */
/*   } */
/* #endif */
}
