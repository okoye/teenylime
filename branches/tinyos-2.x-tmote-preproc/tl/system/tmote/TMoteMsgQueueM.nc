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
 * *	$Id: TMoteMsgQueueM.nc 894 2009-09-07 17:03:39Z sguna $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "TLDebug.h"
#include "TMoteTuning.h"

module TMoteMsgQueueM {

  provides {
    interface ReliableSend;
    interface Receive as Receive;
    interface Receive as Snoop;
    interface SplitControl as AMControl;
    interface QueueControl as TMoteQueueControl;
  }

  uses {
    interface Boot;
    interface SplitControl as SubAMControl;
    interface AMPacket;
    interface AMSend;
    interface Receive as AMReceive;
    interface Receive as AMSnoop;
#ifdef SECURE_TL
    interface AMSend as ReconfSend;
    interface Receive as ReconfReceive;
    interface Receive as ReconfSnoop;
#endif
    interface PacketLink;
    interface LowPowerListening;
    interface CC2420Config;
    interface CC2420Packet;
    interface Tuning;
    
    interface TLDebug;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
   }
}

implementation {

  // TODO: Can pack in a single byte
  bool transmitLock = FALSE;
  bool radioOn = FALSE;
  bool booting = TRUE;
  bool open = TRUE;

  struct pMsg {
    message_t msg;
    uint8_t len;
#ifdef SECURE_TL
    bool reconf;
#endif
  };
  struct pMsg pendingMsgs[TMOTE_QUEUE_SIZE];
  uint8_t pendingMsgsNum = 0;

  event void Boot.booted() {
    call SubAMControl.start();
  }

  command error_t AMControl.start() {
    return call SubAMControl.start();
  }

  command error_t AMControl.stop() {
    radioOn = FALSE;
    return call SubAMControl.stop();
  }

  event void SubAMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call SubAMControl.start();
    } else {
      if (booting) {
	call CC2420Config.setAddressRecognition(TRUE);
	call LowPowerListening.setLocalSleepInterval(LOCAL_LPL_INTERVAL);
	booting = FALSE;
      } else {
	signal AMControl.startDone(err);
      }
      radioOn = TRUE;
    }
  }

  event void SubAMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call SubAMControl.stop();
    } else {
      signal AMControl.stopDone(err);
    }
  }

  /**
   * Adds the message passed as parameter to the pending msg list. 
   */
#ifdef SECURE_TL
  void addPendingMsg(uint16_t address, uint8_t length, 
		     message_t* msg, bool reliable, bool reconf) {
#else
  void addPendingMsg(uint16_t address, uint8_t length, 
		     message_t* msg, bool reliable) {
#endif

    atomic {
      call AMPacket.setDestination(msg, address);
      
      if (reliable) {
	call PacketLink.setRetries(msg, call Tuning.get(KEY_MSG_RETRIES));
      } else {
	call PacketLink.setRetries(msg, 0);
      }

      call LowPowerListening.setRxSleepInterval(msg, 
						call Tuning.get(KEY_REMOTE_LPL_SLEEP));
      call CC2420Packet.setPower(msg, call Tuning.get(KEY_TX_POWER));
      
      if(pendingMsgsNum < TMOTE_QUEUE_SIZE) {
	memcpy(&(pendingMsgs[pendingMsgsNum].msg), msg, sizeof(message_t));
	pendingMsgs[pendingMsgsNum].len = length;
#ifdef SECURE_TL
    pendingMsgs[pendingMsgsNum].reconf = reconf;
#endif
#ifdef PRINTF_SUPPORT
/* 	printf("L%d",length); */
#endif
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

#ifdef SECURE_TL
  bool isFirstPendingMsgReconf() {
    atomic {
      return (pendingMsgs[0].reconf & FLAG_SECURE_RECONF) != 0;
    }
  }
#endif
 
 
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
#ifdef SECURE_TL
    bool currentReconf;
#endif

    atomic {
     
      if (!transmitLock
	  && radioOn) { // Keeps messages in the queue when the radio is off 
 
	transmitLock = TRUE;
#ifdef SECURE_TL
    currentReconf = isFirstPendingMsgReconf();
#endif
	currentMsg = getFirstPendingMsg(&len);
	
	if (currentMsg !=NULL) {

#ifdef SECURE_TL
      if (currentReconf)
	    sendStatus = call ReconfSend.send(
                call AMPacket.destination(currentMsg), currentMsg, len);
      else
#endif
	  sendStatus = call AMSend.send(call AMPacket.destination(currentMsg), 
					currentMsg, len);
	  
	  if (sendStatus != SUCCESS) {
	    transmitLock = FALSE;
	  }

	  if (sendStatus == EBUSY) {
	    post send();
	  } else if (sendStatus == FAIL) {
#ifdef PRINTF_SUPPORT
/* 	    printf("TRF"); */
#endif	    
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
  
#ifdef SECURE_TL
  command error_t ReliableSend.send(uint16_t address, message_t* msg, 
				    uint8_t length, bool reliable, bool reconf) {
#else
  command error_t ReliableSend.send(uint16_t address, message_t* msg, 
				    uint8_t length, bool reliable) {
#endif     

    atomic {
      if (open) {
#ifdef SECURE_TL
	addPendingMsg(address, length, msg, reliable, reconf);
#else
	addPendingMsg(address, length, msg, reliable);
#endif
	post send();
	return SUCCESS;
      } else {
	return FAIL;
      }
    }
  }
 
  void genericSendDone(message_t *msg, error_t success) {
    bool reliableSendFailed = FALSE;

    atomic {
      if (call PacketLink.getRetries(msg) > 0 
	  && !call PacketLink.wasDelivered(msg)) {
	reliableSendFailed = TRUE;
      }
      signal ReliableSend.sendDone(msg, success, reliableSendFailed);

      deleteFirstPendingMsg();
      transmitLock = FALSE;
      post send();
    }
  }
  
  event void AMSend.sendDone(message_t* msg, error_t success) {
    genericSendDone(msg, success);
  }

  command error_t TMoteQueueControl.close() {
    open = FALSE;
    return SUCCESS;
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

  command error_t ReliableSend.cancel(message_t* msg) {
    return SUCCESS;
  }

  command uint8_t ReliableSend.maxPayloadLength() {
    return call AMSend.maxPayloadLength();
  }  

  command void* ReliableSend.getPayload(message_t* msg) {
    return call AMSend.getPayload(msg);    
  }

  event void CC2420Config.syncDone(error_t err) {}

  event void Tuning.setDone(uint8_t key, uint16_t value) {}

#ifdef PRINTF_SUPPORT
  // Printf support
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif

#ifdef SECURE_TL
  event void ReconfSend.sendDone(message_t *msg, error_t success) {
    genericSendDone(msg, success);
  }

  event message_t* ReconfReceive.receive(message_t* msg, void *payload, 
          uint8_t len) {
    atomic {
      signal Receive.receive(msg, payload, len); 
      return msg;
    }
  }

  event message_t* ReconfSnoop.receive(message_t* msg, void *payload, 
          uint8_t len){
    atomic {
      signal Snoop.receive(msg, payload, len); 
      return msg;
    }
  }
#endif
}

