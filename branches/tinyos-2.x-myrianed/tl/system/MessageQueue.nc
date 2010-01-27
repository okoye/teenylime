/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 172 $
 * * DATE
 * *    $LastChangedDate: 2007-10-31 14:38:56 -0500 (Wed, 31 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: MessageQueue.nc 172 2007-10-31 19:38:56Z bronwasser $
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
#ifdef myrianode
#include "spi.h"
#endif

#ifndef mydbg
#define mydbg(d, s...) dbg(d, ## s)
//#define mydbg(m, f, s...) dbg(m, "[%s] " f, currentTime(), ## s)
#endif

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
    interface TinyMalloc as Mem;
   }
}

implementation {

  message_t *pendingMsgs[QUEUE_SIZE];
  uint16_t pendingAddresses[QUEUE_SIZE];
  uint8_t pendingLengths[QUEUE_SIZE];

//  message_t *rxMsg;
//  uint8_t rxBusy;

  uint8_t nextPendingMsg;
  bool transmitLock = FALSE;
  void print_data_size();


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
      pendingMsgs[nextPendingMsg] = msg;
      pendingAddresses[nextPendingMsg] = address;
      pendingLengths[nextPendingMsg] = length;

      nextPendingMsg++;

      return SUCCESS;
    }
    else {
      mydbg(DBG_ERROR, "ERROR: No space left in the pending message list\n");
//      uart_puts("no space left in the pending msg list\n");
      return FAIL;
    }
  }

  bool getFirstPendingMsg(message_t *msg, uint16_t *address, uint8_t *length) {
    uint8_t i;

    if (nextPendingMsg > 0) {
      // There is something in the queue, let's send it.
      msg = pendingMsgs[0];
      *address = pendingAddresses[0];
      *length = pendingLengths[0];

      nextPendingMsg--;

      // TODO: shifting the entire queue is not the most elegant way to
      // keep track of the a bunch of unsent messages. Try a linked list or a circular
      // buffer instead.
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

  result_t sendPendingMsg(uint16_t address, uint8_t length, message_t *msg) {

    if (!transmitLock) {
      transmitLock = TRUE;
//      mydbg (DBG_USR1, "Sending message size %d\n",length);
//      uart_puts("send");
      if (call SendComm.send(address, msg, length) == SUCCESS) {
//        uart_puts("success\n");
        return SUCCESS;
      } else {
        transmitLock = FALSE;
        uart_puts("error, msg not sent\n");
        err("ERROR: Message NOT sent\n");
        signal Send.sendDone(msg, FAIL);
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
//    rxBusy = FALSE;
    initPendingMsgs();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uart_puts("start mqueue and AMControl\n");
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

  event void SendComm.sendDone(message_t *msg, result_t success) {

    TOS_Msg pendingMsg;
    uint16_t pendingAddress = NULL_NEIGHBOR_ID;
    uint8_t pendingLength = 0;

    if (transmitLock) {
      transmitLock = FALSE;
      if (getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
//      uart_puts("sendDone success\n");
    }
    signal Send.sendDone(msg, success);
//      uart_puts("sendDone fail\n");
  }


  command result_t Send.send(uint16_t address, message_t *msg, uint8_t length) {

    #ifdef myrianode
      PORTE |= _BV(PINE2);
      _delay_us(20);
      PORTE &= ~_BV(PINE2);
    #endif
    if (addPendingMsg(address, length, msg) == SUCCESS) {
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
        #ifdef myrianode
        PORTE |= _BV(PINE2);
        _delay_us(100);
        PORTE &= ~_BV(PINE2);
        #endif
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
    }
  }



  event message_t* ReceiveComm.receive(TOS_MsgPtr msg, void *payload, uint8_t len){
    signal Receive.receive(msg, payload, len);
    return msg;
  }

// Alternative receive version. It can be used as a starting point to implement
// a receive queue. This could be necessary for MAC layers capable of receiving
// many messages in a short time.
//
//  task void signalReceive() {
//    uint8_t len; void* payload; uint8_t totalLen;
//    payload = call Receive.getPayload(rxMsg, &len);
//    signal Receive.receive(rxMsg, payload, len);
//    totalLen = (sizeof(message_t) - call Send.maxPayloadLength()) + len;
//    call Mem.free(rxMsg, totalLen);
//    rxBusy = FALSE;
//  }
//
//
//  event message_t* ReceiveComm.receive(TOS_MsgPtr msg, void *payload, uint8_t len){
//    uint8_t totalLen;
//    if (rxBusy == FALSE) {
//      rxBusy = TRUE;
//      totalLen = (sizeof(message_t) - call Send.maxPayloadLength()) + len;
//      rxMsg = (message_t*) call Mem.malloc(totalLen);
//      memcpy(rxMsg, payload, len);
//      post signalReceive();
//    }
//    return msg;
//  }


  command void* Receive.getPayload(message_t *m, uint8_t *len) {
    return call ReceiveComm.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength(message_t *m) {
    return call ReceiveComm.payloadLength(m);
  }

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
}

