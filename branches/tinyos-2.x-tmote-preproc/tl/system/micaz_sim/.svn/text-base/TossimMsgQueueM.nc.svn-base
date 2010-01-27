/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 792 $
 * * DATE
 * *    $LastChangedDate: 2009-05-01 15:17:13 +0200 (Fri, 01 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TossimMsgQueueM.nc 792 2009-05-01 13:17:13Z lmottola $
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

#include "TossimStackConf.h"
#include "TLDebug.h"

module TossimMsgQueueM {

  provides {
    interface ReliableSend;
    interface Receive as Receive;
    interface QueueControl as TossimQueueControl;
  }

  uses {
    interface Boot;
    interface SplitControl as SubAMControl;
    interface AMPacket;
    interface AMSend;
    interface Receive as AMReceive;
    
    interface TLDebug;
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
  };
  struct pMsg pendingMsgs[TOSSIM_QUEUE_SIZE];
  uint8_t pendingMsgsNum = 0;

  event void Boot.booted() {
    dbg("TL", "starting radio\n");
    call SubAMControl.start();
  }

  event void SubAMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call SubAMControl.start();
    } else {
      if (booting) {
	booting = FALSE;
      } 
      dbg("TL", "radio started\n");
      radioOn = TRUE;
    }
  }

  event void SubAMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call SubAMControl.stop();
    } 
  }

  /**
   * Adds the message passed as parameter to the pending msg list. 
   */
  void addPendingMsg(uint16_t address, uint8_t length, 
		     message_t* msg, bool reliable) {

    atomic {
      call AMPacket.setDestination(msg, address);
      
      if(pendingMsgsNum < TOSSIM_QUEUE_SIZE) {
	memcpy(&(pendingMsgs[pendingMsgsNum].msg), msg, sizeof(message_t));
	pendingMsgs[pendingMsgsNum].len = length;
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

    atomic {

      if (transmitLock || !radioOn) {
        // Keeps messages in the queue when the radio is off 
        post send();
        return;
      }

      transmitLock = TRUE;
      currentMsg = getFirstPendingMsg(&len);

      if (currentMsg == NULL) {
        transmitLock = FALSE;
        return;
      }

      dbg("TL", "low level send %d\n", call AMPacket.destination(currentMsg));
      sendStatus = call AMSend.send(call AMPacket.destination(currentMsg),
              currentMsg, len);

      if (sendStatus != SUCCESS) {
          dbg("TL", "low level send failed\n");
          transmitLock = FALSE;
      }

      if (sendStatus == EBUSY) 
          post send();
      else if (sendStatus == FAIL) 
          call TLDebug.triggerErr(TRANSMISSION_FAILURE);

    } 
  }
  
  command error_t ReliableSend.send(uint16_t address, message_t* msg, 
				    uint8_t length, bool reliable) {
     
    atomic {
      if (open) {
	addPendingMsg(address, length, msg, reliable);
	post send();
	return SUCCESS;
      } else {
	return FAIL;
      }
    }
  }
  
  event void AMSend.sendDone(message_t* msg, error_t success) {
    
    bool reliableSendFailed = FALSE;
    dbg("TL", "send done %d %d\n", success, SUCCESS);

    atomic {
      signal ReliableSend.sendDone(msg, success, reliableSendFailed);

      deleteFirstPendingMsg();
      transmitLock = FALSE;
      post send();
    }
  }

  command error_t TossimQueueControl.close() {
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

  command error_t ReliableSend.cancel(message_t* msg) {
    return SUCCESS;
  }

  command uint8_t ReliableSend.maxPayloadLength() {
    return call AMSend.maxPayloadLength();
  }  

  command void* ReliableSend.getPayload(message_t* msg) {
    return call AMSend.getPayload(msg);    
  }
}

