/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 295 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:19:43 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalTeenyLime.nc 295 2008-02-26 18:19:43Z lmottola $
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

#include "TupleSpace.h"
#include "TLDebug.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * The component managing the multiset of locally stored tuples.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module LocalTeenyLime {

  provides {
    interface Init;
    interface LocalTupleSpace;
    interface BridgeTupleSpace;
  }

  uses {
    interface Boot;
    interface AMPacket;
    interface Timer<TMilli> as LogicalTime;
    interface TLDebug;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  // Storing the tuples
  tuple tuples[MAX_TUPLES];

  // Logical time stamp for freshness
  uint16_t logicalTime = 0;

  // Data structure to store local reactions
  struct localReaction_t {
    TLOpId_t operationId;
    tuple templ;
    bool onlyOnce;
  };
  struct localReaction_t localReactions[MAX_REACTIONS];
  uint8_t nextLocalReactionSlot = 0;

  // Identifier for TeenyLIME system operations
  TLOpId_t teenyLimeSystemOp;

  // The current neighbor tuple
  tuple nghTuple;

  uint8_t nrTuples() {

    uint8_t i,count = 0;

    for(i = 0; i < MAX_TUPLES; i++) {
      if(isEmptyTuple(&(tuples[i])) == FALSE) {
        count++;
      }
    }
    return count;
  }

  bool findTuple(tuple *key, tuple **result) {

    int i;
    bool found = FALSE;

    for(i = 0; i < MAX_TUPLES; i++) {
      if (compareTuples(key, &(tuples[i]), logicalTime) == TRUE) {
        *result = &(tuples[i]);
        found = TRUE;
        if (!isCapabilityTuple(*result)) {
          break;
        }
      }
    }
    return found;
  }

  uint8_t findTuples(tuple *key, tuple* result) {

    int i;
    uint8_t number = 0;

    for(i = 0; i < MAX_TUPLES && number < MAX_RETURN_TUPLES; i++) {
      if(compareTuples(key, &(tuples[i]),logicalTime) == TRUE) {
        copyTuple(&(result[number]), &(tuples[i]));
        number++;
      }
    }

    return number;
  }

  uint8_t findEraseTuples(tuple *key, tuple* result) {

    int i;
    uint8_t number = 0;

    for(i = 0; i < MAX_TUPLES && number < MAX_RETURN_TUPLES; i++) {
      if(compareTuples(key, &(tuples[i]),logicalTime) == TRUE) {
        copyTuple(&(result[number]), &(tuples[i]));
	tuples[i] = emptyTuple();
        number++;
      }
    }

    return number;
  }

  void triggerReactions(tuple* t) {

    uint8_t i;
    struct localReaction_t reactionSnapshot[MAX_REACTIONS];
/*     struct localReaction_t* aliveReactions[MAX_REACTIONS]; */
/*     uint8_t numberAlive = 0; */
    bool match;   

    atomic {

      for (i=0; i<nextLocalReactionSlot; i++) {
	reactionSnapshot[i].onlyOnce = localReactions[i].onlyOnce;
	reactionSnapshot[i].operationId.commandId = localReactions[i].operationId.commandId;
	reactionSnapshot[i].operationId.componentId = localReactions[i].operationId.componentId;
	reactionSnapshot[i].operationId.reliable = localReactions[i].operationId.reliable;
	reactionSnapshot[i].operationId.msgOrigin = localReactions[i].operationId.msgOrigin;
	copyTuple(&(reactionSnapshot[i].templ), &(localReactions[i].templ));
      }

      for (i=0; i<nextLocalReactionSlot; i++) {
	match = compareTuples(&(reactionSnapshot[i].templ), t, logicalTime);
	if (match) {
	  if (reactionSnapshot[i].operationId.msgOrigin == call AMPacket.address()) {
	    if (isCapabilityTuple(t)) { // TODO: (Luca) I don't understand this...
	      signal LocalTupleSpace.
		reifyCapabilityTuple(t, reactionSnapshot[i].operationId);
	    } else {
	      signal LocalTupleSpace.
		tupleReady(reactionSnapshot[i].operationId, t, 1);
	    }
	  } else {
	    if (isCapabilityTuple(t)) { // TODO: (Luca) See above...
	      signal LocalTupleSpace.
		reifyCapabilityTuple(t, reactionSnapshot[i].operationId);
	    } else {
	      if (reactionSnapshot[i].onlyOnce) {
		// Only once reactions are used for capability tuples
		signal BridgeTupleSpace.
		  tupleReady(reactionSnapshot[i].operationId, t, 1, FALSE);
	      } else {
		signal BridgeTupleSpace.
		  tupleReady(reactionSnapshot[i].operationId, t, 1, TRUE);
	      }
	    }
	  }
	}

	// TODO: Feature to be tested for capability tuples
	// If the reaction fired and it is onlyOnce, we should delete it
/* 	if (!match  */
/* 	    || !reactionSnapshot[i].onlyOnce) { */
/* 	  aliveReactions[numberAlive++] = &(reactionSnapshot[i]); */
/* 	} */
      }
      /*       for (i=0; i<numberAlive; i++) { */
      /* 	reactionSnapshot[i] = *aliveReactions[i]; */
      /*       } */
      /*       nextLocalReactionSlot = numberAlive; */
    }
  }

  void localOut(tuple *t) {

    int i;
    
    atomic {
      for(i = 0; i < MAX_TUPLES; i++) {
	if(isEmptyTuple(&(tuples[i])) == TRUE) {
	  copyTuple(&(tuples[i]),t);
	  tuples[i].logicalTime = logicalTime;
	  triggerReactions(t);
	  return;
	}
      }
    }
    call TLDebug.triggerErr(TUPLE_SPACE_FULL);
  }

  // Replace an existing tuple with a new, or insert the new one in 
  // case the old tuple is not in the tuple space
  void replaceTuple(tuple *old, tuple* t) {

    tuple* temp;
    atomic {
      if(findTuple(old, &temp) == TRUE) {
	copyTuple(temp, t);
	triggerReactions(t);
      } else {
	localOut(t);
      }
    }
  }

  error_t insertReaction(tuple *templ, TLOpId_t *operationId, bool onlyOnce) {

    if (nextLocalReactionSlot > MAX_REACTIONS) {
      return FAIL;
    } else {
      atomic {
	localReactions[nextLocalReactionSlot].operationId.commandId = operationId->commandId;
	localReactions[nextLocalReactionSlot].operationId.reliable = operationId->reliable;
	localReactions[nextLocalReactionSlot].operationId.componentId = operationId->componentId;
	localReactions[nextLocalReactionSlot].operationId.msgOrigin = operationId->msgOrigin;
	copyTuple(&(localReactions[nextLocalReactionSlot].templ),templ);
	localReactions[nextLocalReactionSlot].onlyOnce = onlyOnce;
	nextLocalReactionSlot++;
	
	return SUCCESS;
      }
    }
  }

  command error_t Init.init() {

    uint8_t i;

    for(i = 0; i < MAX_TUPLES; i++) {
      tuples[i] = emptyTuple();
    }

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    // Inserting fake neighbor tuple
    atomic {
      nghTuple = newTuple(1, actualField_uint16(call AMPacket.address()));
      localOut(&nghTuple);
    }

    return SUCCESS;
  }

  event void Boot.booted() {
    call LogicalTime.startPeriodic(EPOCH);
  }

  command error_t LocalTupleSpace.out(tuple *t, TLOpId_t operationId) {

    localOut(t);
    return SUCCESS;
  }

  command error_t BridgeTupleSpace.out(tuple *t, TLOpId_t operationId) {

    if (operationId.commandId == TEENYLIME_SYSTEM_OPERATION) {
      dbg("DBG_USR1", "TeenyLIME system inserting tuple\n");
    } else {    
      dbg("DBG_USR1", "Remote out op\n");
    }
    localOut(t);
    return SUCCESS;
  }

  command error_t BridgeTupleSpace.rd(tuple *templ, TLOpId_t operationId) {

    tuple* result = NULL;

    atomic {
      if (findTuple(templ, &result) == TRUE) {
	if (isCapabilityTuple(result)) {
	  
	  // TODO: Feature to be tested for capability tuples
	  // The reactions serves to direct the actual tuple once output
	  /* 	  	  insertReaction(templ, operationId, TRUE); */
	  /* signal LocalTupleSpace.reifyCapabilityTuple(result, operationId); */
	} else {
	  signal BridgeTupleSpace.tupleReady(operationId, result, 1, FALSE);
	}
      } else {
	signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
      }
      return SUCCESS;
    }
  }

  command error_t LocalTupleSpace.rd(tuple *templ, TLOpId_t operationId) {

    tuple* result;

    atomic {
      if(findTuple(templ, &result) == TRUE) {
	signal LocalTupleSpace.tupleReady(operationId, result, 1);
      } else {
	signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
      }
    }
    return SUCCESS;
  }

  command error_t BridgeTupleSpace.in(tuple *templ, TLOpId_t operationId) {

    tuple* result = NULL;

    atomic {

      if (findTuple(templ, &result) == TRUE) {
	if (!isCapabilityTuple(result)) {
	  signal BridgeTupleSpace.tupleReady(operationId, result, 1, FALSE);
	  *result = emptyTuple();
	}
      } else {
	signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
      }
      return SUCCESS;
    }
  }

  command error_t BridgeTupleSpace.remove(tuple *templ) {
    
    tuple* result = NULL;

    atomic {
      if(findTuple(templ, &result) == TRUE) {
	*result = emptyTuple();
      }
      return SUCCESS;
    }
  }

  command error_t BridgeTupleSpace.replace(tuple* old, tuple *t) {
    
    replaceTuple(old, t);
    return SUCCESS;
  }

  command error_t LocalTupleSpace.in(tuple *templ, TLOpId_t operationId) {

    tuple* result = NULL;

    atomic {
      if(findTuple(templ, &result) == TRUE) {
	signal LocalTupleSpace.tupleReady(operationId, result, 1);
	*result = emptyTuple();
      } else {
	signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
      }
    }
    return SUCCESS;
  }

  command error_t BridgeTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {

    tuple result[MAX_RETURN_TUPLES];
    tuple returning[MAX_RETURN_TUPLES];
    uint8_t i, number, returningNumber = 0;

    atomic {
      number = findTuples(templ, result);
      if(number > 0) {
	// Filtering out capability tuples
	for (i = 0; i < number; i++) {
	  if (isCapabilityTuple(&(result[i]))) {
	    // TODO: Feature to be tested for capability tuples
/* 	    // The reactions serves to direct the actual tuple once output */
/* 	    insertReaction(templ, operationId, TRUE); */
/* 	    signal LocalTupleSpace.reifyCapabilityTuple(result[i], operationId); */
	  } else {
	    copyTuple(&(returning[returningNumber++]), &(result[i]));
	  }
	}
	signal BridgeTupleSpace.tupleReady(operationId, returning,
					   returningNumber, FALSE);
      } else {
	signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
      }
      return SUCCESS;
    }
  }

  command error_t LocalTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {

    tuple result[MAX_RETURN_TUPLES];
    uint8_t number;

    atomic {
      number = findTuples(templ, result);
      if(number > 0) {
	// TODO: Feature to be tested for capability tuples
/* 	for (i = 0; i < number; i++) { */
/* 	  if (isCapabilityTuple(result[i])) { */
/* 	    // The reactions serves to direct the actual tuple once output */
/* 	    //	    insertReaction(templ, operationId, TRUE); */
/* 	    signal LocalTupleSpace.reifyCapabilityTuple(result[i], operationId); */
/* 	  } */
/* 	} */
	signal LocalTupleSpace.tupleReady(operationId, result, number);
      } else {
	signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
      }   
      return SUCCESS;
    }
  }


  command error_t LocalTupleSpace.ing(tuple *templ, TLOpId_t operationId) {

    tuple result[MAX_RETURN_TUPLES];
    uint8_t number;

    atomic {
      number = findEraseTuples(templ, result);
      if(number > 0) {
	signal LocalTupleSpace.tupleReady(operationId, result, number);
      } else {
	signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
      } 
      return SUCCESS;
    }
  }

  command error_t BridgeTupleSpace.ing(tuple *templ, TLOpId_t operationId) {

    tuple result[MAX_RETURN_TUPLES];
    uint8_t number;

    atomic {
      number = findEraseTuples(templ, result);
      if(number > 0) {

	// TODO: Feature to be tested for capability tuples
	// Getting rid of capability tuples
/* 	for (i=0; i<number; i++){ */
/* 	  if (!isCapabilityTuple(result[i])) { */
/* 	    tempResult[tempNumber++] = result[i]; */
/* 	  } */
/* 	} */
/* 	for (i=0; i<tempNumber; i++){ */
/* 	  result[i] = tempResult[i]; */
/* 	} */
/* 	number = tempNumber; */
	
	signal BridgeTupleSpace.tupleReady(operationId, result, number, FALSE);
      } else {
	signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
      }
      return SUCCESS;
    }
  }

  command bool LocalTupleSpace.isLocalReaction(TLOpId_t reactionId) {

    uint8_t i;
    
    for (i=0; i<nextLocalReactionSlot; i++){
      if (localReactions[i].operationId.commandId == reactionId.commandId
	  && localReactions[i].operationId.msgOrigin == call AMPacket.address()) {
	return TRUE;
      }
    }
    return FALSE;
  }

  command error_t LocalTupleSpace.addReaction(tuple *templ,
					      TLOpId_t *operationId) {
    return insertReaction(templ, operationId, FALSE);
  }

  command error_t BridgeTupleSpace.addReaction(tuple *templ,
            TLOpId_t *operationId) {
    return insertReaction(templ, operationId, FALSE);
  }

  error_t deleteReaction(TLOpId_t operationId) {

    uint8_t i;
    
    atomic {

      for (i=0; i<nextLocalReactionSlot; i++){
	if (localReactions[i].operationId.commandId == operationId.commandId
	    && localReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	  localReactions[i] = localReactions[--nextLocalReactionSlot];
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  command error_t LocalTupleSpace.removeReaction(TLOpId_t operationId) {

    return deleteReaction(operationId);
  }

  command error_t BridgeTupleSpace.removeReaction(TLOpId_t operationId) {

    return deleteReaction(operationId);
  }

  command tuple* BridgeTupleSpace.getNeighborTuple() {

    return &nghTuple;
  }

  void pruneExpiredTuples() {
    int i;

    atomic {
      for(i = 0; i < MAX_TUPLES; i++) {
	if (tuples[i].expireIn!=TIME_UNDEFINED
	    && tuples[i].logicalTime + tuples[i].expireIn <= logicalTime) {
	  dbg ("DBG_USR1", "Removing expired tuple\n");
	  tuples[i] = emptyTuple();
	}
      }
    }
  }

  event void LogicalTime.fired() {

    tuple newNghTuple;
    atomic {
      logicalTime = (logicalTime + 1) % 0xFFFF;
      
      // Prune expired tuples
      pruneExpiredTuples();
      
      // Replaces the local neighbor tuple
      newNghTuple = *(signal LocalTupleSpace.reifyNeighborTuple());
      
      replaceTuple(&nghTuple, &newNghTuple);  
      copyTuple(&nghTuple, &newNghTuple);
      
      signal BridgeTupleSpace.timeTick();
    }
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
