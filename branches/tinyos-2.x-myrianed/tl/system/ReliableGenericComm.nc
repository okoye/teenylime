/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 188 $
 * * DATE
 * *    $LastChangedDate: 2007-11-04 15:26:29 -0600 (Sun, 04 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: ReliableGenericComm.nc 188 2007-11-04 21:26:29Z bronwasser $
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

#include "ReliableGenericComm.h"
#include "ReliableMsg.h"

module ReliableGenericComm {
  provides {
    interface StdControl;
    interface Init;
    interface ReliableSend;
    interface Receive as ReliableReceive;
  }

  uses {
    interface AMSend as Send;
    interface Receive;
    interface Packet;
    interface Init as CommInit;
    interface Timer<TMilli> as OneShotTimer;
    interface Timer<TMilli> as PeriodicTimer;
    interface Leds;
  }
}

implementation {

  /**
   * Component global variables
   */
  bool beaconNeeded = FALSE; // Used to avoid sending beacon
  uint32_t globalMsgCounter = 0; // message counter
  bool active = FALSE; // Radio status
  uint32_t localTime = 0; // Local (logical) time


  /*********************************
   *           BUFFER
   *
   * It contains the ReliableMsg and the recipients which should receive
   * it.
   *
   * Available Methods:
   *
   * - void initializeBuffer();
   * - MsgData* getMessage(msgId_t msgId);
   * - MsgData* addMessage(ReliableMsg* rMsg);
   * - void removeDeliveredMessages();
   * - void resendUndeliveredMessages();
   * - bool messageSent(ReliableMsg* rMsg);
   *
   **********************************/

  typedef struct MsgData {
    TOS_Msg msg;
    uint16_t recipients[MAX_NEIGHBORS];
    bool sent;
    bool justSent; // TODO: this is an hack to prevent a message to
       // be resend immediately (still to implement)
  } MsgData;
  MsgData msgBuffer[BUFFER_SIZE];

void print_data_size();

  /**
   * Prototypes
   *
   * These functions are defined later but are used here
   */
  result_t addNotDeliveredMessage(uint16_t deviceId, MsgData* msgData);
  result_t sendReliableMsg(TOS_MsgPtr msg);
  TOS_MsgPtr addUnorderderMessage(TOS_MsgPtr msg);
  void printUnorderedMessages();

#ifndef mica2
  void printMsgBuffer() {
    uint8_t i, j;
    char debugString[1024];

    for(i = 0; i < BUFFER_SIZE; i++) {
      if(!isNullMsg(&(msgBuffer[i].msg))) {
        sprintf(debugString, "Message %s to be delivered to { ", printReliableMsg(&(msgBuffer[i].msg)));
        for(j = 0; j < MAX_NEIGHBORS; j++) {
          if(msgBuffer[i].recipients[j] != NULL_NEIGHBOR_ID) {
            sprintf(debugString, "%s%d ", debugString, msgBuffer[i].recipients[j]);
          }
        }
        mydbg(DBG_USR3,"Message[%d] -> %s}\n", i, debugString);
      }
    }
  }
#endif

  /**
   * It initiliazes the buffer. It put a null message in every cell
   * and fill the recipient list with TOS_LOCAL_ADDRESS
   */
  void initializeBuffer() {
    uint8_t i,j;
    for(i = 0; i < BUFFER_SIZE; i++) {
      // TODO: This isn't necessary. We're copying a lot of bytes for nothing here.
      msgBuffer[i].msg = newNullMsg();
      for(j = 0; j < MAX_NEIGHBORS; j++) {
        msgBuffer[i].recipients[j] = NULL_NEIGHBOR_ID;
      }
    }
  }

  /**
   * It return a pointer to the cell hosting the message specified in
   * the parameter list. If none is found, NULL is returned.
   */
  MsgData* getMessage(TOS_MsgPtr msg) {
    uint8_t i;

    for(i = 0; i < BUFFER_SIZE; i++) {
      if(msgcmp(&(msgBuffer[i].msg), msg)) {
        return &(msgBuffer[i]);
      }
    }

    return NULL;
  }

  /**
   * It adds a message into the buffer. If reliable is TRUE, the
   * recipient list is filled according to the target specified in the
   * message itself. It returns the pointer to the MsgData
   * structure. A message is inserted only once: if the message is
   * already in the buffer, it returns the pointer to its location. If
   * no space left, NULL is returned.
   */
  MsgData* addMessage(TOS_MsgPtr msg) {
    uint8_t i, j;

    MsgData* result = getMessage(msg);
    if(result != NULL) {
      return result;
    } else {
      for(i = 0; i < BUFFER_SIZE; i++) {
        if(isNullMsg(&(msgBuffer[i].msg))) {
          msgBuffer[i].msg = *msg;
          msgBuffer[i].sent = TRUE;
          if(isReliableMsg(msg)) {
            ReliableMsg *rMsg = TOS_to_Reliable(msg);
            for(j = 0; j < MAX_NEIGHBORS; j++) {
              msgBuffer[i].recipients[j] = rMsg->msgDeviceId[j].deviceId;
              if (rMsg->msgDeviceId[j].deviceId != NULL_NEIGHBOR_ID) {
                addNotDeliveredMessage(rMsg->msgDeviceId[j].deviceId,
                     &(msgBuffer[i]));
              }
            }
          }
          return &(msgBuffer[i]);
        }
      }
    }

    // No available space left
    mydbg(DBG_ERROR, "ERROR: Buffer is full. No more space left\n");
    return NULL;
  }

  /**
   * This function checks the buffer and remove all the message that
   * are considered delivered. This includes all the unreliable
   * messages and the reliable messages which have been acknowledged.
   */
  void removeDeliveredMessages() {
    // A message is considered delivered when it
    // has no more recipients and it has been sent at least once
    uint8_t i, j;
    bool toRemove;

    for(i = 0; i < BUFFER_SIZE; i++) {
      if(!isNullMsg(&(msgBuffer[i].msg))) {
        toRemove = msgBuffer[i].sent;
        for(j = 0; j < MAX_NEIGHBORS; j++) {
          if(msgBuffer[i].recipients[j] != NULL_NEIGHBOR_ID) {
            toRemove = FALSE;
          }
        }
        if(toRemove) {
          if(isReliableMsg(&(msgBuffer[i].msg))) {
            signal ReliableSend.deliveredMessage(&(msgBuffer[i].msg));
          }
          // TODO: Please invent something better than copying
          // hundred zeroes just to clear a msg...
          msgBuffer[i].msg = newNullMsg();
        }
      }
    }
  }


  /********************************************
   * Pending Message
   *
   * This structure hosts the list of messages which are to be
   * sent. It contains pointer to the buffer.
   *
   * Available Methods
   *
   * - void initPendingMsgs();
   * - result_t addPendingMsg(ReliableMsg *rMsg);
   * - MsgData* getFirstPendingMsg();
   * - result_t sendReliableMsg(ReliableMsg* rMsg);
   *
   */
  TOS_Msg beaconMsg;


  // Asymmetric neighbors
  typedef struct AsymmetricNeighbor {
    uint16_t deviceId;
    uint32_t lastSeen;
  } AsymmetricNeighbor;

  AsymmetricNeighbor asymmetricNeighbors[MAX_NEIGHBORS];

   /**
   * Returns a null asymmetric neighbor
   *
   */

  AsymmetricNeighbor newNullAsymmetricNeighbor() {
    AsymmetricNeighbor neighbor;

    neighbor.deviceId = NULL_NEIGHBOR_ID;
    neighbor.lastSeen = 0;

    return neighbor;
  }

  /**
   * Checks whether neighbor points to a null asymmetric neighbor
   *
   */

  bool isNullAsymmetricNeighbor(AsymmetricNeighbor* neighbor) {
    return (neighbor->deviceId == NULL_NEIGHBOR_ID);
  }


  /**
   * Initialize neighbor list
   *
   */

  void initializeAsymmetricNeighbors() {
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      asymmetricNeighbors[i] = newNullAsymmetricNeighbor();
    }
  }


  AsymmetricNeighbor* getAsymmetricNeighbor(uint16_t deviceId) {
    uint8_t i;

    for(i=0; i < MAX_NEIGHBORS; i++) {
      if(asymmetricNeighbors[i].deviceId == deviceId) {
        return &(asymmetricNeighbors[i]);
      }
    }

    return NULL;
  }


  AsymmetricNeighbor* addAsymmetricNeighbor(uint16_t deviceId) {
    AsymmetricNeighbor* neighbor;

    neighbor = getAsymmetricNeighbor(deviceId);

    if(neighbor != NULL) {
      neighbor->lastSeen = localTime;
      return neighbor;
    }
    else {
      uint8_t i = 0;

      while(i < MAX_NEIGHBORS) {
        if(asymmetricNeighbors[i].deviceId == NULL_NEIGHBOR_ID) {
          asymmetricNeighbors[i].deviceId = deviceId;
          asymmetricNeighbors[i].lastSeen = localTime;
          mydbg(DBG_USR1,"Adding new asymmetric neighbor %d\n", deviceId);
          return &(asymmetricNeighbors[i]);
        }
        i++;
      }
      mydbg(DBG_ERROR, "ERROR: No space left to store other neighbors");
      return NULL;
    }
  }

  void pruneAsymmetricNeighbors() {
    uint8_t i;

    for(i=0; i < MAX_NEIGHBORS; i++) {
      if (!isNullAsymmetricNeighbor(&(asymmetricNeighbors[i]))
           && localTime > asymmetricNeighbors[i].lastSeen + NEIGHBOR_UPDATE_LOST) {
        mydbg(DBG_USR1, "Asymmetric neighbor %d removed\n",
           asymmetricNeighbors[i].deviceId);
        asymmetricNeighbors[i] = newNullAsymmetricNeighbor();
      }
    }
  }

  /****************************************
   *
   * NEIGHBOR STRUCTURE
   *
   */

  typedef struct NeighborData {
    uint16_t deviceId;
    msgId_t msgCounter;
    msgId_t lastMsgReceived;
    MsgData* notDeliveredMessage[BUFFER_SIZE];
  } NeighborData;
  NeighborData symmetricNeighbors[MAX_NEIGHBORS];


   /**
   * Returns a null neighbor
   *
   */

  NeighborData newNullNeighbor() {
    NeighborData neighbor;

    neighbor.deviceId = NULL_NEIGHBOR_ID;
    neighbor.msgCounter = NULL_MSG_ID;
    neighbor.lastMsgReceived = NULL_MSG_ID;

    return neighbor;
  }

  /**
   * Checks whether neighbor points to a null neighbor
   *
   */

  bool isNullNeighbor(NeighborData* neighbor) {
    return (neighbor->deviceId == NULL_NEIGHBOR_ID);
  }


  /**
   * Prints the content of the neighbor data
   *
   */
#ifndef mica2
  void printNeighbors() {
    uint8_t i, j;
    char debugString[1024];
    ReliableMsg *rMsg;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      if(!isNullNeighbor(&(symmetricNeighbors[i]))) {
        sprintf(debugString, "Neighbor %d, counter %d, lastMsgReceived %d, NotDeliveredMsgs ={ ", symmetricNeighbors[i].deviceId,  symmetricNeighbors[i].msgCounter,  symmetricNeighbors[i].lastMsgReceived);
        for(j= 0; j < BUFFER_SIZE; j++) {
          if(symmetricNeighbors[i].notDeliveredMessage[j] != NULL) {
            rMsg = TOS_to_Reliable(&(symmetricNeighbors[i].notDeliveredMessage[j]->msg));
            sprintf(debugString, "%s%d ", debugString, rMsg->msgId);
          }
        }
        sprintf(debugString, "%s}\n", debugString);
        mydbg(DBG_USR3, "neighbors[%d] -> %s", i, debugString);
      }
      else {
        sprintf(debugString, "Null Neighbor\n");
      }
    }
  }
