/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 307 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 12:37:23 +0200 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: DataForwarderC.nc 307 2008-03-04 10:37:23Z lmottola $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "Configuration.h"
#include "CollectionInfo.h"
#include "CollectionTuning.h"

/** 
 * Module for data forwarding on the collecting tree.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */
module DataForwarderC {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerReliablePath;
    interface TupleSpace as TS;
    interface Tuning;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif

    interface AMPacket;
    interface TreeConnection;
    interface TLObjects;
    interface RetriesInfo;

    interface TeenyLIMEExceptions;
  }

  provides {
    interface CollectionInfo;
    interface CollectionDebug;
    interface CollectionTuning;
  }

}

implementation {

  struct {
    uint16_t last_loc_id;
    uint16_t src;
    uint16_t src_id;
  } buffer[CHILDREN_HISTORY_SIZE];

  uint16_t forward_id, forwarded_id, removed_id;
  uint16_t current_parent;

  bool rem_reading, rem_outing;
  uint16_t rem_reading_msg_id, rem_reading_node_id;

  tuple<uint8_t, uint16_t, uint16_t,
    uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> forwarding_msg;

  TLOpId_t reactionId, outRemId, outId, rdRemId,
    rdgRecoveryId, inId, ingId;
  bool fw_active;
  bool notified_active;
  
  uint8_t deleted_messages;
  uint8_t rd_retries;
  bool failed_rd;
  uint16_t recovery_retries;
  uint16_t cache_size, max_recovery_retries; 

  bool evaluating;
  bool set_reliable_path;
  uint16_t reliable_lpl, unreliable_lpl;

  tuple<uint8_t, uint16_t, uint16_t, 
    uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> toEvaluate;

  bool isRecoveryRequired(uint16_t src, uint16_t src_msg_id);
  bool isDuplicate(uint16_t src, uint16_t src_msg_id);
  void insertIntoCache(tuple<uint8_t, uint16_t, uint16_t,
                       uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *msg);
  void fakeLastId(uint16_t node_id, uint16_t faked_last_id);
  task void evaluateRemoteMsg();
  task void nextToEvaluate();
  void installReaction();

  // Returns TRUE if round2 follows round1
  bool isSecondNewer(uint16_t round1, uint16_t round2){
    if (round1 == round2){
      return FALSE;
    } else if (round1 < round2){
      if ((round2 - round1) < 0x8000) {
        return TRUE;
      } else {
        return FALSE;
      }
    } else {
      if ((round1 - round2) < 0x8000) {
        return FALSE;
      } else {
        return TRUE;
      }
    }
  }

  // Returns TRUE if the message coming from src with src_msg_id:
  // - requires reliable delivery and there is no history about
  //   the source
  // - requires reliable delivery and the src_msg_id is not the one
  //   following the last recorded in the history of the source
  // - requires reliable delivery and the src_msg_id is older than the
  //   cache size (to face the case in which a node has been restarted)
  bool isRecoveryRequired(uint16_t src, uint16_t src_msg_id){
    uint8_t ind;
    uint16_t previous_id;
    if (src_msg_id == UNRELIABLE_DELIVERY || src == TL_LOCAL)
      return FALSE;
    if (src_msg_id == MIN_RELIABLE_MSG_ID)
      previous_id = MAX_RELIABLE_MSG_ID;
    else
      previous_id = src_msg_id - 1;
    atomic{
      for (ind = 0; ind < CHILDREN_HISTORY_SIZE; ind++){
        if (buffer[ind].src == src){
          if (isSecondNewer(buffer[ind].src_id, previous_id) ||
              isSecondNewer(src_msg_id + CACHE_SIZE, buffer[ind].src_id))
            return TRUE;
          else
            return FALSE;
        }
      }
    }
    return TRUE;
  }

  // Adds a message id (faked_last_id) to the history of node_id; it is used
  // when a message that should be recovered cannot be find in the cache
  // of the sender
  void fakeLastId(uint16_t node_id, uint16_t faked_last_id){
    uint8_t ind;
    uint8_t replace_info = 0;
    atomic{
      for (ind = 0; ind < CHILDREN_HISTORY_SIZE; ind++){
        if (buffer[ind].src == TL_LOCAL ||
            buffer[ind].src == node_id){
          replace_info = ind;
          break;
        } else if (isSecondNewer(buffer[ind].last_loc_id,
                                 buffer[replace_info].last_loc_id)){
          replace_info = ind;
        }
      }
      if (buffer[replace_info].src == node_id){
        buffer[replace_info].src_id = faked_last_id;
      } else {
        buffer[replace_info].src = node_id;
        buffer[replace_info].src_id = faked_last_id;
        buffer[replace_info].last_loc_id = 0;
      }
    }
  }

  // Returns TRUE if the message is a duplicate. It happens when:
  // - the message requires reliable delivery and the src_msg_id is older
  //   than the last message recorded in the history but not older than the
  //   cache size
  bool isDuplicate(uint16_t src, uint16_t src_msg_id){
    uint16_t ind;
    if (src_msg_id == UNRELIABLE_DELIVERY || src == TL_LOCAL)
      return FALSE;
    for (ind = 0; ind < CHILDREN_HISTORY_SIZE; ind++){
      if (buffer[ind].src == src){
        if (isSecondNewer(src_msg_id + CACHE_SIZE, buffer[ind].src_id))
          return FALSE;
        else if (!isSecondNewer(buffer[ind].src_id, src_msg_id))
          return TRUE;
        else
          return FALSE;
      }
    }
    return FALSE;
  }

  // Looks for the next message to evaluate
  task void nextToEvaluate(){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp;
    atomic{
      if (!evaluating){
        temp = newTuple(
                        actualField(MSG_TYPE),
                        dontCare(),
                        dontCare(),
                        dontCare());
        call TS.rdg(&rdgRecoveryId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
      }
    }
  }

  // Inserts a message in the local cache
  void insertIntoCache(tuple<uint8_t, uint16_t, uint16_t,
                       uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *msg){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp;
    uint16_t ind, replace_info;
    atomic{
      if (removed_id == MAX_RELIABLE_MSG_ID)
        removed_id = MIN_RELIABLE_MSG_ID;
      else
        removed_id++;
      temp = newTuple(
                      actualField(CACHE_TYPE),
                      actualField(TL_LOCAL),
                      actualField(removed_id),
                      dontCare());
      call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
      if (msg->value1 != TL_LOCAL){
        replace_info = 0;
        for (ind = 0; ind < CHILDREN_HISTORY_SIZE; ind++){
          if (buffer[ind].src == msg->value1 ||
              buffer[ind].src == TL_LOCAL){
            replace_info = ind;
            break;
          } else if (isSecondNewer(buffer[ind].last_loc_id,
                                   buffer[replace_info].last_loc_id)){
            replace_info = ind;
          }
        }
        if ((buffer[replace_info].src == msg->value1 &&
             isSecondNewer(buffer[replace_info].src_id, msg->value2)) ||
            buffer[replace_info].src != msg->value1){
          buffer[replace_info].src = msg->value1;
          buffer[replace_info].src_id = msg->value2;
        }
        buffer[replace_info].last_loc_id = forwarded_id;
      }
      msg->value0 = CACHE_TYPE;
      msg->value1 = TL_LOCAL;
      msg->value2 = forwarded_id;
      call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) msg);
    }
  }

  // Evaluates a message to be forwarded
  task void evaluateRemoteMsg(){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp;
    atomic{
      if (isDuplicate(toEvaluate.value1, toEvaluate.value2)){
        // If it is a duplicate the message is removed from the tuple space
        signal CollectionDebug.droppedDuplicate(toEvaluate.value1);
        call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &toEvaluate);
        if (fw_active){
          post nextToEvaluate();
        }
      } else if (isRecoveryRequired(toEvaluate.value1, toEvaluate.value2)){
        if (!rem_reading){
          // If a recovery is required and no remote reading is active,
          // read from the cache of the source the lost message
          rem_reading = TRUE;
          rem_reading_node_id = toEvaluate.value1;
          if (toEvaluate.value2 == MIN_RELIABLE_MSG_ID)
            rem_reading_msg_id = MAX_RELIABLE_MSG_ID;
          else
            rem_reading_msg_id = toEvaluate.value2 - 1;
          temp = newTuple(
                          actualField(CACHE_TYPE),
                          actualField(rem_reading_node_id),
                          actualField(rem_reading_msg_id),
                          dontCare());
          rd_retries = 0;
          recovery_retries = 0;
          failed_rd = FALSE;
          call TS.rd(&rdRemId, TRUE, rem_reading_node_id, RAM_TS, (tuple *) &temp);
          if (fw_active){
            post nextToEvaluate();
          }
        }
      } else if (!rem_outing){
        // If no recovery is required, it is not a duplicate and there is
        // out operation running, output the message in the tuple space of the
        // parent
        rem_outing = TRUE;
        call TLObjects.copy_tuple((tuple *) &forwarding_msg, 
                                  (tuple *) &toEvaluate);
        forwarding_msg.value1 = TL_LOCAL;
        if (toEvaluate.value2 != UNRELIABLE_DELIVERY){
          if (forward_id == MAX_RELIABLE_MSG_ID)
            forward_id = MIN_RELIABLE_MSG_ID;
          else
            forward_id++;
          forwarding_msg.value2 = forward_id;
          forwarded_id = forward_id;
        }
        call TS.out(&outRemId, TRUE, current_parent, RAM_TS, 
                    (tuple *) &forwarding_msg);
        forwarding_msg.value1 = toEvaluate.value1;
        forwarding_msg.value2 = toEvaluate.value2;
      }
      evaluating = FALSE;
    }
  }

  void installReaction(){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    p = newTuple(
                 actualField(MSG_TYPE),
                 dontCare(), 
                 dontCare(),
                 dontCare());
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }
  
  event void Boot.booted() {
    uint8_t ind;
    evaluating = FALSE;
    current_parent = TL_LOCAL;
    fw_active = FALSE;
    rem_outing = FALSE;
    rem_reading = FALSE;
    notified_active = FALSE;
    cache_size = CACHE_SIZE;
    max_recovery_retries = MAX_RECOVERY_RETRIES;
    failed_rd = FALSE;
    removed_id = MAX_RELIABLE_MSG_ID - CACHE_SIZE;
    forward_id = MAX_RELIABLE_MSG_ID;
    rem_reading_node_id = TL_LOCAL;
    set_reliable_path = FALSE;
    reliable_lpl = LPL_RELIABLE_PATH;
    unreliable_lpl = LPL_UNRELIABLE_PATH;
    installReaction();
    for (ind = 0; ind < CHILDREN_HISTORY_SIZE; ind++){
      buffer[ind].last_loc_id = 0;
      buffer[ind].src = TL_LOCAL;
      buffer[ind].src_id = 0;
    }
    call TreeConnection.congested(TRUE);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    uint16_t msg_id, src;
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp,
			   *oldest, *rec;

    PROCESS_OP(reactionId,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId, iterator);
               if (fw_active && !evaluating &&
                   (!rem_reading || rem_reading_node_id != rec->value1)){
/*                  If a new message is received, the forwarding is active */
/*                  and the message is not coming from a node towards which */
/*                  there is a recovery active, look for the oldest message */
/*                  from that node in the tuple space */
                 temp = newTuple(
                                 actualField(MSG_TYPE),
                                 actualField(rec->value1),
                                 dontCare(),
                                 dontCare());
                 call TS.rdg(&rdgRecoveryId, FALSE, TL_LOCAL, RAM_TS, 
                             (tuple *) &temp);
               });
    
    PROCESS_OP(rdRemId,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId, iterator);
               signal CollectionDebug.messageRecovery(rec != NULL,
                                                      rd_retries,
                                                      rem_reading_node_id);
               if (failed_rd && recovery_retries < max_recovery_retries){
                 temp = newTuple(
                                 actualField(CACHE_TYPE),
                                 actualField(rem_reading_node_id),
                                 actualField(rem_reading_msg_id),
                                 dontCare());
                 rd_retries = 0;
                 recovery_retries++;
                 failed_rd = FALSE;
                 call TS.rd(&rdRemId, TRUE, rem_reading_node_id, RAM_TS, (tuple *) &temp);
                 return;
               }
               rem_reading = FALSE;
               if (rec != NULL){
/*                  If the recovery returned a result, just output it in the */
/*                  local tuple space */
                 rec->value0 = MSG_TYPE;
                 rem_reading_node_id = TL_LOCAL;
                 call TS.out(&outId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rec);
               } else {
/*                  No result has been recovered from the cache, a fake */
/*                  message is recorded in the history to go on with the  */
/*                  processing of the messages coming from that node */
                 fakeLastId(rem_reading_node_id, rem_reading_msg_id);
                 temp = newTuple(
                                 actualField(MSG_TYPE),
                                 actualField(rem_reading_node_id),
                                 dontCare(),
                                 dontCare());
                 rem_reading_node_id = TL_LOCAL;
                 if (fw_active && !evaluating){
                   call TS.rdg(&rdgRecoveryId, FALSE, TL_LOCAL, RAM_TS, 
                               (tuple *) &temp);
                 }
               });

    PROCESS_OP(rdgRecoveryId,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId, iterator);
