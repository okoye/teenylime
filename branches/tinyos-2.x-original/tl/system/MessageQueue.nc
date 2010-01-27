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
 * *	$Id: MessageQueue.nc 173 2007-10-31 19:40:56Z bronwasser $
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

#include "MsgQueueConf.h"
#define mydbg(d, s...) dbg(d, ## s)

module MessageQueue {
  provides {
    interface StdControl;
    interface Init;
    interface AMSend as Send;
    interface Receive as Receive;
  }

  uses {
    interface AMSend as SendComm;
    interface SplitControl as AMControl;
    interface Receive as ReceiveComm;
    interface NeighborSystem;
    interface Timer<TMilli> as SendMsgTimer;
   }
}

implementation {

  TOS_Msg tosMsg;

  TOS_Msg pendingMsgs[QUEUE_SIZE];
  uint16_t pendingAddresses[QUEUE_SIZE];
  uint8_t pendingLengths[QUEUE_SIZE];

  uint8_t nextPendingMsg;
  bool transmitLock = FALSE;

//  void print_data_size() {
//
//    uart_puts("\n\nMsgQueue data\n");
//
//    uart_puthex4(sizeof(TOS_Msg));
//    uart_puts(" <- tosMsg\n");
//
//    uart_puthex4(sizeof(pendingMsgs));
//    uart_puts(" <- pendingMsgs * QUEUE_SIZE\n");
//
//    uart_puthex4(sizeof(pendingAddresses));
//    uart_puts(" <- pendingAddresses * QUEUE_SIZE\n");
//
//    uart_puthex4(sizeof(pendingLengths));
//    uart_puts(" <- pendingLengths * QUEUE_SIZE\n");
//
//    uart_puthex4(sizeof(nextPendingMsg));
//    uart_puts(" <- nextPendingMsg\n");
//
//    uart_puthex4(sizeof(transmitLock));
//    uart_puts(" <- transmitLock\n");
//
//    uart_puts("end of MsgQueue data\n\n");
//  }

 /**
  * Initialize pendingMesg structure
  */
  void initPendingMsgs() {
    nextPendingMsg = 0;
  }

  /**
   * It adds the message passed as parameter to the pending msg
   * list. If the tupleMessage has not been added to the tuple space,
   * it is and then it is added to the queue list.
   */
  result_t addPendingMsg(uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    if(nextPendingMsg < QUEUE_SIZE) {
      pendingMsgs[nextPendingMsg] = *msg;
      pendingAddresses[nextPendingMsg] = address;
      pendingLengths[nextPendingMsg] = length;

      nextPendingMsg++;

      return SUCCESS;
    }
    else {
      mydbg(DBG_ERROR, "ERROR: No space left in the pending message list\n");
      uart_puts("no space left in the pending msg list\n");
      return FAIL;
    }
  }

  /**
   * It returns the next message to send. If all messages have been
   * sent, NULL is returned.
   */
  bool getFirstPendingMsg(TOS_Msg *msg, uint16_t *address, uint8_t *length) {
    uint8_t i;

    if(nextPendingMsg > 0) {
      *msg = pendingMsgs[0];
      *address = pendingAddresses[0];
      *length = pendingLengths[0];

      nextPendingMsg--;

      for(i=0; i < nextPendingMsg; i++) {
  pendingMsgs[i] = pendingMsgs[i+1];
  pendingAddresses[i] = pendingAddresses[i+1];
  pendingLengths[i] = pendingLengths[i+1];
      }
      return TRUE;
    }
    else {
      return FALSE;
    }
  }

  result_t sendPendingMsg(uint16_t address, uint8_t length, TOS_MsgPtr msg) {

    if(!transmitLock) {
      transmitLock = TRUE;
      tosMsg = *msg;
      mydbg (DBG_USR1, "Sending message size %d\n",length);
      uart_puts("send");
//      return SUCCESS;
      if(call SendComm.send(address, &tosMsg, length) == SUCCESS) {
//        uart_puts("success\n");
        return SUCCESS;
      } else {
        transmitLock = FALSE;
        uart_puts("error, msg not sent\n");
        mydbg(DBG_ERROR, "ERROR: Message NOT sent\n");
        return FAIL;
      }
    }
    else {
      return FAIL;
    }
  }

  command result_t Init.init() {
//    uart_puts("init msg queue\n");
//    print_data_size();
    initPendingMsgs();
    return SUCCESS;
  }

  command result_t StdControl.start() {
//    uart_puts("start mqueue and AMControl\n");
//    return call AMControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
   return call AMControl.stop();
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.start();
      uart_puts("amcontrol startdone failure\n");
    } else {
      uart_puts("AMControl done succesfully\n");
      // todo: signal higher layer
    }
  }

  event void AMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.stop();
    } else {
      // todo: signal higher layer
    }
  }

  event void SendComm.sendDone(TOS_MsgPtr msg, result_t success) {

    TOS_Msg pendingMsg;
    uint16_t pendingAddress = NULL_NEIGHBOR_ID;
    uint8_t pendingLength = 0;

    if(transmitLock && msg == &tosMsg) {
      transmitLock = FALSE;
      if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
      signal Send.sendDone(msg, success);
//      uart_puts("sendDone success\n");
    }
    else {
      signal Send.sendDone(msg, FAIL);
//      uart_puts("sendDone fail\n");
    }
  }

  command result_t Send.send(uint16_t address, TOS_MsgPtr msg, uint8_t length) {

    if(addPendingMsg(address, length, msg) == SUCCESS) {
      // Initial Scattering
      call SendMsgTimer.startOneShot(MESSAGE_SCATTERING);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command error_t Send.cancel(message_t* msg) {
    // todo: implement cancel
    return FAIL;
  }


  command uint8_t Send.maxPayloadLength() {
    return call SendComm.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg) {
    return call SendComm.getPayload(msg);
  }


  event void SendMsgTimer.fired() {

    TOS_Msg pendingMsg;
    uint16_t pendingAddress = NULL_NEIGHBOR_ID;
    uint8_t pendingLength = 0;


    if(transmitLock == FALSE) {
      if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
    }
  }

//   task void recv() {
//     uart_putchr('r');
//   }

  event TOS_MsgPtr ReceiveComm.receive(TOS_MsgPtr msg, void *payload, uint8_t len){
//    post recv();
    return signal Receive.receive(msg, payload, len);
  }

    command void* Receive.getPayload(message_t *m, uint8_t *len) {
    // todo: consider reliability fields
    return call ReceiveComm.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength(message_t *m) {
    return call ReceiveComm.payloadLength(m);
  }
}

