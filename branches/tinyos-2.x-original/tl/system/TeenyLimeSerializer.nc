/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 173 $
 * * DATE
 * *    $LastChangedDate: 2007-10-31 20:40:56 +0100 (Wed, 31 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TeenyLimeSerializer.nc 173 2007-10-31 19:40:56Z bronwasser $
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
    interface SendTuple;
    interface ReceiveTuple;
    interface Init;
  }

  uses {
    interface AMSend as Send;
    interface Receive as Receive;
    interface NeighborSystem;
    interface Init as CommInit;
    interface AMPacket;
   }
}

implementation {

  TOS_Msg tosMsg;


  command error_t Init.init() {
    return call CommInit.init();
  }

  command result_t SendTuple.send(TLTarget_t target, tuple* tuples,
          uint8_t tupleNumber, msg_t operation,
          TLOpId_t operationId) {


    int i, result;
    TupleMsg *tupleMsg = (TupleMsg *)tosMsg.data;

    tupleMsg->nghTuple = *(call NeighborSystem.getNeighborTuple());

    for (i=0; i<tupleNumber && i<MAX_TUPLES_MSG; i++){
      tupleMsg->tuples[i] = tuples[i];
    }

    operationId.msgOrigin = TOS_LOCAL_ADDRESS;

    tupleMsg->tupleNumber = tupleNumber;
    tupleMsg->operation = operation;
    tupleMsg->operationId = operationId;

    result = call Send.send(TOS_BCAST_ADDR, &tosMsg, sizeof(TupleMsg));
    return result;

//    if (tupleMsg->operation != REACT) {
//      return call ReliableSend.send(target, sizeof(TupleMsg), &tosMsg,
//				    operationId.reliable);
//    } else {
//      return call ReliableSend.send(target, sizeof(TupleMsg), &tosMsg, FALSE);
//    }
  }

  // todo
  TupleMsg* tlMsg;

  task void receiveTask() {
    call NeighborSystem.update(tlMsg->operationId.msgOrigin, tlMsg->nghTuple);
    signal ReceiveTuple.receive(tlMsg->tuples, tlMsg->tupleNumber,
        tlMsg->operation, tlMsg->operationId);
//        uart_puts("recv\n");
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void *payload, uint8_t len){
    tlMsg = (TupleMsg*) payload;
    post receiveTask();
    return msg;
  }

//  event result_t Send.deliveredMessage(TOS_MsgPtr msg) {
//    TupleMsg* tlMsg = (TupleMsg*) msg->data;
//    signal ReceiveTuple.operationCompleted(tlMsg->operationId);
//
//    return SUCCESS;
//  }

  event void Send.sendDone(TOS_MsgPtr msg, result_t success) {
    TupleMsg* tpMsg = (TupleMsg*) msg->data;
    signal SendTuple.sendDone(tpMsg->operationId, success);

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
