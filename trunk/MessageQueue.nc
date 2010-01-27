/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 44 $
 * * DATE
 * *    $LastChangedDate: 2007-05-30 09:29:52 -0500 (Wed, 30 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MessageQueue.nc 44 2007-05-30 14:29:52Z lmottola $
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
#define mydbg(m, f, s...) dbg(m, "[%s] " f, currentTime(), ## s)

module MessageQueue {
  provides {
    interface StdControl;
    interface SendMsg as Send;
    interface ReceiveMsg as Receive;
  }

  uses {
    interface SendMsg as SendComm;
    interface ReceiveMsg as ReceiveComm;
    interface NeighborSystem;
    interface Timer as SendMsgTimer;
   }
}

implementation {

  TOS_Msg tosMsg;

  TOS_Msg pendingMsgs[QUEUE_SIZE];
  uint16_t pendingAddresses[QUEUE_SIZE];
  uint8_t pendingLengths[QUEUE_SIZE];

  uint8_t nextPendingMsg;
  bool transmitLock = FALSE;

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
      if(call SendComm.send(address, length, &tosMsg) == SUCCESS) {
	return SUCCESS;
      } else {
	transmitLock = FALSE;
	mydbg(DBG_ERROR, "ERROR: Message NOT sent\n");
        return FAIL;
      }
    }
    else {
      return FAIL;
    }
  }
  
  command result_t StdControl.init() {
    initPendingMsgs();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
   return SUCCESS;
  }
  
  event result_t SendComm.sendDone(TOS_MsgPtr msg, result_t success) { 

   TOS_Msg pendingMsg;
   uint16_t pendingAddress;
   uint8_t pendingLength;

   if(transmitLock && msg == &tosMsg) {
     transmitLock = FALSE;
     if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
       sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
     }
     return signal Send.sendDone(msg, success);
   } 
   else {
     return signal Send.sendDone(msg, FAIL);
   }
  }
  
  command result_t Send.send(uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    
    if(addPendingMsg(address, length, msg) == SUCCESS) {
      // Initial Scattering
      call SendMsgTimer.start(TIMER_ONE_SHOT, rand() % 1024);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  event result_t SendMsgTimer.fired() {

    TOS_Msg pendingMsg;
    uint16_t pendingAddress;
    uint8_t pendingLength;
    
    if(transmitLock == FALSE) {
      if(getFirstPendingMsg(&pendingMsg, &pendingAddress, &pendingLength)) {
	sendPendingMsg(pendingAddress, pendingLength, &pendingMsg);
      }
    }
    
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveComm.receive(TOS_MsgPtr msg){
    return signal Receive.receive(msg);    
  }
}

