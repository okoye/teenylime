/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 198 $
 * * DATE
 * *    $LastChangedDate: 2007-11-17 09:28:18 -0600 (Sat, 17 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MicazTossimMsgQueueM.nc 198 2007-11-17 15:28:18Z lmottola $
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

#include "TLDebug.h"

module MicazTossimMsgQueueM {

  provides {
    interface ReliableSend as Send;
    interface Receive as Receive;
  }

  uses {
    interface Boot;
    interface Timer<TMilli> as SendMsgTimer;
    interface SplitControl as AMControl;
    interface AMPacket;
    interface AMSend as SendComm;
    interface Receive as ReceiveComm;
    interface Random;
    
    interface TLDebug;
   }
}

implementation {

  message_t tosMsg;

  message_t pendingMsgs[QUEUE_SIZE];
  uint16_t pendingAddresses[QUEUE_SIZE];
  uint8_t pendingLengths[QUEUE_SIZE];

  uint8_t nextPendingMsg = 0;
  bool transmitLock = FALSE;

  event void Boot.booted() {
    call AMControl.start();
  }

  /**
   * Adds the message passed as parameter to the pending msg list. 
   */
  error_t addPendingMsg(uint16_t address, uint8_t length, message_t* msg) {
    if(nextPendingMsg < QUEUE_SIZE) {
      pendingMsgs[nextPendingMsg] = *msg;
      pendingAddresses[nextPendingMsg] = address;
      pendingLengths[nextPendingMsg] = length;
      nextPendingMsg++;

      return SUCCESS;
    } else {
      dbg("DBG_ERROR", "ERROR: No space left in the pending message list\n");
      call TLDebug.triggerErr(QUEUE_OVERFLOW);
      return FAIL;
    }
  }

  /**
   * Returns the next message to send. If all messages have been
   * sent, FALSE is returned.
   */
  bool getFirstPendingMsg(message_t *msg, uint16_t *address, uint8_t *length) {
   
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

  error_t sendPendingMsg(uint16_t address, uint8_t length, message_t* msg) {

    if(!transmitLock) {
      transmitLock = TRUE;
      tosMsg = *msg;
      dbg ("DBG_USR1", "Sending message size %d\n",length);
      if(call SendComm.send(address, &tosMsg, length) == SUCCESS) {
/* 	printf ("Sent msg size: %u\n",sizeof(TupleMsg)); */
/* 	call PrintfFlush.flush(); */
        return SUCCESS;
      } else {
        transmitLock = FALSE;
        dbg("DBG_ERROR", "ERROR: Message NOT sent\n");
	call TLDebug.triggerErr(TRANSMISSION_FAILURE);
        return FAIL;
      }
    }
    else {
      return FAIL;
    }
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.start();
    } else {
      // TODO: signal higher layer
    }
  }

  event void AMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.stop();
    } else {
      // TODO: signal higher layer
    }
  }

  command error_t Send.send(uint16_t address, message_t* msg, 
			     uint8_t length, bool reliable) {

    if(addPendingMsg(address, length, msg) == SUCCESS) {
      // Initial Scattering      
      call SendMsgTimer.startOneShot(call Random.rand16() % DELAY_UPPER_BOUND);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  event void SendComm.sendDone(message_t* msg, error_t success) {

    message_t pendingMsg;
    uint16_t pendingAddress = NULL_NEIGHBOR_ID;
    uint8_t pendingLength = 0;

    if(transmitLock && msg == &tosMsg) {
      transmitLock = FALSE;
      if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
    }
  }

  event void SendMsgTimer.fired() {
    
    message_t pendingMsg;
    uint16_t pendingAddress = NULL_NEIGHBOR_ID;
    uint8_t pendingLength = 0;

    if(!transmitLock) {
      if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
        sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
    }
  }

  event message_t* ReceiveComm.receive(message_t* msg, void *payload, 
				       uint8_t len){
    
    return signal Receive.receive(msg, payload, len); 
  }

  command void* Receive.getPayload(message_t *m, uint8_t *len) {
    return call ReceiveComm.getPayload(m, len);
  }
  
  command uint8_t Receive.payloadLength(message_t *m) {
    return call ReceiveComm.payloadLength(m);
  }
}

