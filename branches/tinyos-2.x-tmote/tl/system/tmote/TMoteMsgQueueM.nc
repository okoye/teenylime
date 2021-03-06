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
 * *	$Id: TMoteMsgQueueM.nc 304 2008-03-04 10:35:11Z lmottola $
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

module TMoteMsgQueueM {

  provides {
    interface ReliableSend;
    interface Receive as Receive;
    interface Receive as Snoop;
  }

  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface AMPacket;
    interface AMSend;
    interface Receive as AMReceive;
    interface Receive as AMSnoop;
    interface PacketLink;
    interface LowPowerListening;
    
    interface TLDebug;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
   }
}

implementation {

  bool transmitLock = FALSE;
  bool transmitReliable = FALSE;

  struct pMsg {
    message_t msg;
    uint8_t len;
  };
  struct pMsg pendingMsgs[QUEUE_SIZE];
  uint8_t pendingMsgsNum = 0;

  event void Boot.booted() {
    call AMControl.start();
    call LowPowerListening.setLocalSleepInterval(LOCAL_LPL_INTERVAL);
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.start();
    } 
    call LowPowerListening.setLocalSleepInterval(LOCAL_LPL_INTERVAL);
  }

  event void AMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.stop();
    } 
  }

  /**
   * Adds the message passed as parameter to the pending msg list. 
   */
  void addPendingMsg(uint16_t address, uint8_t length, 
		     message_t* msg, bool reliable) {

    atomic {
      call AMPacket.setDestination(msg, address);
      
      if (reliable) {
	call PacketLink.setRetries(msg, MAX_MSG_RETRIES);
      } else {
	call PacketLink.setRetries(msg, 0);
      }

      if (address != TOS_BCAST_ADDR) {
	call LowPowerListening.setRxSleepInterval(msg, PREAMBLE_RETRIES *
						  REMOTE_LPL_INTERVAL);
      } else {
	call LowPowerListening.setRxSleepInterval(msg, REMOTE_LPL_INTERVAL);
      }
      
      if(pendingMsgsNum < QUEUE_SIZE) {
	pendingMsgs[pendingMsgsNum].msg = *msg;
	pendingMsgs[pendingMsgsNum].len = length;
	pendingMsgsNum++;	
      } else {
	call TLDebug.triggerErr(QUEUE_OVERFLOW);
      }
    }
  }

  /**
   * Retrieves the next message to send. If all messages have been
   * sent, FALSE is returned.
   */
  message_t* getFirstPendingMsg(uint8_t *length) {
   
    atomic {
      if(pendingMsgsNum > 0) {
	*length = pendingMsgs[0].len;     
	return &(pendingMsgs[0].msg);
      } else {
	return NULL;
      }
    }
  }
 
  void deleteFirstPendingMsg() {

    uint8_t i;
    atomic {

      if(pendingMsgsNum > 0) {
	
	pendingMsgsNum--;
	
	for(i=0; i < pendingMsgsNum; i++) {
	  pendingMsgs[i].msg = pendingMsgs[i+1].msg;
	  pendingMsgs[i].len = pendingMsgs[i+1].len;
	}
      }
    }
  } 

  
  task void send() {

    uint8_t len;
    message_t* currentMsg;
    error_t sendStatus;
    void* payload;

    atomic {
     
      if (!transmitLock) { 
 
	transmitLock = TRUE;
	currentMsg = getFirstPendingMsg(&len);
	
	if (currentMsg !=NULL) {
	  
	  if (call PacketLink.getRetries(currentMsg) > 0) {
	    transmitReliable = TRUE;
	  } else {
	    transmitReliable = FALSE;
	  }
	  
	  payload = call AMSend.getPayload(currentMsg);     
	  sendStatus = call AMSend.send(call AMPacket.destination(currentMsg), 
					currentMsg, len); 

	  if (sendStatus != SUCCESS) {
	    transmitLock = FALSE;
	  }

	  if (sendStatus == EBUSY) {
	    post send();
	  } else if (sendStatus == FAIL) {
	    call TLDebug.triggerErr(TRANSMISSION_FAILURE);
	  }

	} else {
	  transmitLock = FALSE;
	} 
      } else {
	post send();
      }
    } 
  }
  
  command error_t ReliableSend.send(uint16_t address, message_t* msg, 
				    uint8_t length, bool reliable) {
     
    atomic {
      addPendingMsg(address, length, msg, reliable);
      post send();
      return SUCCESS;
    }
  }
  
  event void AMSend.sendDone(message_t* msg, error_t success) {
    
    atomic {
      if (transmitReliable && !call PacketLink.wasDelivered(msg)) {
	signal ReliableSend.reliableSendFailed(call AMPacket.destination(msg),
					       msg);
      }

      deleteFirstPendingMsg();
      transmitLock = FALSE;
      post send();
    }
  }

  event message_t* AMReceive.receive(message_t* msg, 
				     void *payload, 
				     uint8_t len){
    atomic {
      signal Receive.receive(msg, payload, len); 
      return msg;
    }
  }

  command void* Receive.getPayload(message_t *m, uint8_t *len) {
    return call AMReceive.getPayload(m, len);
  }
  
  command uint8_t Receive.payloadLength(message_t *m) {
    return call AMReceive.payloadLength(m);
  }

  event message_t* AMSnoop.receive(message_t* msg, 
				   void *payload, 
				   uint8_t len){
    atomic {
      signal Snoop.receive(msg, payload, len); 
      return msg;
    }
  }

  command void* Snoop.getPayload(message_t *m, uint8_t *len) {
    return call AMSnoop.getPayload(m, len);
  }
  
  command uint8_t Snoop.payloadLength(message_t *m) {
    return call AMSnoop.payloadLength(m);
  }

#ifdef PRINTF_SUPPORT
  // Printf support
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}