/*                We look for a message that can be evaluted for the  */
/*                forwarding */
               if (rec != NULL) {
                 src = rec->value1;
                 msg_id = rec->value2;
                 oldest = rec;
                 for (rec = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                             *) call TS.nextTuple(operationId, iterator);
                      rec != NULL;
                      rec = (tuple<uint8_t, uint16_t, uint16_t,
                             uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                             *) call TS.nextTuple(operationId, iterator)){
                   if (rem_reading && rec->value1 == rem_reading_node_id){
                     /* DO NOTHING */
                   } else if ((rem_reading && src == rem_reading_node_id)
                              || (rec->value1 == src
                                  && (msg_id == UNRELIABLE_DELIVERY ||
                                      (rec->value2 != UNRELIABLE_DELIVERY &&
                                       isSecondNewer(rec->value2, msg_id))))){
/*                      The tracked message is replaced if: */
/*                      - an older message coming from the same source is  */
/*                        found */
/*                      - the tracked message was coming from a node from */
/*                        from which an operation of recovery is active */
/*                      - the tracked message was for an unreliable delivery */
                     src = rec->value1;
                     msg_id = rec->value2;
                     oldest = rec;
                   }
                 }
                 if (src == TL_LOCAL || !rem_reading 
                     || src != rem_reading_node_id){
/*                    If the message is eligible to be forwarded */
                   evaluating = TRUE;
                   call TLObjects.copy_tuple((tuple *) &toEvaluate, 
                                             (tuple *) oldest);
                   post evaluateRemoteMsg();
                 }
               } else {
                 if (!notified_active){
/*                    If no message is left to be forwarded and the */
/*                    application is still to be notified about the */
/*                    active forwarding */
                   notified_active = TRUE;
                   signal CollectionInfo.forwardingStatus(FORWARDING_ACTIVE);
                 }
               });
    
    PROCESS_OP(inId,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId, iterator);
               if (rec != NULL)
                 call TS.nextTuple(operationId, iterator);
               );

    PROCESS_OP(ingId,
               for (rec = (tuple<uint8_t, uint16_t, uint16_t,
                           uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                           *) call TS.nextTuple(operationId, iterator);
                    rec != NULL;
                    rec = (tuple<uint8_t, uint16_t, uint16_t,
                           uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                           *) call TS.nextTuple(operationId, iterator)){
                 deleted_messages++;
               });
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,  
                      		   TLTupleSpace_t ts,
				   tuple* returningTuple){
    uint16_t traffic_class;

    CHECK_OP(outRemId, RELIABLE_OP_FAIL,
/*              If the out operation failed */
             if (forwarding_msg.value2 == UNRELIABLE_DELIVERY){
               traffic_class = 0;
             } else if (forwarding_msg.value3[0] == CLASS_1_END_SESSION){
               traffic_class = 1;
             } else if (forwarding_msg.value3[0] == CLASS_1_TYPE){
               traffic_class = 1;
               if (set_reliable_path){
                 call TimerReliablePath.stop();
               } else {
                 set_reliable_path = TRUE;
                 call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, reliable_lpl);
                 call TreeConnection.setReliablePath(TRUE);
               }
               call TimerReliablePath.startOneShot(RELIABLE_WINDOW * 
                                                   MAX_CLASS_1_REPORT_INTERVAL);
             } else {
               traffic_class = 2;
             }
             signal CollectionDebug.transmissionFailed(traffic_class,
                                                       call RetriesInfo.getRetries(),
                                                       forwarding_msg.value1);
             rem_outing = FALSE;
             if (forwarding_msg.value2 != UNRELIABLE_DELIVERY){
/*                clean the changes made to the id of the forwarded messages */
               if (forward_id == MIN_RELIABLE_MSG_ID)
                 forward_id = MAX_RELIABLE_MSG_ID;
               else
                 forward_id--;
               forwarded_id = forward_id;
             }
/*              notify the tree builder that the tree is congested */
             call TreeConnection.congested(FALSE);
             );

    CHECK_OP(outRemId, OP_COMPLETED_OK,
/*              If the message has been successfully forwarded */
/*              remove the message from the local tuple space */
             if (forwarding_msg.value2 == UNRELIABLE_DELIVERY){
               traffic_class = 0;
             } else if (forwarding_msg.value3[0] == CLASS_1_END_SESSION){
               traffic_class = 1;
             } else if (forwarding_msg.value3[0] == CLASS_1_TYPE){
               traffic_class = 1;
               if (set_reliable_path){
                 call TimerReliablePath.stop();
               } else {
                 set_reliable_path = TRUE;
                 call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, reliable_lpl);
                 call TreeConnection.setReliablePath(TRUE);
               }
               call TimerReliablePath.startOneShot(RELIABLE_WINDOW * 
                                                   MAX_CLASS_1_REPORT_INTERVAL);
             } else {
               traffic_class = 2;
             }
             signal CollectionDebug.packetForwarded(traffic_class,
                                                    call RetriesInfo.getRetries(),
                                                    forwarding_msg.value1);
             call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &forwarding_msg);
             if (forwarding_msg.value2 != UNRELIABLE_DELIVERY){
/*                insert the message in the local cache */
               insertIntoCache(&forwarding_msg);
             }
             rem_outing = FALSE;
             if (fw_active){
               if (!notified_active){
/*                  notify the application that the forwarding is active */
                 notified_active = TRUE;
                 signal CollectionInfo.forwardingStatus(FORWARDING_ACTIVE);
               }
/*                look for a new message to forward */
               post nextToEvaluate();
             });

    CHECK_OP(rdRemId, QUERY_SENT_OK,
             rd_retries = call RetriesInfo.getRetries();
             );

    CHECK_OP(rdRemId, RELIABLE_OP_FAIL,
             failed_rd = TRUE;
             if (rd_retries == 0)
               rd_retries = call RetriesInfo.getRetries();
             );

  }
  
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TimerReliablePath.fired(){
    atomic{
      set_reliable_path = FALSE;
      call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, unreliable_lpl);
      call TreeConnection.setReliablePath(FALSE);
    }
  }
  
  event void TreeConnection.parentUpdate(uint16_t parent){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp;
    if (current_parent != parent || fw_active){
      signal CollectionDebug.parentUpdated(parent, 
                                           call TreeConnection.getPathCost());
    }
    atomic{
      if (current_parent != parent){
        // If I changed parent, create a hole in the sequence numbers to
        // prevent the new parent to recover message that were sent to the
        // old parent
        if (forward_id == MAX_RELIABLE_MSG_ID)
          forward_id = MIN_RELIABLE_MSG_ID;
        else
          forward_id++;
        current_parent = parent;
        if (removed_id == MAX_RELIABLE_MSG_ID)
          removed_id = MIN_RELIABLE_MSG_ID;
        else
          removed_id++;
        temp = newTuple(
                        actualField(CACHE_TYPE),
                        actualField(TL_LOCAL),
                        actualField(removed_id),
                        dontCare());
        call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
      }
    }
    if (!fw_active){
      // if the forwarding is not active, start the forwarding
      atomic{
        fw_active = TRUE;
        post nextToEvaluate();
      }
    }
  }

  event void TreeConnection.congestedPath(bool root, bool failure){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> temp;
    // Notify the application that the forwarding is no longer active
    // and stop the forwarding
    signal CollectionDebug.treeCongested(root);
      if (failure){
        // If I changed parent, create a hole in the sequence numbers to
        // prevent the new parent to recover message that were sent to the
        // old parent
        if (forward_id == MAX_RELIABLE_MSG_ID)
          forward_id = MIN_RELIABLE_MSG_ID;
        else
          forward_id++;
        if (removed_id == MAX_RELIABLE_MSG_ID)
          removed_id = MIN_RELIABLE_MSG_ID;
        else
          removed_id++;
        temp = newTuple(
                        actualField(CACHE_TYPE),
                        actualField(TL_LOCAL),
                        actualField(removed_id),
                        dontCare());
        call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &temp);
      }
    atomic{
      if (notified_active){
        notified_active = FALSE;
        signal CollectionInfo.forwardingStatus(FORWARDING_INACTIVE);
      }
      if (fw_active){
        fw_active = FALSE;
      }
    }
  }
 
  command uint16_t CollectionInfo.currentParent(){
    return call TreeConnection.getParent();
  }

  command uint16_t CollectionInfo.parentCost(){
    return call TreeConnection.getPathCost();
  }

  command uint16_t CollectionInfo.parentLQI(){
    return call TreeConnection.getParentLQI();
  }

  event void TeenyLIMEExceptions.exception(uint8_t exceptionCode, 
					   void* data) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    switch (exceptionCode) {
      
    case TS_FULL:
      // if the tuple space is full, clean the
      // cache
      atomic{
        deleted_messages = 0;
        p = newTuple(
                     actualField(MSG_TYPE),
                     different(TL_LOCAL),
                     dontCare(),
                     dontCare());
        call TS.ing(&ingId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
        signal CollectionDebug.bufferOverflow(deleted_messages);
        call TreeConnection.congested(TRUE);
      }
      break;

    default:
      
    }
  }


  command error_t CollectionTuning.setImmediate(uint8_t key, uint16_t value){
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> p;
    uint8_t i;
    switch (key) {

    case KEY_CACHE_SIZE:
      if (value < cache_size){
        for (i = 0; i < cache_size - value; i++){
          if (removed_id == MAX_RELIABLE_MSG_ID)
            removed_id = MIN_RELIABLE_MSG_ID;
          else
            removed_id++;
          p = newTuple(
                       actualField(CACHE_TYPE),
                       actualField(TL_LOCAL),
                       actualField(removed_id),
                       dontCare());
          call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
        }
      } else {
        for (i = 0; i < value - cache_size; i++){
          if (removed_id == MIN_RELIABLE_MSG_ID)
            removed_id = MAX_RELIABLE_MSG_ID;
          else
            removed_id--;
        }
      }
      cache_size = value;
      return SUCCESS;

    case KEY_RECOVERY_RETRIES:
      max_recovery_retries = value;
      return SUCCESS;

    case KEY_LPL_UNRELIABLE_PATH:
      unreliable_lpl = value;
      if (!set_reliable_path)
        call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, unreliable_lpl);
      return SUCCESS;

    case KEY_LPL_RELIABLE_PATH:
      reliable_lpl = value;
      if (set_reliable_path)
        call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, reliable_lpl);
      return SUCCESS;

    case KEY_FORWARDER_NODE:
      if (value == LEAF)
        call TreeConnection.setForwarderNode(FALSE);
      else if (value == FORWARDER)
        call TreeConnection.setForwarderNode(TRUE);
      return SUCCESS;
      
    default:
      return FAIL;
    }
  }

  event void Tuning.setDone(uint8_t key, uint16_t value) {}

  command uint16_t CollectionDebug.getTotalSend(){
    return call RetriesInfo.getTotalSend();
  }

  command uint16_t CollectionDebug.getTotalRetxmit(){
    return call RetriesInfo.getTotalRetxmit();
  }
  
  // Default event to make it possible not to wire to the interface
  default event void CollectionDebug.parentUpdated(uint16_t parent, 
                                                   uint16_t cost){}
  default event void CollectionDebug.packetForwarded(uint8_t traffic_class,
                                                     uint8_t retries,
                                                     uint16_t child){}
  default event void CollectionDebug.transmissionFailed(uint8_t traffic_class,
                                                        uint8_t retries,
                                                        uint16_t child){}
  default event void CollectionDebug.treeCongested(bool root){}
  default event void CollectionDebug.bufferOverflow(uint8_t deletedMessages){}
  default event void CollectionDebug.messageRecovery(bool success, 
                                                     uint8_t retries,
                                                     uint16_t child){}
  default event void CollectionDebug.droppedDuplicate(uint16_t child){}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