#endif


  /**
   * Initialize neighbor list
   *
   */

  void initializeNeighbors() {
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      symmetricNeighbors[i] = newNullNeighbor();
    }
  }

  NeighborData* getNeighbor(uint16_t deviceId) {
    uint8_t i;

    for(i=0; i < MAX_NEIGHBORS; i++) {
      if(symmetricNeighbors[i].deviceId == deviceId) {
        return &(symmetricNeighbors[i]);
      }
    }

    return NULL;
  }


  NeighborData* addNeighbor(uint16_t deviceId) {
    NeighborData* neighbor;

    neighbor = getNeighbor(deviceId);

    if(neighbor != NULL) {
      return neighbor;
    }
    else {
      uint8_t i = 0, j;

      while(i < MAX_NEIGHBORS) {
        if(symmetricNeighbors[i].deviceId == NULL_NEIGHBOR_ID) {
          symmetricNeighbors[i].deviceId = deviceId;
          symmetricNeighbors[i].msgCounter = 0;
          symmetricNeighbors[i].lastMsgReceived = 0;
          for(j=0; j < BUFFER_SIZE; j++) {
            symmetricNeighbors[i].notDeliveredMessage[j] = NULL;
          }
          return &(symmetricNeighbors[i]);
        }
        i++;
      }

      mydbg(DBG_ERROR, "ERROR: No space left to store other neighbors");
      return NULL;
    }
  }


  uint8_t addRecipients(ReliableMsg* rMsg) {
    uint8_t i;
    uint8_t numRecipients = 0;

    if(rMsg->target != TOS_BCAST_ADDR) {
      NeighborData* neighborData = addNeighbor(rMsg->target);
      if(neighborData != NULL) {
        rMsg->msgDeviceId[0].deviceId = rMsg->target;
        rMsg->msgDeviceId[0].msgId = ++(neighborData->msgCounter);
        numRecipients++;
        for(i = 1; i < MAX_NEIGHBORS; i++) {
          rMsg->msgDeviceId[i].deviceId = NULL_NEIGHBOR_ID;
          rMsg->msgDeviceId[i].msgId = NULL_MSG_ID;
        }
      }
    }
    else {
      for(i = 0; i < MAX_NEIGHBORS; i++) {
        if(symmetricNeighbors[i].deviceId != NULL_NEIGHBOR_ID) {
          rMsg->msgDeviceId[i].msgId = ++(symmetricNeighbors[i].msgCounter);
          numRecipients++;
        }
        else {
          rMsg->msgDeviceId[i].msgId = NULL_MSG_ID;
        }
        rMsg->msgDeviceId[i].deviceId = symmetricNeighbors[i].deviceId;
      }
    }

    return numRecipients;

  }

  void addNeighborList(ReliableMsg* rMsg) {
    uint8_t i, pos;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      if(isNullNeighbor(&(symmetricNeighbors[i])) == FALSE) {
        pos = getMsgDeviceIndex(rMsg->msgDeviceId, symmetricNeighbors[i].deviceId);
        if(pos == MAX_NEIGHBORS) {
          pos =  addNewMsgDeviceId(rMsg->msgDeviceId, symmetricNeighbors[i].deviceId);
        }
        rMsg->msgDeviceId[pos].lastMsgId = symmetricNeighbors[i].lastMsgReceived;
      }
    }

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      if(!isNullAsymmetricNeighbor(&(asymmetricNeighbors[i])) && getNeighbor(asymmetricNeighbors[i].deviceId) == NULL) {
        pos = getMsgDeviceIndex(rMsg->msgDeviceId, asymmetricNeighbors[i].deviceId);
        if(pos == MAX_NEIGHBORS) {
         pos =  addNewMsgDeviceId(rMsg->msgDeviceId, asymmetricNeighbors[i].deviceId);
        }
        rMsg->msgDeviceId[pos].lastMsgId = NULL_MSG_ID;
      }
    }
  }


  void updateSymmetricNeighbors(Msg_device_id_t messages[], uint16_t recipient) {
    uint8_t i, j, z;
    NeighborData* neighbor;
    MsgData* msgData;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      if(messages[i].deviceId == TOS_LOCAL_ADDRESS) {
        addNeighbor(recipient);
        return;
      }
    }

    // Asymmetric link: remove existing symmetric neighbor (if any)
    neighbor = getNeighbor(recipient);
    if(neighbor != NULL) {
      // Recipient is no more a symmetric link
      for(j = 0; j < BUFFER_SIZE; j++) {
        msgData = neighbor->notDeliveredMessage[j];
        neighbor->notDeliveredMessage[j] = NULL;
        if(msgData != NULL) {
          for(z=0; z < MAX_NEIGHBORS; z++) {
            if(msgData->recipients[z] == neighbor->deviceId) {
              msgData->recipients[z] = NULL_NEIGHBOR_ID;
            }
          }
        }
      }
      mydbg(DBG_USR3, "Removing neighbor %d as it does not exist any longer\n", neighbor->deviceId);
      *neighbor = newNullNeighbor();
    }
  }

  result_t addNotDeliveredMessage(uint16_t deviceId, MsgData* msgData) {
    uint8_t i = 0;

    NeighborData* neighbor = getNeighbor(deviceId);

    // Since this procedure is called only *after* a message has been
    // created if neighbor does not exist, it is an error

    while(i < BUFFER_SIZE && neighbor->notDeliveredMessage[i] != NULL) {
      i++;
    }
    if(i < BUFFER_SIZE) {
      neighbor->notDeliveredMessage[i] = msgData;
      return SUCCESS;
    }
    else {
      mydbg(DBG_ERROR,"ERROR: No space left for additional undelivered messages");
      return FAIL;
    }
  }

  /**
   * It removes all the unicast (broadcast) messages in the buffer
   * whose id is less than lastUnicastMsgId (lastBroadcastMsgId).
   */
  void pruneRecipient(uint16_t recipient, msgId_t lastMsgId) {
    uint8_t i,j,pos;
    NeighborData* neighbor = getNeighbor(recipient);
    msgId_t msgId;
    MsgData* msgData;

    if(neighbor != NULL) {
      for(i = 0; i < BUFFER_SIZE; i++) {
        msgData = neighbor->notDeliveredMessage[i];
        if(msgData != NULL) {
          ReliableMsg *rMsg = TOS_to_Reliable(&(msgData->msg));
          pos = getMsgDeviceIndex(rMsg->msgDeviceId, recipient);
          msgId = rMsg->msgDeviceId[pos].msgId;
          if(msgId <= lastMsgId) {
            for(j=0; j < MAX_NEIGHBORS; j++) {
              if(msgData->recipients[j] == recipient) {
                msgData->recipients[j] = NULL_NEIGHBOR_ID;
              }
            }
            neighbor->notDeliveredMessage[i] = NULL;
          }
        }
      }
    }
    else {
      // Neighbor unknown.
    }
  }

  void removeOldNeighbors() {
    MsgData* msgData;
    uint8_t i,j,z;
    bool toRemove;

    for(i = 0; i < MAX_NEIGHBORS; i++) {
      if(!isNullNeighbor(&(symmetricNeighbors[i]))) {
        toRemove = TRUE;

        for(j=0; j < MAX_NEIGHBORS && toRemove; j++) {
          if(asymmetricNeighbors[j].deviceId == symmetricNeighbors[i].deviceId) {
            // TODO: don't understand this.
            // If the neighbor appears in the assym list, we don't remove?
            // Why don't we just respond to the event that a neighbor is pruned from
            // the assymetric neighbor list instead of searching here?
            toRemove = FALSE;
          }
        }

        if(toRemove) {
          for(j = 0; j < BUFFER_SIZE; j++) {
            msgData = symmetricNeighbors[i].notDeliveredMessage[j];
            symmetricNeighbors[i].notDeliveredMessage[j] = NULL;
            if(msgData != NULL) {
              for(z=0; z < MAX_NEIGHBORS; z++) {
                if(msgData->recipients[z] == symmetricNeighbors[i].deviceId) {
                  msgData->recipients[z] = NULL_NEIGHBOR_ID;
                }
              }
            }
          }
          mydbg(DBG_USR3, "Removing neighbor %d as it does not exist any longer\n", symmetricNeighbors[i].deviceId);
          symmetricNeighbors[i] = newNullNeighbor();
        }
      }
    }
  }


  /**
   * Once a new message is received, we update the list of the
   * received messages and we also check which is the last message
   * received from us.
   */
  result_t messageReceived(TOS_MsgPtr msg) {
    uint8_t pos;
    msgId_t lastMsgRcv;
    msgId_t myOwnMsgId;
    ReliableMsg *rMsg = (ReliableMsg *) msg->data;

    // check messages...
    pos = getMsgDeviceIndex(rMsg->msgDeviceId, TOS_LOCAL_ADDRESS);
    if(pos == MAX_NEIGHBORS) {
      lastMsgRcv = NULL_MSG_ID;
    }
    else {
      lastMsgRcv = rMsg->msgDeviceId[pos].lastMsgId;
    }
    pruneRecipient(rMsg->msgOrigin, lastMsgRcv);
    updateSymmetricNeighbors(rMsg->msgDeviceId, rMsg->msgOrigin);

    if(isReliableMsg(msg)) {
      pos = getMsgDeviceIndex(rMsg->msgDeviceId, TOS_LOCAL_ADDRESS);
      if(pos == MAX_NEIGHBORS) {
        myOwnMsgId = NULL_MSG_ID;
      }
      else {
        myOwnMsgId = rMsg->msgDeviceId[pos].msgId;
      }

      if(myOwnMsgId != NULL_MSG_ID) {
        NeighborData *neighbor = addNeighbor(rMsg->msgOrigin);

        // Update our received message list (only if the message is meant to us)
        if(myOwnMsgId ==  neighbor->lastMsgReceived + 1) {
          neighbor->lastMsgReceived = myOwnMsgId;
          return SUCCESS;
        }
        else if(myOwnMsgId > neighbor->lastMsgReceived + 1) {
          addUnorderderMessage(msg);
          return FAIL;
        }
        else {
          // Message already delivered
          return FAIL;
        }
      }
      else {
        // Message not for me
        return FAIL;
      }
    }
    else {
      // Message was not reliable, so I pass it to DistributedTL
      return SUCCESS;
    }
  }

  TOS_MsgPtr getLowestUndeliveredMessage(NeighborData *neighbor) {
    uint8_t i;
    ReliableMsg *result = NULL;
    TOS_MsgPtr tosResult = NULL;
    ReliableMsg* rMsg;

    for(i = 0; i < BUFFER_SIZE; i++) {
      if(neighbor->notDeliveredMessage[i] != NULL && neighbor->notDeliveredMessage[i]->sent) {
        rMsg = (ReliableMsg *)neighbor->notDeliveredMessage[i]->msg.data;
        if(result == NULL || result->msgId > rMsg->msgId) {
          // Note that here I use the universal msg id and not the
          // neighbor specific because anyway the order relations are
          // guaranteed
          result = rMsg;
          tosResult = &(neighbor->notDeliveredMessage[i]->msg);
        }
      }
    }

    return tosResult;
  }


  /**
   * This functions checks the buffer to see if there are still some
   * messages which have not been acknowledged and in case resend it.
   */
  void resendUndeliveredMessages() {
    msgId_t msgSent[BUFFER_SIZE];
    uint8_t i, j;
    uint8_t cont = 0;
    bool toSend;
    ReliableMsg* rMsg = NULL;
    TOS_MsgPtr msg;

    for(i = 0; i < BUFFER_SIZE; i++) {
      msgSent[i] = NULL_MSG_ID;
    }

    for(j = 0; j < MAX_NEIGHBORS; j++) {
      if(!isNullNeighbor(&(symmetricNeighbors[j]))) {
        msg = getLowestUndeliveredMessage(&(symmetricNeighbors[j]));
        if(msg != NULL) {
          rMsg = TOS_to_Reliable(msg);
          toSend = TRUE;
          for(i = 0; i < cont; i++) {
            if(msgSent[i] ==  rMsg->msgId) {
              toSend = FALSE;
            }
          }
          if(toSend) {
            msgSent[cont++] = rMsg->msgId;
            sendReliableMsg(msg);
          }
        }
      }
    }
  }


 /****************************************/

  /**
   * Unordered Messages
   *
   * This structure hosts the messages that have not been received in order
   *
   */

  TOS_Msg unorderedMessages[BUFFER_SIZE];


  /**
   * Initialize the list of unorderedMessages
   */
  void initializeUnorderedMessages() {
    uint8_t i;

    for(i=0; i < BUFFER_SIZE; i++) {
      unorderedMessages[i] = newNullMsg();
    }
  }


