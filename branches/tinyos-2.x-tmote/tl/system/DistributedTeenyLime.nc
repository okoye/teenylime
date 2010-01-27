/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 294 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:18:51 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: DistributedTeenyLime.nc 294 2008-02-26 18:18:51Z lmottola $
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

#include "TLConf.h"

#include "TupleSpace.h"
#include "TupleMsg.h"
#include "TLDebug.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * The component implementing distributed operations.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

module DistributedTeenyLime {

  provides {
    interface Init;
    interface DistributedTupleSpace;
  }

  uses {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
    interface BridgeTupleSpace;
    interface TLDebug;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  // Data structure to maintain remote reactions towards other hosts
  typedef struct {
    TLOpId_t operationId;
    tuple templ;
    TLTarget_t target;
  } activeReaction;
  activeReaction activeReactions[MAX_REACTIONS];
  uint8_t numberActiveReactions;

  // Data structure representing remote reactions active on this host
  typedef struct {
    TLOpId_t operationId;
    uint16_t lastSeen;
  } installedReaction;
  installedReaction installedReactions[MAX_REACTIONS];
  uint8_t numberInstalledReactions;

  // Data structure for pending remote operations
  typedef struct {
    bool empty;
    TLOpId_t operationId; 
    tuple tuples[MAX_RETURN_TUPLES];
    uint8_t number;
    bool singleAnswer;
    bool completed;
    uint16_t countDown;
  } pendingOp;
  pendingOp pendingOps[MAX_PENDING_OPS];

  // Data structure for maintaining the neighbor set
  TLTarget_t neighborsId[MAX_NEIGHBORS];
  typedef struct {
    tuple nghTuple;
    uint16_t lastSeen;
  } neighborData;
  neighborData neighborSet[MAX_NEIGHBORS];

  // Identifier for TeenyLIME system operations
  TLOpId_t teenyLimeSystemOp;
  
  // Local (logical) time
  uint16_t localTime = 0;  

  // Utility functions
  uint16_t minB (uint16_t a, uint16_t b) {
    if (a<b) 
      return a;
    else 
      return b;
  }

  uint16_t maxB (uint16_t a, uint16_t b) {
    if (a>b) 
      return a;
    else 
      return b;
  }

  error_t addActiveReaction(TLOpId_t *operationId, tuple* templ, 
			    TLTarget_t target) {
    
    atomic {
      if (numberActiveReactions < MAX_REACTIONS) {
	activeReactions[numberActiveReactions].operationId.msgOrigin = operationId->msgOrigin;
	activeReactions[numberActiveReactions].operationId.componentId = operationId->componentId;
	activeReactions[numberActiveReactions].operationId.commandId = operationId->commandId;
	activeReactions[numberActiveReactions].operationId.reliable = operationId->reliable;
	copyTuple(&(activeReactions[numberActiveReactions].templ), templ);
	activeReactions[numberActiveReactions].target = target; 
	numberActiveReactions++;
	return SUCCESS;
      } else {
	return FAIL;
      } 
    } 
  }

  error_t removeActiveReaction(TLOpId_t operationId) {

    uint8_t i;    
    for (i=0; i<numberActiveReactions; i++) {
      if (activeReactions[i].operationId.commandId == operationId.commandId) {
	atomic {
	  activeReactions[i] = activeReactions[--numberActiveReactions];
	}
	return SUCCESS; 
      }
    }
    return FAIL;
  }

  error_t addInstalledReaction(TLOpId_t operationId) {

    if (numberInstalledReactions < MAX_REACTIONS) {
      atomic {
	installedReactions[numberInstalledReactions].operationId = operationId;
	installedReactions[numberInstalledReactions].lastSeen = localTime;
	numberInstalledReactions++;
      }
      return SUCCESS;
    } else {
      return FAIL;
    } 
  } 

  bool isInstalledReaction(TLOpId_t operationId) {

    uint8_t i;    
    for (i=0; i<numberInstalledReactions; i++) {
      if (installedReactions[i].operationId.commandId == operationId.commandId
	  &&installedReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	return TRUE; 
      }
    }
    return FALSE;
  }  

  void refreshInstalledReaction(TLOpId_t operationId) {

    uint8_t i;    
    atomic {
      for (i=0; i<numberInstalledReactions; i++) {
	if (installedReactions[i].operationId.commandId == operationId.commandId
	    &&installedReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	  installedReactions[i].lastSeen = localTime; 
	}
      }
    }
  }  

  void pruneExpiredReactions() {
  
    installedReaction* aliveReactions[MAX_REACTIONS];
    uint8_t i, numberAliveReactions = 0;
    
    atomic {
      // Selecting alive reactions
      for (i=0; i<numberInstalledReactions; i++) {
	if (localTime <= installedReactions[i].lastSeen + REACTION_LOST_REFRESH) {
	  aliveReactions[numberAliveReactions++] = &(installedReactions[i]);
	} 
      }
      
      // Copying back
      for (i=0; i<numberAliveReactions; i++) {
	installedReactions[i].operationId.commandId = aliveReactions[i]->operationId.commandId;
	installedReactions[i].operationId.componentId = aliveReactions[i]->operationId.componentId;
	installedReactions[i].operationId.reliable = aliveReactions[i]->operationId.reliable;
	installedReactions[i].operationId.msgOrigin = aliveReactions[i]->operationId.msgOrigin;
	installedReactions[i].lastSeen = aliveReactions[i]->lastSeen;
      }
      numberInstalledReactions = numberAliveReactions;
    }
  }  

  void pruneTeenyLIMESystem() {
    
    uint8_t i;

    atomic {
      for (i=0; i<MAX_NEIGHBORS; i++) {
	if (neighborsId[i] != NULL_NEIGHBOR_ID
	    && localTime > neighborSet[i].lastSeen + NEIGHBOR_LOST_REFRESH) {
	  call BridgeTupleSpace.remove(&(neighborSet[i].nghTuple));
	  // TODO: This feature must still be tested
/* 	  signal DistributedTupleSpace.tupleSpaceError(NEIGHBOR_DISAPPEREAD,  */
/* 						       teenyLimeSystemOp,  */
/* 						       neighborsId[i],   */
/* 						       &(neighborSet[i].nghTuple));   */
	  neighborsId[i] = NULL_NEIGHBOR_ID;
	}
      }
    }
  }

  void addResultTuples(uint8_t commandId, tuple* tuples, uint8_t number) {

    uint8_t i,j;

    atomic {

      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].operationId.commandId == commandId
	    && !pendingOps[i].completed) {
	  for (j=0; j<number && pendingOps[i].number+number<=MAX_RETURN_TUPLES; j++) {
	    copyTuple(&pendingOps[i].tuples[j+pendingOps[i].number], &tuples[j]);
	  }
	  pendingOps[i].number += number;
	  return;	
	}
      }
    }
  }

  void addPendingOp(TLOpId_t operationId, bool singleAnswer){
    
    uint8_t i;

    atomic {

      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (pendingOps[i].empty){
	  pendingOps[i].empty = FALSE;
	  pendingOps[i].operationId.reliable = operationId.reliable;
	  pendingOps[i].operationId.componentId = operationId.componentId;
	  pendingOps[i].operationId.commandId = operationId.commandId;
	  pendingOps[i].operationId.msgOrigin = operationId.msgOrigin;
	  pendingOps[i].number = 0;
	  pendingOps[i].completed = FALSE;
	  pendingOps[i].singleAnswer = singleAnswer;
	  pendingOps[i].countDown = 1; 
	  return;
	}
      }
      
      call TLDebug.triggerErr(PENDING_OPS_OVERFLOW);
    }
  }

  bool isPending(TLOpId_t operationId) {

    uint8_t i;
    
    atomic {
      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].operationId.commandId == operationId.commandId){
	  return TRUE;
	}
      }
      return FALSE;
    }
  }

  void signalCompletion(uint8_t commandId) {

    uint8_t i;

    atomic {

      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].operationId.commandId == commandId){
	  pendingOps[i].completed = TRUE;
	  signal DistributedTupleSpace.tupleReady(pendingOps[i].operationId,
						  pendingOps[i].tuples,
						  pendingOps[i].number);
	}
      }
    }
  }

  bool isSingleAnswer(uint8_t commandId) {

    uint8_t i;
    
    atomic {
      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].operationId.commandId == commandId){
	  return pendingOps[i].singleAnswer;
	}
      }
      return FALSE;
    }
  }

  bool isCompleted(uint8_t commandId) {

    uint8_t i;
    
    atomic {
      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].operationId.commandId == commandId){
	  return pendingOps[i].completed;
	}
      }
      return FALSE;
    }
  }

  command error_t Init.init() {

    uint8_t i;
    
    for (i=0; i<MAX_PENDING_OPS; i++) {
      pendingOps[i].empty = TRUE;
    }

    numberActiveReactions = 0;
    numberInstalledReactions = 0;

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    // Init neighbor set
    for (i=0; i<MAX_NEIGHBORS; i++) {
      neighborsId[i] = NULL_NEIGHBOR_ID;
    }
    return SUCCESS;
  }
  
  command error_t DistributedTupleSpace.out(TLTarget_t target, 
					     tuple *t, 
					     TLOpId_t operationId) {
    if (operationId.reliable 
	&& target == TL_NEIGHBORHOOD) {
      call TLDebug.triggerErr(UNSUPPORTED_RELIABLE_OP);
      return FAIL;
    } else {
      return call SendTuple.send(target, t, 1, OUT_OP, operationId);
    }
  }

  command error_t DistributedTupleSpace.rd(TLTarget_t target, 
					    tuple *templ, 
					    TLOpId_t operationId) {
    if (operationId.reliable 
	&& target == TL_NEIGHBORHOOD) {
      call TLDebug.triggerErr(UNSUPPORTED_RELIABLE_OP);
      return FAIL;
    } else {
      atomic {
	addPendingOp(operationId, TRUE);
	return call SendTuple.send(target, templ, 1, RD_OP, operationId);
      }
    }
  }
  
  command error_t DistributedTupleSpace.in(TLTarget_t target, 
					    tuple *templ, 
					    TLOpId_t operationId) {
    if (operationId.reliable 
	&& target == TL_NEIGHBORHOOD) {
      call TLDebug.triggerErr(UNSUPPORTED_RELIABLE_OP);
      return FAIL;
    } else {
      atomic {
	addPendingOp(operationId, TRUE);
	return call SendTuple.send(target, templ, 1, IN_OP, operationId);
      }
    }
  }

  command error_t DistributedTupleSpace.rdg(TLTarget_t target, 
					     tuple *templ, 
					     TLOpId_t operationId) {
    if (operationId.reliable 
	&& target == TL_NEIGHBORHOOD) {
      call TLDebug.triggerErr(UNSUPPORTED_RELIABLE_OP);
      return FAIL;
    } else{
      atomic {
	addPendingOp(operationId, FALSE);
	return call SendTuple.send(target, templ, 1, RDG_OP, operationId);
      }
    }
  }

  command error_t DistributedTupleSpace.ing(TLTarget_t target, 
					     tuple *templ, 
					     TLOpId_t operationId) {    
    if (operationId.reliable 
	&& target == TL_NEIGHBORHOOD) {
      call TLDebug.triggerErr(UNSUPPORTED_RELIABLE_OP);
      return FAIL;
    } else {
      atomic {
	addPendingOp(operationId, FALSE);
	return call SendTuple.send(target, templ, 1, ING_OP, operationId);
      }
    }
  }

  command error_t DistributedTupleSpace.addReaction(TLTarget_t target, 
						     tuple *templ, 
						     TLOpId_t *operationId){
    return addActiveReaction(operationId, templ, target);    
  }

  command error_t DistributedTupleSpace.removeReaction(TLOpId_t operationId) {

    return removeActiveReaction(operationId);    
  }

  event error_t BridgeTupleSpace.tupleReady(TLOpId_t operationId, 
					     tuple *tuples, 
					     uint8_t number, 
					     bool reaction){
    atomic {
      if (number>0) {
	if (!reaction) {
	  call SendTuple.send(operationId.msgOrigin, tuples, number, 
			      QUERY_RESULT, operationId);
	} else {
	  call SendTuple.send(operationId.msgOrigin, tuples, number, 
			      REACTION_FIRING, operationId);
	}        
      }
      return SUCCESS;
    }
  }

  bool isNeighbor(TLTarget_t deviceId) {

    uint8_t i;

    atomic {
      
      for (i=0; i<MAX_NEIGHBORS; i++) {
	if (neighborsId[i] != NULL_NEIGHBOR_ID
	    && neighborsId[i] == deviceId) {
	  return TRUE;
	}
      }
      return FALSE; 
    }
  }

  void signalExpiredCompletion() {
    
    uint8_t i;

    atomic {
      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty
	    && pendingOps[i].countDown == 0
	    && !pendingOps[i].completed) {
	  signal DistributedTupleSpace.tupleReady(pendingOps[i].operationId,
						  pendingOps[i].tuples,
						  pendingOps[i].number);
	}
      }
    } 
  }

  void prunePendingOps() {
    
    uint8_t i;

    atomic {
      for (i=0; i<MAX_PENDING_OPS; i++) {
	if (!pendingOps[i].empty) {
	  if (pendingOps[i].countDown == 0) {
	    pendingOps[i].empty = TRUE;
	  } else {
	    pendingOps[i].countDown--;
	  }
	}
      }
    } 
  }

  event void BridgeTupleSpace.timeTick() {

    uint8_t i;

    atomic {

      localTime++;    

      // Signaling expired operations
      signalExpiredCompletion();
      
      // Refreshing remote reactions
      for (i=0; i<numberActiveReactions; i++) {
	call SendTuple.send(activeReactions[i].target, 
			    &(activeReactions[i].templ), 1, 
			    REACT, activeReactions[i].operationId); 
      }
            
      // Pruning expired pending operations
      prunePendingOps();

      // Pruning expired reactions
      pruneExpiredReactions();

      // Pruning info from the TL system
      pruneTeenyLIMESystem();
    }
  }

  event error_t ReceiveTuple.receive(tuple* tuples, uint8_t tupleNumber, 
				      uint8_t operation, TLOpId_t operationId) {    
    atomic {
      switch (operation) {
      case OUT_OP:
	call BridgeTupleSpace.out(tuples, operationId);
	break;
	
      case RD_OP:
	call BridgeTupleSpace.rd(tuples, operationId);
	break;
	
      case IN_OP:
	call BridgeTupleSpace.in(tuples, operationId);
	break;
	
      case RDG_OP:
	call BridgeTupleSpace.rdg(tuples, operationId);
	break;
	
      case ING_OP:
	call BridgeTupleSpace.ing(tuples, operationId);
	break;
	
      case REACT:
	if (!isInstalledReaction(operationId)) {
	  addInstalledReaction(operationId);
	  call BridgeTupleSpace.addReaction(tuples, &operationId);
	}
	refreshInstalledReaction(operationId);
	break;
	
      case QUERY_RESULT:
	// TODO: We're looping four times through the message queue
	// to find some opId. We should write a function that does
	// everything and call it only once.
	addResultTuples(operationId.commandId, tuples, tupleNumber);
	if (isSingleAnswer(operationId.commandId)  
	    && !isCompleted(operationId.commandId)) {
	  signalCompletion(operationId.commandId);
	}
	break;
	
      case REACTION_FIRING:
	signal DistributedTupleSpace.tupleReady(operationId, tuples, tupleNumber);
	break;
	
      default:
#ifdef PRINTF_SUPPORT
	printf("Unknown op %u\n", operation);
	call PrintfFlush.flush();
#endif
      }
      
      return SUCCESS;
    }
  }

  event tuple* NeighborSystem.getNeighborTuple() {
    return call BridgeTupleSpace.getNeighborTuple();
  }

  event error_t NeighborSystem.update(TLTarget_t msgOrigin, 
				      tuple neighborTuple) {
    uint8_t i;    
    bool insertion = FALSE;

    atomic {
      if (!isNeighbor(msgOrigin)) {
	for (i=0; i<MAX_NEIGHBORS && !insertion; i++) {
	  if (neighborsId[i] == NULL_NEIGHBOR_ID) {
	    neighborsId[i] = msgOrigin;
	    neighborSet[i].nghTuple = neighborTuple;
	    neighborSet[i].lastSeen = localTime;
	    call BridgeTupleSpace.out(&(neighborSet[i].nghTuple),
				      teenyLimeSystemOp);
	    insertion = TRUE;
	  }
	}
	if (!insertion) {
	  call TLDebug.triggerErr(NEIGHBOR_OVERFLOW);
	}
      } else {
	for (i=0; i<MAX_NEIGHBORS; i++) {
	  if (neighborsId[i] != NULL_NEIGHBOR_ID 
	      && neighborsId[i] == msgOrigin) {
	    call BridgeTupleSpace.replace(&(neighborSet[i].nghTuple),
					  &neighborTuple);
	    neighborSet[i].lastSeen = localTime; 
	    neighborSet[i].nghTuple = neighborTuple;   
	  } 
	}
      }
      return SUCCESS;
    }
  }

  event void SendTuple.reliableOpFail(TLOpId_t operationId, 
				      TLTarget_t target,  
				      tuple* failedTuple){

    signal DistributedTupleSpace.tupleSpaceError(RELIABLE_MSG_FAIL, 
						 operationId, 
						 target,  
						 failedTuple);  
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}
