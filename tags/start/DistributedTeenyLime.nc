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
 * *	$Id: DistributedTeenyLime.nc 4 2007-04-27 15:22:42Z paolinux78 $
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

includes TupleSpace;
includes TupleMsg;

/**
 * The component implementing distributed operations.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

module DistributedTeenyLime {

  provides {
    interface DistributedTupleSpace;
    interface StdControl;
    interface NeighborSystem;
  }

  uses {
    interface SendTuple;
    interface ReceiveTuple;
    interface BridgeTupleSpace;
    interface Timer as OperationTimer;
    interface Timer as PeriodicTimer;
    interface Leds;
  }
}

implementation {

  // Data structure to maintain remote reactions
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
    TLOpId_t operationId;
    tuple tuples[MAX_RETURN_TUPLES];
    uint8_t number;
    bool singleAnswer;
    bool completed;
  } pendingOp;

  // Pending unreliable operations
  pendingOp pendingUnrelOps[MAX_PENDING_OPS];
  uint8_t firstUnrelPendingOp, lastUnrelPendingOp, currentUnrelPendingOps;

  // Pending reliable operations
  pendingOp pendingRelOps[MAX_PENDING_OPS];
  uint8_t firstRelPendingOp, lastRelPendingOp, currentRelPendingOps;

  // Data structure to enforce overall FIFO delivery for reliable operations
/*   TLOpId_t completedOps[MAX_PENDING_OPS]; */
/*   uint8_t completedOpsNum; */

  // Data structure for maintaining the neighbor set
  TLTarget_t neighborsId[MAX_NEIGHBORS];
  typedef struct {
/*     TLTarget_t deviceId; */
    tuple nghTuple;
    uint16_t lastSeen;
  } neighborData;
  neighborData neighborSet[MAX_NEIGHBORS];
  /*   uint8_t numberNeighbors; */

  // Identifier for TeenyLIME system operations
  TLOpId_t teenyLimeSystemOp;
  
  // Local (logical) time
  uint16_t localTime;

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

  result_t addActiveReaction(TLOpId_t operationId, tuple* templ, 
			     TLTarget_t target) {

    if (numberActiveReactions < MAX_REACTIONS) {
      activeReactions[numberActiveReactions].operationId = operationId;
      activeReactions[numberActiveReactions].templ = *templ;
      activeReactions[numberActiveReactions].target = target; 
      numberActiveReactions++;
      return SUCCESS;
    } else {
      return FAIL;
    } 
  } 

  result_t removeActiveReaction(TLOpId_t operationId) {

    uint8_t i;    
    for (i=0; i<numberActiveReactions; i++) {
      if (activeReactions[i].operationId.commandId == operationId.commandId) {
        activeReactions[i] = activeReactions[--numberActiveReactions];
	return SUCCESS; 
      }
    }
    return FAIL;
  }

  result_t addInstalledReaction(TLOpId_t operationId) {

    if (numberInstalledReactions < MAX_REACTIONS) {
      installedReactions[numberInstalledReactions].operationId = operationId;
      installedReactions[numberInstalledReactions].lastSeen = localTime;
      numberInstalledReactions++;
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
    for (i=0; i<numberInstalledReactions; i++) {
     if (installedReactions[i].operationId.commandId == operationId.commandId
         &&installedReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	installedReactions[i].lastSeen = localTime; 
      }
    }
  }  

  void pruneExpiredReactions() {
  
    installedReaction aliveReactions[MAX_REACTIONS];
    uint8_t i, numberAliveReactions = 0;   
    
    // Selecting alive reactions
    for (i=0; i<numberInstalledReactions; i++) {
      if (localTime <= installedReactions[i].lastSeen + REACTION_LOST_REFRESH) {
        aliveReactions[numberAliveReactions++] = installedReactions[i];       
      } else {
        mydbg (DBG_USR1, "Reaction id %d msgOrigin %d expired!\n", 
	       installedReactions[i].operationId.commandId, 
	       installedReactions[i].operationId.msgOrigin); 
      }
    }
    
    // Copying back
    for (i=0; i<numberAliveReactions; i++) {
      installedReactions[i] = aliveReactions[i];
    }    
    numberInstalledReactions = numberAliveReactions;
  }  

  void pruneTeenyLIMESystem() {
    
    uint8_t i;
/*     neighborData aliveNeighbors[MAX_NEIGHBORS]; */
/*     , aliveNeighborNumber = 0; */

    for (i=0; i<MAX_NEIGHBORS; i++) {
      if (neighborsId[i] != NULL_NEIGHBOR_ID 
	  && localTime > neighborSet[i].lastSeen + NEIGHBOR_LOST_REFRESH) {
	call BridgeTupleSpace.remove(&(neighborSet[i].nghTuple));
      }
    }
    
/*     for (i=0; i<aliveNeighborNumber; i++) { */
/*       neighborSet[i] = aliveNeighbors[i]; */
/*     } */
/*     numberNeighbors = aliveNeighborNumber;         */
  }

  void addResultTuples(TLOpId_t operationId, tuple* tuples, uint16_t number) {

    uint8_t i,j, minBound, maxBound, empty = 0;
    pendingOp *queue;

    if (operationId.reliable) {
        minBound = minB(firstRelPendingOp, lastRelPendingOp);
        maxBound = maxB(firstRelPendingOp, lastRelPendingOp);
	queue = pendingRelOps;	
      } else {
        minBound = minB(firstUnrelPendingOp, lastUnrelPendingOp);
        maxBound = maxB(firstUnrelPendingOp, lastUnrelPendingOp);
	queue = pendingUnrelOps;	      
    }

    for (i=minBound; i<=maxBound; i++) {
      if (queue[i].operationId.commandId == operationId.commandId
         && !queue[i].completed) {
        for (j=0; j<number && queue[i].number<MAX_RETURN_TUPLES; j++) {
	  if (!isEmptyTuple(&(tuples[j]))) {
	    queue[i].tuples[j+queue[i].number] = tuples[j];
	  } else {
	    empty++;
	  }
	}
	queue[i].number += (number - empty);
	break;
      }
    }
  }

  result_t addPendingOp(TLOpId_t operationId, bool singleAnswer){

    uint8_t *minBound,*maxBound,*current;
    pendingOp *newOp;

    if (operationId.reliable) {
      minBound = &firstRelPendingOp;
      current = &currentRelPendingOps;
      lastRelPendingOp = (lastRelPendingOp+1) % MAX_PENDING_OPS;
      maxBound = &lastRelPendingOp;
      newOp = &(pendingRelOps[lastRelPendingOp]);
      mydbg (DBG_USR1, "Adding reliable pending operation\n");
    } else {
      minBound = &firstUnrelPendingOp;
      current = &currentUnrelPendingOps;
      lastUnrelPendingOp = (lastUnrelPendingOp+1) % MAX_PENDING_OPS;
      maxBound = &lastUnrelPendingOp;
      newOp = &(pendingUnrelOps[lastUnrelPendingOp]);
      mydbg (DBG_USR1, "Adding unreliable pending operation\n");
    }

    if (*current < MAX_PENDING_OPS) {
      newOp->operationId = operationId;
      newOp->number = 0;
      newOp->completed = FALSE;
      newOp->singleAnswer = singleAnswer;
      *current = *current + 1;
      if (*current == 1) {
        *minBound = *maxBound;
      }
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  bool isPending(TLOpId_t operationId) {
    uint8_t i, minBound, maxBound;
    pendingOp *queue;
    if (operationId.reliable) {
        minBound = minB(firstRelPendingOp, lastRelPendingOp);
        maxBound = maxB(firstRelPendingOp, lastRelPendingOp);
	queue = pendingRelOps;	
      } else {
        minBound = minB(firstUnrelPendingOp, lastUnrelPendingOp);
        maxBound = maxB(firstUnrelPendingOp, lastUnrelPendingOp);
	queue = pendingUnrelOps;	
    }

    for (i=minBound; i<=maxBound; i++) {
      if (queue[i].operationId.commandId == operationId.commandId) {
        return TRUE;
      }
    }
    return FALSE;
  }

  void signalCompletion(TLOpId_t operationId) {

    uint8_t i, minBound, maxBound;
    pendingOp *queue;
    if (operationId.reliable) {
      minBound = minB(firstRelPendingOp, lastRelPendingOp);
      maxBound = maxB(firstRelPendingOp, lastRelPendingOp);
      queue = pendingRelOps;	
      mydbg (DBG_USR1, "Signalling completion for reliable operation %d\n", 
	     operationId.commandId);
    } else {
      minBound = minB(firstUnrelPendingOp, lastUnrelPendingOp);
      maxBound = maxB(firstUnrelPendingOp, lastUnrelPendingOp);	     
      queue = pendingUnrelOps;	
      mydbg (DBG_USR1, "Signalling completion for unreliable operation %d\n", 
	     operationId.commandId);
    } 
    
    for (i=minBound; i<=maxBound; i++) {
      if (queue[i].operationId.commandId == operationId.commandId) {
        mydbg (DBG_USR1, "Firing event for operation %d\n", operationId.commandId);
        queue[i].completed = TRUE;
	signal DistributedTupleSpace.tupleReady(operationId, queue[i].tuples, 
						queue[i].number); 
      }
    }
  }

  bool isSingleAnswer(TLOpId_t operationId) {
    uint8_t i, minBound, maxBound;
    pendingOp *queue;
    if (operationId.reliable) {
        minBound = minB(firstRelPendingOp, lastRelPendingOp);
        maxBound = maxB(firstRelPendingOp, lastRelPendingOp);
	queue = pendingRelOps;	
      } else {
        minBound = minB(firstUnrelPendingOp, lastUnrelPendingOp);
        maxBound = maxB(firstUnrelPendingOp, lastUnrelPendingOp);	      
	queue = pendingUnrelOps;	
    } 

    for (i=minBound; i<=maxBound; i++) {
      if (queue[i].operationId.commandId == operationId.commandId) {
        return queue[i].singleAnswer;
      }
    }
    return FALSE;
  }

  bool isCompleted(TLOpId_t operationId) {
    uint8_t i, minBound, maxBound;
    pendingOp *queue;
    if (operationId.reliable) {
        minBound = minB(firstRelPendingOp, lastRelPendingOp);
        maxBound = maxB(firstRelPendingOp, lastRelPendingOp);
	queue = pendingRelOps;	
      } else {
        minBound = minB(firstUnrelPendingOp, lastUnrelPendingOp);
        maxBound = maxB(firstUnrelPendingOp, lastUnrelPendingOp);	      
	queue = pendingUnrelOps;	
    } 

    for (i=minBound; i<=maxBound; i++) {
      if (queue[i].operationId.commandId == operationId.commandId) {
        return queue[i].completed;
      }
    }
    return FALSE;
  }

  pendingOp getFirstPendingOp(bool reliable) {
    if (reliable) {
      return pendingRelOps[firstRelPendingOp];	
    } else {
      return pendingUnrelOps[firstUnrelPendingOp];	
    }
  }

  void deleteFirstPendingOp(bool reliable) {
    
    if (reliable && currentRelPendingOps > 0) {
      mydbg (DBG_USR1, "Deleting reliable pending operation %d\n", 
	     pendingRelOps[firstRelPendingOp].operationId.commandId);
      firstRelPendingOp = (firstRelPendingOp+1) % MAX_PENDING_OPS;
      currentRelPendingOps--;
    } else {
      mydbg (DBG_USR1, "Deleting unreliable pending operation %d\n", 
	     pendingUnrelOps[firstUnrelPendingOp].operationId.commandId);
      firstUnrelPendingOp = (firstUnrelPendingOp+1) % MAX_PENDING_OPS;
      currentUnrelPendingOps--;
    }
  }

  command result_t StdControl.init() {

    uint8_t i;

    mydbg (DBG_USR1, "Tuple size is %d, field size is %d\n", 
	   sizeof(tuple), sizeof(field));

    firstRelPendingOp = 0;
    lastRelPendingOp = 0;
    currentRelPendingOps = 0;

    firstUnrelPendingOp = 0;
    lastUnrelPendingOp = 0;
    currentUnrelPendingOps = 0;

/*     completedOpsNum = 0; */

    localTime = 0;

    numberActiveReactions = 0;
    numberInstalledReactions = 0;
/*     numberNeighbors = 0; */

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    // Init neighbor set
    for (i=0; i<MAX_NEIGHBORS; i++) {
      neighborsId[i] = NULL_NEIGHBOR_ID;
    }

    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return call PeriodicTimer.start(TIMER_REPEAT, EPOCH);
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t DistributedTupleSpace.out(TLTarget_t target, 
					     tuple *t, 
					     TLOpId_t operationId) {
    return call SendTuple.send(target, t, 1, OUT_OP, operationId);    
  }

  command result_t DistributedTupleSpace.rd(TLTarget_t target, 
					    tuple *templ, 
					    TLOpId_t operationId) {
    addPendingOp(operationId, TRUE);

    if (!operationId.reliable) {
      call OperationTimer.start(TIMER_ONE_SHOT, EPOCH);    
    } 
    return call SendTuple.send(target, templ, 1, RD_OP, operationId);
  }
  
  command result_t DistributedTupleSpace.in(TLTarget_t target, 
					    tuple *templ, 
					    TLOpId_t operationId) {
    addPendingOp(operationId, TRUE);

    if (!operationId.reliable) {
      call OperationTimer.start(TIMER_ONE_SHOT, EPOCH);    
    }
    return call SendTuple.send(target, templ, 1, IN_OP, operationId);
  }

  command result_t DistributedTupleSpace.rdg(TLTarget_t target, 
					     tuple *templ, 
					     TLOpId_t operationId) {
    if (target!=TOS_BCAST_ADDR){
      addPendingOp(operationId, TRUE);
    } else {
      addPendingOp(operationId, FALSE);
    }
 
    if (!operationId.reliable) {
      call OperationTimer.start(TIMER_ONE_SHOT, EPOCH);    
    } 
    return call SendTuple.send(target, templ, 1, RDG_OP, operationId);
  }

  command result_t DistributedTupleSpace.ing(TLTarget_t target, 
					     tuple *templ, 
					     TLOpId_t operationId) {    
    if (target!=TOS_BCAST_ADDR){
      addPendingOp(operationId, TRUE);
    } else {
      addPendingOp(operationId, FALSE);
    }

    if (!operationId.reliable) {
      call OperationTimer.start(TIMER_ONE_SHOT, EPOCH);    
    } 
    return call SendTuple.send(target, templ, 1, ING_OP, operationId);
  }

  command result_t DistributedTupleSpace.addReaction(TLTarget_t target, 
						     tuple *templ, 
						     TLOpId_t operationId){
      return addActiveReaction(operationId, templ, target);    
  }

  command result_t DistributedTupleSpace.removeReaction(TLOpId_t operationId) {
    mydbg (DBG_USR1, "Removing active reaction\n");
    return removeActiveReaction(operationId);    
  }

  event result_t BridgeTupleSpace.tupleReady(TLOpId_t operationId, 
					     tuple *tuples, 
					     uint8_t number, 
					     bool reaction){
    uint8_t i;
    tuple toBeSent[MAX_TUPLES_MSG];

    for (i=0; i<MAX_TUPLES_MSG && i<number; i++) {
      toBeSent[i] = tuples[i];
    }

    // In case of reliable operations, an empty tuple is always sent back
    if (number == 0 && operationId.reliable) {
      dbg(DBG_USR1, "Inserting empty tuple.\n");
      toBeSent[i++] = emptyTuple();
    }

    if (i>0) {
      if (!reaction) {
        call SendTuple.send(operationId.msgOrigin, toBeSent, i, 
			    QUERY_RESULT, operationId);
      } else {
        call SendTuple.send(operationId.msgOrigin, toBeSent, i, 
			    REACTION_FIRING, operationId);
      }        
    }
    return SUCCESS;
  }

  bool isNeighbor(TLTarget_t deviceId) {
    uint8_t i;

    for (i=0; i<MAX_NEIGHBORS; i++) {
      if (neighborsId[i] != NULL_NEIGHBOR_ID
	  && neighborsId[i] == deviceId) {
        return TRUE;
      }
    }
    return FALSE;
  }

  void prunePendingOperation(bool reliable) {

    pendingOp firstOp = getFirstPendingOp(reliable);
    if (!firstOp.completed) {
      mydbg (DBG_USR1, "Pending operation has not yet completed\n");
      signalCompletion(firstOp.operationId);
    } 
    deleteFirstPendingOp(reliable);
  }

  event result_t OperationTimer.fired() {
    // For unreliable ops, the timeout signals the operation completion
    prunePendingOperation(FALSE); 
    return SUCCESS;
  }

  event result_t ReceiveTuple.operationCompleted(TLOpId_t operationId) {

    // For unreliable ops, the timeout signals the operation completion
    prunePendingOperation(TRUE); 
    return SUCCESS;

/*     uint8_t i; */
/*     bool found; */
/*     pendingOp firstOp; */

/*     // For reliable ops, an event from TeenyLimeSerializer  */
/*     // signals the operation completion */
/*     mydbg (DBG_USR1, "Reliable operation completed\n"); */
/*     completedOps[completedOpsNum++] = operationId; */

/*     do { */
/*       found = FALSE; */
/*       firstOp = getFirstPendingOp(TRUE); */
/*       mydbg (DBG_USR1, "firstOp %d\n", firstOp.operationId.commandId); */
/*       mydbg (DBG_USR1, "operationId %d\n",operationId.commandId); */
/*       for (i=0; i<completedOpsNum; i++) { */
/*         // Reliable out operations must not be notified to the application */
/*         if (isPending(completedOps[i])  */
/* 	    && firstOp.operationId.commandId == completedOps[i].commandId) { */
/*           mydbg (DBG_USR1, "Pruning operation %d\n", */
/* 		 firstOp.operationId.commandId);     */
/*           prunePendingOperation(TRUE); */
/*           completedOps[i] = completedOps[--completedOpsNum];  */
/*           found = TRUE; */
/*           continue; */
/*         } */
/*       }  */
/*     } while (found); */
/*     return SUCCESS; */
  }

  event result_t PeriodicTimer.fired() {

    uint8_t i;

    localTime++;    
    call Leds.yellowToggle();

    // Refreshing remote reactions
    for (i=0; i<numberActiveReactions; i++) {
      call SendTuple.send(activeReactions[i].target, 
			  &(activeReactions[i].templ), 1, 
			  REACT, activeReactions[i].operationId); 
      mydbg(DBG_USR1, "Operation id reliable %d\n", 
	    activeReactions[i].operationId.reliable);
    }

    // Pruning the TeenyLIME system
    pruneTeenyLIMESystem();
    
    // Pruning expired reactions
    pruneExpiredReactions();

    return SUCCESS;
  }

  event result_t SendTuple.sendDone(TLOpId_t operationId, result_t success) {
    return SUCCESS;
  }

  event result_t ReceiveTuple.receive(tuple* tuples, uint8_t tupleNumber, 
				      msg_t operation, TLOpId_t operationId) {

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
      mydbg (DBG_USR1, "Rdg operation received\n");
      call BridgeTupleSpace.rdg(tuples, operationId);
      break;
      
    case ING_OP:
      call BridgeTupleSpace.ing(tuples, operationId);
      break;
      
    case REACT:
      if (!isInstalledReaction(operationId)) {
	addInstalledReaction(operationId);
	call BridgeTupleSpace.addReaction(tuples, operationId);
      }
      refreshInstalledReaction(operationId);
      break;
      
    case QUERY_RESULT:
      addResultTuples(operationId, tuples, tupleNumber);
      if (isSingleAnswer(operationId)
	  && !isCompleted(operationId)) {
	signalCompletion(operationId);
      }
      break;
      
    case REACTION_FIRING:
      signal DistributedTupleSpace.tupleReady(operationId, tuples, 1); 	  
      break;
      
    default:
    }
  
    return SUCCESS;
  }

  command tuple* NeighborSystem.getNeighborTuple() {
    return call BridgeTupleSpace.getNeighborTuple();
  }

/*   command TLTarget_t* NeighborSystem.getNeighborsId() { */
/*     return neighborsId; */
/*   } */

  command result_t NeighborSystem.update(TLTarget_t msgOrigin, 
					 tuple neighborTuple) {
    uint8_t i;    
    bool insertion = FALSE;

    if (!isNeighbor(msgOrigin)) {
      for (i=0; i<MAX_NEIGHBORS && !insertion; i++) {
	if (neighborsId[i] == NULL_NEIGHBOR_ID) {
	  mydbg(DBG_USR1, "Adding new neighbor %d to TLSystem\n", msgOrigin); 
	  neighborsId[i] = msgOrigin;
	  neighborSet[i].nghTuple = neighborTuple;
	  neighborSet[i].lastSeen = localTime;
/* 	  numberNeighbors++; */
	  call BridgeTupleSpace.out(&(neighborSet[i].nghTuple), 
				    teenyLimeSystemOp);
	  insertion = TRUE;
	}
      }
      if (!insertion) {
	mydbg(DBG_ERROR, "No more space to add a new neighbor!\n");
      }
    } else {
      for (i=0; i<MAX_NEIGHBORS; i++) {
        if (neighborsId[i] != NULL_NEIGHBOR_ID
	    && neighborsId[i] == msgOrigin) {
          call BridgeTupleSpace.remove(&(neighborSet[i].nghTuple));
	  neighborSet[i].lastSeen = localTime; 
          neighborSet[i].nghTuple = neighborTuple;   
          call BridgeTupleSpace.out(&(neighborSet[i].nghTuple), 
				    teenyLimeSystemOp);
	} 
      }
    }
    return SUCCESS;
  }
}