#ifndef mica2
  /**
   * Print the list of unorderedMessages
   */
  void printUnorderedMessages() {
    uint8_t i;

    for(i=0; i < BUFFER_SIZE; i++) {
      if(!isNullMsg(&(unorderedMessages[i]))) {
  mydbg(DBG_USR3, "unorderedMessages[%d] -> %s\n", i, printReliableMsg(&(unorderedMessages[i])));
      }
    }
  }
#endif

  /**
   * Get an unordered message
   */
  TOS_MsgPtr getUnorderedMessage(TOS_MsgPtr msg) {
    uint8_t i;

    for(i=0; i < BUFFER_SIZE; i++) {
      if(msgcmp(msg, &(unorderedMessages[i]))) {
  return &(unorderedMessages[i]);
      }
    }

    return NULL;
  }

  /**
   * Add an unordered message. If the message is already in, it is not added.
   */
  TOS_MsgPtr addUnorderderMessage(TOS_MsgPtr msg) {
    uint8_t i;
    TOS_MsgPtr tm;

    // First check whether it has already in
    tm = getUnorderedMessage(msg);

    if(tm != NULL) {
      return tm;
    }
    else {
      for(i=0; i < BUFFER_SIZE; i++) {
  if(isNullMsg(&(unorderedMessages[i]))) {
    unorderedMessages[i] = *msg;
    return &(unorderedMessages[i]);
  }
      }

      mydbg(DBG_ERROR, "ERRORR: No space left for additional unordered messages");
      return NULL;
    }
  }

  TOS_Msg getNextUnorderedMessage(TOS_MsgPtr msg) {
    msgId_t ownMsgId, tmpMsgId;
    uint8_t i,pos;
    TOS_Msg result;
    NeighborData *neighbor;
    ReliableMsg *rMsg = TOS_to_Reliable(msg);


    pos =  getMsgDeviceIndex(rMsg->msgDeviceId, TOS_LOCAL_ADDRESS);
    if(pos == MAX_NEIGHBORS) {
      ownMsgId = NULL_MSG_ID;
    }
    else {
      ownMsgId = rMsg->msgDeviceId[pos].msgId;
    }
    neighbor = getNeighbor(rMsg->msgOrigin);

    if(neighbor == NULL) {
      // There is no unordered messages (neighbor is unknown)
      return newNullMsg();
    }
    else {
      ReliableMsg* unorderedReliableMsg;
      for(i=0; i < BUFFER_SIZE; i++) {
        unorderedReliableMsg = TOS_to_Reliable(&(unorderedMessages[i]));
        if(!isNullMsg(&(unorderedMessages[i])) && neighbor->deviceId == unorderedReliableMsg->msgOrigin) {
          pos = getMsgDeviceIndex(unorderedReliableMsg->msgDeviceId, TOS_LOCAL_ADDRESS);
          if(pos == MAX_NEIGHBORS) {
            tmpMsgId = NULL_MSG_ID;
        }
          else {
            tmpMsgId = unorderedReliableMsg->msgDeviceId[pos].msgId;
          }
          if(tmpMsgId == ownMsgId + 1) {
            result = unorderedMessages[i];
            unorderedMessages[i] = newNullMsg();
            neighbor->lastMsgReceived = tmpMsgId;
            return result;
          }
        }
      }
      return newNullMsg();
    }
  }



  /***********************************************/

  /**
   *
   * Network Primitives
   *
   */


  /**
   * It sends a tuple message. If there is already another send on
   * hold, the message is inserted in the pending message list.
   */
  result_t sendReliableMsg(TOS_MsgPtr msg) {
    ReliableMsg* rMsg = (ReliableMsg *)msg->data;

    // Update the receive message list
    addNeighborList(rMsg);

//    uart_puts("calling sendReliableMsg()\n");


    if (call Send.send(TOS_BCAST_ADDR, msg, sizeof(ReliableMsg)) == SUCCESS) {
      mydbg(DBG_USR3, "Message sent: %s\n", printReliableMsg(msg));

      beaconNeeded = FALSE;
      return SUCCESS;
    } else {
      mydbg(DBG_ERROR, "ERROR: Message NOT sent: %s\n", printReliableMsg(msg));
      uart_puts("msg NOT sent\n");
      return FAIL;
    }
  }

  result_t sendBeaconMessage() {
    ReliableMsg *rMsg = TOS_to_Reliable(&beaconMsg);
    initMsgDevice(rMsg->msgDeviceId);

    rMsg->target = TOS_BCAST_ADDR;
    rMsg->msgId = NULL_MSG_ID;
    rMsg->reliable = FALSE;
    rMsg->msgOrigin = TOS_LOCAL_ADDRESS;

    return sendReliableMsg(&beaconMsg);
  }


  /***********************************************/

   command result_t Init.init() {
//      print_data_size();

     initializeAsymmetricNeighbors();
     initializeNeighbors();
     initializeBuffer();
     initializeUnorderedMessages();


     return call CommInit.init();
//     return SUCCESS; // call CommControl.init();
   }

  command result_t StdControl.start() {
    active = TRUE;
    call OneShotTimer.startOneShot((TOS_LOCAL_ADDRESS * 1024) % UPDATE);
  return SUCCESS;
  }

  command result_t StdControl.stop() {
    active = FALSE;
    call PeriodicTimer.stop();
  }

  event void PeriodicTimer.fired() {

    localTime++;

    mydbg(DBG_USR3, "*********************** DEBUG Node %d ********************\n", TOS_LOCAL_ADDRESS);

    pruneAsymmetricNeighbors();
    removeOldNeighbors();
    removeDeliveredMessages();
    resendUndeliveredMessages();

#ifndef mica2
    printNeighbors();
    printMsgBuffer();
    printUnorderedMessages();
#endif

    mydbg(DBG_USR3, "*********************** END DEBUG Node %d ********************\n", TOS_LOCAL_ADDRESS);
  }

  event void OneShotTimer.fired() {

    static bool initTimer = TRUE;

    if(initTimer) {
      call PeriodicTimer.startPeriodic(UPDATE);
      initTimer = FALSE;
    }

    if(beaconNeeded) {
      sendBeaconMessage();
    }
  }

  event message_t* Receive.receive(TOS_MsgPtr msg, void* payload, uint8_t len){
    TOS_Msg unorderedMsg;
    ReliableMsg* rMsg = (ReliableMsg*) msg->data;
    uint8_t uo_len;
    void* uo_payload;

    addAsymmetricNeighbor(rMsg->msgOrigin);

    mydbg(DBG_USR3, "Message received: %s\n", printReliableMsg(msg));

    if(isReliableMsg(msg)
       && (rMsg->target == TOS_LOCAL_ADDRESS
       || rMsg->target == TOS_BCAST_ADDR)) {
      beaconNeeded = TRUE;
      uart_puts("rel");
      call OneShotTimer.startOneShot(BEACON_TIMEOUT);
    }

    if (messageReceived(msg) == SUCCESS) {
      // Check for unordered message
      unorderedMsg = getNextUnorderedMessage(msg);
      removeReliability(msg);
      signal ReliableReceive.receive(msg, payload, len);

      while(!isNullMsg(&unorderedMsg)) {
        uo_payload = call Receive.getPayload(&unorderedMsg, &uo_len);
        signal ReliableReceive.receive(&unorderedMsg, uo_payload, uo_len);
        unorderedMsg = getNextUnorderedMessage(&unorderedMsg);
      }
    }
    return msg;
  }

  event void Send.sendDone(TOS_MsgPtr msg, result_t success) {
    signal ReliableSend.sendDone(msg,success);
  }

  command result_t ReliableSend.send(uint16_t address, uint8_t length,
             TOS_MsgPtr msg, bool reliable) {
    ReliableMsg* rMsg;

    if (length > TOSH_RELIABLE_DATA_LENGTH) {
      mydbg(DBG_ERROR,"ERROR: Message too big to be transmitted reliably!\n");
      uart_puts("Message too big!\n");
      return FAIL;
    }

    // TODO: don't do this. Just implement ReliableReceive.getPayload() correctly and
    // let this function pass a pointer to the area somewhere after the reliability fields.
    addReliability(msg);
    rMsg = TOS_to_Reliable(msg);

    initMsgDevice(rMsg->msgDeviceId);

    rMsg->msgOrigin = TOS_LOCAL_ADDRESS;
    rMsg->target = address;
    rMsg->reliable = reliable;

    rMsg->msgId = ++globalMsgCounter;
    if(globalMsgCounter == UINT32_MAX) {
      globalMsgCounter = 0;
    }

    if(isReliableMsg(msg)) {
      if(addRecipients(rMsg) == 0) {
        // No recipients found
        mydbg(DBG_USR3, "Msg id:%d is NOT sending\n", rMsg->msgId);
        uart_puts("no recipients found\n");
        return FAIL;
      }
      else {
        mydbg(DBG_USR3, "Msg id:%d is sending\n", rMsg->msgId);
        uart_puts("call addMessage\n");
      }
      addMessage(msg);
    }
    else {
      mydbg(DBG_USR3, "Msg id:%d is sending\n", rMsg->msgId);
    }
    return sendReliableMsg(msg);
  }


  command void* ReliableReceive.getPayload(message_t *m, uint8_t *len) {
    // TODO: consider reliability fields
    // This avoids an expensive call to addReliability
    return call Packet.getPayload(m, len);
  }

  command uint8_t ReliableReceive.payloadLength(message_t *m) {
    // TODO: consider reliability fields
    return call Packet.payloadLength(m);
  }


