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
 * *	$Id: LocalTeenyLime.nc 4 2007-04-27 15:22:42Z paolinux78 $
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

includes TupleSpace;

/**
 * The component managing the multiset of locally stored tuples.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

module LocalTeenyLime {
  provides {
    interface LocalTupleSpace;
    interface BridgeTupleSpace;
    interface StdControl;
  }

  uses {
    interface Timer as LogicalTime;
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
  uint8_t nextLocalReactionSlot;

  // Identifier for TeenyLIME system operations
  TLOpId_t teenyLimeSystemOp;

  // The current neighbor tuple
  tuple nghTuple;

  bool addTuple(tuple *t) {
    int i;
    
    for(i = 0; i < MAX_TUPLES; i++) { 
      if(isEmptyTuple(&(tuples[i])) == TRUE) {
	tuples[i] = *t;
	tuples[i].logicalTime = logicalTime;
	return TRUE;
      }
    }
    return FALSE;    
  }

  bool findTuple(tuple *key, tuple **result) {
    int i;
    bool found = FALSE;

    for(i = 0; i < MAX_TUPLES; i++) {
      if(compareTuples(key, &(tuples[i]),logicalTime) == TRUE) {
	*result = &(tuples[i]);
        found = TRUE;
	if (!isCapabilityTuple(*result)) { 
	  break;
	} 
      }
    }

    return found;
  }

  bool findTuples(tuple *key, tuple* result[], uint8_t *number) {
    int i;
    bool found = FALSE;
    *number = 0;

    for(i = 0; i < MAX_TUPLES; i++) {
      if(compareTuples(key, &(tuples[i]),logicalTime) == TRUE) {
	result[*number] = &(tuples[i]);
	(*number)++;
	found = TRUE;
      }
    }

    return found;
  }

  void triggerReactions(tuple* t) {
    uint8_t i;
    struct localReaction_t aliveReactions[MAX_REACTIONS];
    uint8_t numberAlive = 0;
    
    for (i=0; i<nextLocalReactionSlot; i++) {
      if (compareTuples(&(localReactions[i].templ), t, logicalTime) == TRUE) {
        if (localReactions[i].operationId.msgOrigin == TOS_LOCAL_ADDRESS) {
	  if (isCapabilityTuple(t)) {
	    signal LocalTupleSpace.
	      reifyCapabilityTuple(t, localReactions[i].operationId);  
	  } else {
	    signal LocalTupleSpace.
	      tupleReady(localReactions[i].operationId, t, 1);
	  }
	} else {
	  mydbg (DBG_USR1, "Triggering remote reaction\n");
	  if (isCapabilityTuple(t)) {
	    signal LocalTupleSpace.
	      reifyCapabilityTuple(t, localReactions[i].operationId);
	  } else {
	    if (localReactions[i].onlyOnce) {
	      // Only once reactions are used for capability tuples
	      signal BridgeTupleSpace.
		tupleReady(localReactions[i].operationId, t, 1, FALSE);
	    } else {
	      signal BridgeTupleSpace.
		tupleReady(localReactions[i].operationId, t, 1, TRUE);
	    }
	  }
	}
      }
      if (!compareTuples(&(localReactions[i].templ),t,logicalTime) 
          || !localReactions[i].onlyOnce) {
	aliveReactions[numberAlive++] = localReactions[i]; 
      } 
    }

    for (i=0; i<numberAlive; i++) {
      localReactions[i] = aliveReactions[i];
    }    
    nextLocalReactionSlot = numberAlive;
  }

#ifndef mica2
  void printTupleSpace() {
    int i;
    char tupleString[MAX_FIELDS*20];

    for(i=0; i < MAX_TUPLES; i++) {
      if(isEmptyTuple(&(tuples[i])) == FALSE) {
	printTuple(&(tuples[i]), tupleString);
	mydbg(DBG_USR1, "%s\n",tupleString);
      }
    }
  }

  void printLocalReactions() {
    uint8_t i;
    char tupleString[MAX_FIELDS*20];

    for(i=0; i < nextLocalReactionSlot; i++) {
      printTuple(&(localReactions[i].templ), tupleString);
      mydbg(DBG_USR1, "%s\n",tupleString);
    }   
  }
#endif

  result_t localOut(tuple *t, TLOpId_t operationId) {

    if(addTuple(t) == TRUE) {
      triggerReactions(t);
      return SUCCESS;
    } else
      return FAIL;
  }
  
  result_t insertReaction(tuple *templ, TLOpId_t operationId, bool onlyOnce) {

    if (nextLocalReactionSlot > MAX_REACTIONS) {
      return FAIL;
    } else {
      struct localReaction_t newReaction;
      newReaction.operationId = operationId;
      newReaction.templ = *templ;
      newReaction.onlyOnce = onlyOnce;
      localReactions[nextLocalReactionSlot++] = newReaction;
      return SUCCESS;
    }
  }

  command result_t StdControl.init() {

    uint8_t i;
    
    for(i = 0; i < MAX_TUPLES; i++) {
      tuples[i] = emptyTuple();
    }

    nextLocalReactionSlot = 0;

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    // Inserting fake neighbor tuple
    nghTuple = newTuple(1, actualField_uint16(TOS_LOCAL_ADDRESS));
    localOut(&nghTuple, teenyLimeSystemOp);

    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return call LogicalTime.start(TIMER_REPEAT, EPOCH);
  }

  command result_t StdControl.stop() {
   return SUCCESS;
  }

  command result_t LocalTupleSpace.out(tuple *t, TLOpId_t operationId) {
    mydbg(DBG_USR1, "Local out op\n");
    return localOut(t,operationId);
  }

  command result_t BridgeTupleSpace.out(tuple *t, TLOpId_t operationId) {

    if (operationId.commandId == TEENYLIME_SYSTEM_OPERATION) {
      mydbg(DBG_USR1, "TeenyLIME system inserting tuple\n");      
    } else {
      mydbg(DBG_USR1, "Remote out op\n");
    }
    return localOut(t,operationId);
  }

  command result_t BridgeTupleSpace.rd(tuple *templ, TLOpId_t operationId) {

    tuple* result;  

    if (findTuple(templ, &result) == TRUE) {
      if (isCapabilityTuple(result)) {

        // The reactions serves to direct the actual tuple once output
        insertReaction(templ, operationId, TRUE);
   	signal LocalTupleSpace.reifyCapabilityTuple(result, operationId);
      } else {
        signal BridgeTupleSpace.tupleReady(operationId, result, 1, FALSE);	
      }
    } else {
      signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }

    return SUCCESS;
  }

  command result_t LocalTupleSpace.rd(tuple *templ, TLOpId_t operationId) {

    tuple* result;  

    if(findTuple(templ, &result) == TRUE) {
      signal LocalTupleSpace.tupleReady(operationId, result, 1);
    } else {
      signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
    }

    return SUCCESS;
  }

  command result_t BridgeTupleSpace.in(tuple *templ, TLOpId_t operationId) {

    tuple* result; 
    
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

  command result_t BridgeTupleSpace.remove(tuple *templ) {

    tuple* result; 

    mydbg(DBG_USR1, "TeenyLIME removing tuple\n");      
    if(findTuple(templ, &result) == TRUE) {
      *result = emptyTuple();
    } 

    return SUCCESS;
  }

  command result_t LocalTupleSpace.in(tuple *templ, TLOpId_t operationId) {

    tuple* result; 

    if(findTuple(templ, &result) == TRUE) {
      signal LocalTupleSpace.tupleReady(operationId, result, 1);
      *result = emptyTuple();
    } else {
      signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
    }

    return SUCCESS;
  }

  command result_t BridgeTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {

    tuple* result[MAX_TUPLES]; 
    uint8_t i, number;

    if(findTuples(templ, result, &number) == TRUE) {
      for (i = 0; i < number; i++) {
        if (isCapabilityTuple(result[i])) {
          // The reactions serves to direct the actual tuple once output
          insertReaction(templ, operationId, TRUE);
   	  signal LocalTupleSpace.reifyCapabilityTuple(result[i], operationId);
	}
      }
      signal BridgeTupleSpace.tupleReady(operationId, result[0], number, FALSE);
    } else {
      signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }

    return SUCCESS;
  }

  command result_t LocalTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {

    tuple* result[MAX_TUPLES]; 
    uint8_t i, number;

    if(findTuples(templ, result, &number) == TRUE) {
      for (i = 0; i < number; i++) {
        if (isCapabilityTuple(result[i])) {
          // The reactions serves to direct the actual tuple once output
          insertReaction(templ, operationId, TRUE);
   	  signal LocalTupleSpace.reifyCapabilityTuple(result[i], operationId);
	}
      }
      signal LocalTupleSpace.tupleReady(operationId, result[0], number);
    } else {
      signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
    }

    return SUCCESS;
  }

  command result_t BridgeTupleSpace.ing(tuple *templ, TLOpId_t operationId) {

    tuple* result[MAX_TUPLES];
    tuple* tempResult[MAX_TUPLES]; 
    uint8_t i, number, tempNumber = 0;

    if(findTuples(templ, result, &number) == TRUE) {

      // Getting rid of capability tuples    
      for (i=0; i<number; i++){
        if (!isCapabilityTuple(result[i])) {
	  tempResult[tempNumber++] = result[i];
	}
      }
      for (i=0; i<tempNumber; i++){
        result[i] = tempResult[i];
      }
      number = tempNumber;
      
      signal BridgeTupleSpace.tupleReady(operationId, result[0], number, FALSE);
      for (i=0; i<number; i++){
        *result[i] = emptyTuple();
      }
    } else {
      signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }

    return SUCCESS;
  }

  command result_t LocalTupleSpace.ing(tuple *templ, TLOpId_t operationId) {

    tuple* result[MAX_TUPLES]; 
    uint8_t i, number;

    if(findTuples(templ, result, &number) == TRUE) {
      signal LocalTupleSpace.tupleReady(operationId, result[0], number);
      for (i=0; i<number; i++){
        *result[i] = emptyTuple();
      }
    } else {
      signal LocalTupleSpace.tupleReady(operationId, NULL, 0);
    }

    return SUCCESS;
  }

  command bool LocalTupleSpace.isLocalReaction(TLOpId_t reactionId) {

    uint8_t i;
    for (i=0; i<nextLocalReactionSlot; i++){
      if (localReactions[i].operationId.commandId == reactionId.commandId
         && localReactions[i].operationId.msgOrigin == TOS_LOCAL_ADDRESS) { 
        return TRUE;
      }
    }
    return FALSE;
  }

  command result_t LocalTupleSpace.addReaction(tuple *templ, 
					       TLOpId_t operationId) { 
    return insertReaction(templ, operationId, FALSE);
  }

  command result_t BridgeTupleSpace.addReaction(tuple *templ, 
						TLOpId_t operationId) {
    return insertReaction(templ, operationId, FALSE);
  }

  result_t deleteReaction(TLOpId_t operationId) {
  
    uint8_t i;

    for (i=0; i<nextLocalReactionSlot; i++){
      if (localReactions[i].operationId.commandId == operationId.commandId
          && localReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	localReactions[i] = localReactions[--nextLocalReactionSlot];
	return SUCCESS;
      }
    }
    return FAIL;
  }

  command result_t LocalTupleSpace.removeReaction(TLOpId_t operationId) {
    return deleteReaction(operationId);
  }

  command result_t BridgeTupleSpace.removeReaction(TLOpId_t operationId) {
    mydbg (DBG_USR1, "Removing remote reaction\n");
    return deleteReaction(operationId);
  }

  command tuple* BridgeTupleSpace.getNeighborTuple() {
    return &nghTuple;
  }

  void pruneExpiredTuples() {
    int i;

    for(i = 0; i < MAX_TUPLES; i++) {
      if (tuples[i].expireIn!=TIME_UNDEFINED
         && tuples[i].logicalTime + tuples[i].expireIn < logicalTime) {
 	mydbg (DBG_USR1, "Removing expired tuple\n");
	tuples[i] = emptyTuple(); 
      }
    }
  }

  event result_t LogicalTime.fired() {

    tuple* result; 

    logicalTime++;

    // Prune expired tuples
    pruneExpiredTuples();
    
    // Ask for a new node tuple
    if(findTuple(&nghTuple, &result) == TRUE) {
      *result = emptyTuple();
    }    
    nghTuple = *(signal LocalTupleSpace.reifyNeighborTuple());
    localOut(&nghTuple, teenyLimeSystemOp);

    return SUCCESS;
  }
}
