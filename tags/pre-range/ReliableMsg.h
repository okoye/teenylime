/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 4 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 10:22:42 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: paolinux78 $
 * *
 * *	$Id: ReliableMsg.h 4 2007-04-27 15:22:42Z paolinux78 $
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

#include "ReliableGenericComm.h"

typedef uint8_t msgId_t;

typedef struct Msg_device_id_t {
  TLTarget_t deviceId;
  msgId_t msgId;
  msgId_t lastMsgId;
} Msg_device_id_t;

#define TOSH_RELIABLE_DATA_LENGTH TOSH_DATA_LENGTH-(\
				    sizeof(Msg_device_id_t)*MAX_NEIGHBORS\
				    + sizeof(msgId_t)\
				    + sizeof(TLTarget_t)\
				    + sizeof(uint16_t)\
				    + sizeof(bool)\
				    + 2) // Accounts for CRC field

typedef struct ReliableMsg {
  Msg_device_id_t msgDeviceId[MAX_NEIGHBORS];
  msgId_t msgId;
  TLTarget_t target;
  uint16_t msgOrigin;
  bool reliable;
  int8_t data[TOSH_RELIABLE_DATA_LENGTH];    
} ReliableMsg;

uint8_t getMsgDeviceIndex(Msg_device_id_t messages[], TLTarget_t deviceId) {
  uint8_t i;
  
  for(i = 0; i < MAX_NEIGHBORS; i++) {
    if(messages[i].deviceId == deviceId) {
      return i;
    }
  }

  return MAX_NEIGHBORS;
}


void initMsgDevice(Msg_device_id_t messages[]) {
  uint8_t i;
  
  for(i = 0; i < MAX_NEIGHBORS; i++) {
    messages[i].deviceId = NULL_NEIGHBOR_ID;
    messages[i].msgId = NULL_MSG_ID;
    messages[i].lastMsgId = NULL_MSG_ID;
  }
}

uint8_t addNewMsgDeviceId(Msg_device_id_t messages[], TLTarget_t deviceId) {
  uint8_t i;
  uint8_t pos = getMsgDeviceIndex(messages, deviceId);

  if(pos != MAX_NEIGHBORS) {
    return pos;
  }
  
  for(i = 0; i < MAX_NEIGHBORS; i++) {
    if(messages[i].deviceId == NULL_NEIGHBOR_ID) {
      messages[i].deviceId = deviceId;
      return i;
    }
  }
  
  mydbg(DBG_USR3, "ERROR: no more space to allocate msgDeviceId\n");
  return MAX_NEIGHBORS;
}

bool isNullMsg(TOS_MsgPtr msg) {
  ReliableMsg *rMsg = (ReliableMsg *)msg->data;
  return (rMsg->msgId == NULL_MSG_ID);
}

TOS_Msg newNullMsg() {
  TOS_Msg nullMsg;
  ReliableMsg *rMsg = (ReliableMsg *)nullMsg.data;

  rMsg->msgId = NULL_MSG_ID;

  return nullMsg;
}

bool isReliableMsg(TOS_MsgPtr msg) {
  ReliableMsg *rMsg = (ReliableMsg *)msg->data;
  return (rMsg->reliable == 1);
}

bool msgcmp(TOS_MsgPtr msg1, TOS_MsgPtr msg2) {
  ReliableMsg *rm1 = (ReliableMsg *) msg1->data;
  ReliableMsg *rm2 = (ReliableMsg *) msg2->data;
  return (rm1->msgId == rm2->msgId) && (rm1->msgOrigin == rm2->msgOrigin);
}

ReliableMsg* TOS_to_Reliable(TOS_MsgPtr msg) {
  return (ReliableMsg *) msg->data;
}

void addReliability(TOS_MsgPtr msg) {

  int i;
  TOS_Msg tempMsg = *msg;
  ReliableMsg *rMsg = (ReliableMsg *) msg->data;

  for(i=0; i < TOSH_RELIABLE_DATA_LENGTH; i++) {
    rMsg->data[i] = tempMsg.data[i];
  }
}
    
void removeReliability(TOS_MsgPtr msg) {

  int i;
  TOS_Msg tempMsg = *msg;
  ReliableMsg *rMsg = (ReliableMsg *) tempMsg.data;

  for(i=0; i < TOSH_RELIABLE_DATA_LENGTH; i++) {
    msg->data[i] = rMsg->data[i];
  }
}

#ifndef mica2
char reliableMsgToString[100];

char* printReliableMsg(TOS_MsgPtr msg) {
  ReliableMsg *rMsg = TOS_to_Reliable(msg);
  if(rMsg->reliable == 1) {
    sprintf(reliableMsgToString, "Reliable");
  }
  else {
    sprintf(reliableMsgToString, "Unreliable");
  }

  sprintf(reliableMsgToString, "%s msg %d from %d to %d", 
	  reliableMsgToString, rMsg->msgId, rMsg->msgOrigin, rMsg->target);
  return reliableMsgToString;
}
#endif