/*   command uint16_t* ReliableSend.getSymmetricNeighborsId() { */
/*     uint8_t i, j; */
/*     static uint16_t symmetricNeighborsSet[MAX_NEIGHBORS]; */

/*     j = 0; */
/*     for(i = 0; i < MAX_NEIGHBORS; i++) { */
/*       if(!isNullNeighbor(&(symmetricNeighbors[i]))) { */
/* 	symmetricNeighborsSet[j] = symmetricNeighbors[i].deviceId; */
/* 	j++; */
/*       } */
/*     } */

/*     for(  ; j < MAX_NEIGHBORS; j++) { */
/*       symmetricNeighborsSet[j] = NULL_NEIGHBOR_ID; */
/*     } */

/*     return symmetricNeighborsSet; */
/*   } */


  void print_data_size() {


    uart_puts("\n\nReliableGenericComm data\n");
    uart_puts("component globals:\n");

    uart_puthex4(sizeof(beaconNeeded));
    uart_puts(" <- beaconNeeded\n");

    uart_puthex4(sizeof(globalMsgCounter));
    uart_puts(" <- globalMsgCounter\n");

    uart_puthex4(sizeof(active));
    uart_puts(" <- active\n");

    uart_puthex4(sizeof(localTime));
    uart_puts(" <- localTime\n");

    uart_puts("Buffer:\n");
    uart_puthex4(sizeof(msgBuffer));
    uart_puts(" <- msgBuffer * BUFFER_SIZE(2)\n");

    uart_puts("PendingMsg:\n");
    uart_puthex4(sizeof(beaconMsg));
    uart_puts(" <- beaconMsg\n");

    uart_puthex4(sizeof(asymmetricNeighbors));
    uart_puts(" <- asymmetricNeighbors * MAX_NEIGHBORS\n");

    uart_puts("Neighbor structure:\n");
    uart_puthex4(sizeof(symmetricNeighbors));
    uart_puts(" <- symmetricNeighbors (NeighborData) * MAX_NEIGHBORS\n");

    uart_puts("Unordered msgs:\n");
    uart_puthex4(sizeof(unorderedMessages));
    uart_puts(" <- unorderedMessages * BUFFER_SIZE\n");


    uart_puts("end of ReliableGenericComm data\n\n");
  }


}


