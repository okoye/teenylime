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
 * *	$Id: LocalTeenyLime.nc 894 2009-09-07 17:03:39Z sguna $
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

#include "tl_objs.h"
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
#ifdef FLASH_SYNC_TIME
    interface RunOp;
#endif
    interface BridgeTupleSpace;
    interface TeenyLIMEExceptions;
  }

  uses {
    interface Boot;
    interface AMPacket;
    interface Timer<TMilli> as LogicalTime;
    interface TLDebug;
    interface SlabAllocator;
#ifdef FLASH_SYNC_TIME
    interface FlashOperations;
    interface SlabAllocator as FlashAllocator;
#endif
    interface TLObjects;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  // Logical time stamp for freshness
  uint16_t logicalTime = 0;

  // Data structure to store local reactions
  struct localReaction_t {
    TLOpId_t operationId;
    tuple *templ;
    bool onlyOnce;
  };
  struct localReaction_t localReactions[MAX_REACTIONS];
  uint8_t nextLocalReactionSlot = 0;

  // Identifier for TeenyLIME system operations
  TLOpId_t teenyLimeSystemOp;

  // The current neighbor tuple
  tuple *nghTuple;
  
  // Buffer used by remote flash operations
  char flash_buffer[SLAB_SIZE], *flash_offset;
  uint8_t flash_op;
  TLOpId_t flash_opId;
  tuple *flash_tuple;
  int flash_count;

#ifdef FLASH_SYNC_TIME
  bool flash_init = FALSE;
#endif

  void triggerReactions(tuple* t, TupleIterator *iterator) {

    uint8_t i, snapshot_size;
    struct localReaction_t reactionSnapshot[MAX_REACTIONS];
    bool match;

    atomic {
      snapshot_size = nextLocalReactionSlot;

      for (i = 0; i < snapshot_size; i++) {
	reactionSnapshot[i].onlyOnce = localReactions[i].onlyOnce;
	reactionSnapshot[i].operationId.commandId = 
	  localReactions[i].operationId.commandId;
	reactionSnapshot[i].operationId.componentId = 
	  localReactions[i].operationId.componentId;
	reactionSnapshot[i].operationId.reliable = 
	  localReactions[i].operationId.reliable;
	reactionSnapshot[i].operationId.msgOrigin = 
	  localReactions[i].operationId.msgOrigin;
	reactionSnapshot[i].templ 
	  = call SlabAllocator.addTuple(localReactions[i].templ, 
					 FALSE, FALSE, NULL);
	if (reactionSnapshot[i].templ == NULL) {
      uint16_t j;
      for (j = 0; j < i; j++)
        call SlabAllocator.removeExactTuple(reactionSnapshot[j].templ);
	  signal TeenyLIMEExceptions.exception(TS_FULL, NULL);
	  call TLDebug.triggerErr(TUPLE_SPACE_FULL);
	  return;
	}
      }

      for (i = 0; i < snapshot_size; i++) {
	// TODO, logicalTime
	match = call TLObjects.compare_tuple(reactionSnapshot[i].templ, t);
	if (match) { 
	  if (reactionSnapshot[i].operationId.msgOrigin == 
	      call AMPacket.address()) {
	    if (isCapabilityTuple(t)) { // TODO: (Luca) I don't understand this...
	      signal LocalTupleSpace.
		reifyCapabilityTuple(t, reactionSnapshot[i].operationId);
	    } else {
          TupleIterator it_copy;
          memcpy(&it_copy, iterator, sizeof(TupleIterator));
	      signal LocalTupleSpace.
		tupleReady(reactionSnapshot[i].operationId, &it_copy);
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
      for (i = 0; i < snapshot_size; i++)
        call SlabAllocator.removeExactTuple(reactionSnapshot[i].templ);
    }
  }
  
  tuple * localOut(tuple *t, bool can_delete, bool can_match) {
    tuple *new_tuple;
    // special iterator for reactions: returns the added tuple
    TupleIterator iterator;

    atomic {
      t->logicalTime = logicalTime;
#ifdef FLASH_SYNC_TIME
      if (t->flags & FLAG_PERSISTENT) {
        call FlashAllocator.addTuple(t, can_delete, can_match, NULL);
        return NULL;
      }
#endif
      new_tuple = call SlabAllocator.addTuple(t, can_delete, can_match,
              &iterator);
      if (new_tuple != NULL) {
        char tuple_snapshot[MAX_TUPLE_SIZE];
        call TLObjects.copy_tuple((tuple *) tuple_snapshot, new_tuple);
        if (can_match)
          triggerReactions((tuple *) tuple_snapshot, &iterator);
        return new_tuple;
      }
    }
    signal TeenyLIMEExceptions.exception(TS_FULL, t);
    call TLDebug.triggerErr(TUPLE_SPACE_FULL);
    return NULL;
  }

  // Replace an existing tuple with a new, or insert the new one in 
  // case the old tuple is not in the tuple space
  tuple * replaceTuple(tuple *old, tuple* t, bool can_delete, bool can_match) {
    TupleIterator iterator;
    atomic {
      error_t status =
        call SlabAllocator.replaceTuple(old, t, &iterator);
      if (status == SUCCESS) {
        triggerReactions(old, &iterator);
        return old;
      }
      // If the type of the new tuple is not the same with the type of the
      // old tuple, replace_tuple will fail. The old tuple must be
      // explicitely removed.
      call SlabAllocator.removeExactTuple(old);
      return localOut(t, can_delete, can_match);
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
	localReactions[nextLocalReactionSlot].templ =
	  call SlabAllocator.addTuple(templ, FALSE, FALSE, NULL);
	if (localReactions[nextLocalReactionSlot].templ == NULL) {
	  signal TeenyLIMEExceptions.exception(TS_FULL, templ);
	  call TLDebug.triggerErr(TUPLE_SPACE_FULL);
	  return FAIL;
	}
	localReactions[nextLocalReactionSlot].onlyOnce = onlyOnce;
	nextLocalReactionSlot++;
	
	return SUCCESS;
      }
    }
  }

  void init_iterator(TupleIterator *iterator, tuple *pattern, int flags) {
    iterator->pattern = pattern;
    iterator->data.slab.id = -1;
    iterator->data.slab.obj = 0;
    iterator->flags = flags; 
  }
 
  tuple * next_tuple(TupleIterator *iterator, TLOpId_t opId) {
    bool found;

#ifdef FLASH_SYNC_TIME
    if (iterator->pattern != NULL &&
            iterator->pattern->flags & FLAG_PERSISTENT) {
      // return some dummy tuple
      tuple *result = call SlabAllocator.getTuple(iterator);

      call FlashAllocator.removeTuple(iterator, opId);
      call FlashAllocator.nextPosition(iterator, opId, logicalTime);
      return result;
    }
#endif

    call SlabAllocator.removeTuple(iterator, opId);
    found = call SlabAllocator.nextPosition(iterator, opId, logicalTime);
    if (found)
      return call SlabAllocator.getTuple(iterator);
    return NULL;
  }

  int serialize_iterator(TupleIterator *iterator, TLOpId_t opId, char *buffer,
          int len) {
    char *offset = buffer;
    int count = 0;
    tuple *found_tuple;

    while ((found_tuple = next_tuple(iterator, opId)) != NULL) {
      int tuple_size = call TLObjects.tuple_sizeof(found_tuple);
      if (offset + tuple_size - buffer > len)
        return count;
      call TLObjects.copy_tuple((tuple *) offset, found_tuple);
      offset += tuple_size;
      count++;
    }
    return count;
  }

  command error_t Init.init() {
#ifdef FLASH_SYNC_TIME
    TLOpId_t dummyId;
    call FlashOperations.scheduleOperation(FLASH_INIT, dummyId, NULL);
#endif
    call SlabAllocator.slabInit();

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    // Inserting fake neighbor tuple
    atomic {
      tuple_0_t tmp;
      tmp.type = 0;
      tmp.match_types[0] = MATCH_ACTUAL;
      tmp.value0 = call AMPacket.address();
      tmp.flags = 0;
      nghTuple = localOut((tuple *) &tmp, FALSE, FALSE);
    }
    
    return SUCCESS;
  }
  
  event void Boot.booted() {
    call LogicalTime.startPeriodic(EPOCH);
  }

  command void LocalTupleSpace.clear() {
    call SlabAllocator.clear();
  }
  
  command void LocalTupleSpace.out(tuple *t, TLOpId_t operationId) {
    localOut(t, TRUE, TRUE);
  }

  command tuple * BridgeTupleSpace.out(tuple *t, TLOpId_t operationId,
				       bool can_delete, bool can_match) {
#ifdef FLASH_SYNC_TIME
    if (t->flags & FLAG_PERSISTENT) {
      call FlashOperations.scheduleOperation(OUT_OP, operationId, t);
      return NULL;
    }
#endif
    return localOut(t, can_delete, can_match);
  }

  command tuple *LocalTupleSpace.nextTuple(TupleIterator *iterator,
          TLOpId_t operationId) {
    return next_tuple(iterator, operationId);
  }

  command tuple *LocalTupleSpace.getTuple(TupleIterator *iterator) {
#ifdef FLASH_SYNC_TIME
    if (iterator->pattern->flags & FLAG_PERSISTENT)
      return call FlashAllocator.getTuple(iterator);
#endif
    return call SlabAllocator.getTuple(iterator);
  }

  command void BridgeTupleSpace.rd(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    char buffer[MAX_TUPLE_SIZE]; 
    int count;

    init_iterator(&iterator, templ, IT_ONE_TUPLE);

    atomic {
#ifdef FLASH_SYNC_TIME
      if (templ->flags & FLAG_PERSISTENT) {
        call FlashOperations.scheduleOperation(RD_OP, operationId, templ);
        return;
      }
#endif
      count = serialize_iterator(&iterator, operationId, buffer,
              MAX_TUPLE_SIZE);
      if (count > 0)
        signal BridgeTupleSpace.tupleReady(operationId, (tuple *) buffer,
                count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }
  }

  command void LocalTupleSpace.rd(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    init_iterator(&iterator, templ, IT_ONE_TUPLE);

    atomic {
	  signal LocalTupleSpace.tupleReady(operationId, &iterator);
    }
  }

  command void BridgeTupleSpace.in(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    char buffer[MAX_TUPLE_SIZE]; 
    int count;

    init_iterator(&iterator, templ, IT_ONE_TUPLE | IT_REMOVE);

    atomic {
#ifdef FLASH_SYNC_TIME
      if (templ->flags & FLAG_PERSISTENT) {
        call FlashOperations.scheduleOperation(IN_OP, operationId, templ);
        return;
      }
#endif
      count = serialize_iterator(&iterator, operationId, buffer,
              MAX_TUPLE_SIZE);
      if (count > 0)
        signal BridgeTupleSpace.tupleReady(operationId, (tuple *) buffer,
                count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }
  }


  command void BridgeTupleSpace.remove(tuple *addr) {
    
    atomic {
      call SlabAllocator.removeExactTuple(addr);
    }
  }

  command tuple * BridgeTupleSpace.replace(tuple* old, tuple *t,
					   bool can_delete, bool can_match) {
    return replaceTuple(old, t, can_delete, can_match);
  }
  
  command void LocalTupleSpace.in(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    init_iterator(&iterator, templ, IT_REMOVE | IT_ONE_TUPLE);
    atomic {
      signal LocalTupleSpace.tupleReady(operationId, &iterator);
    }
  }
  
  command void BridgeTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    int count;
    char buffer[SLAB_SIZE];

    init_iterator(&iterator, templ, IT_DEFAULT);
    
    atomic {
#ifdef FLASH_SYNC_TIME
      if (templ->flags & FLAG_PERSISTENT) {
        call FlashOperations.scheduleOperation(RDG_OP, operationId, templ);
        return;
      }
#endif
      count = serialize_iterator(&iterator, operationId, buffer, SLAB_SIZE);
      if (count > 0)
        signal BridgeTupleSpace.tupleReady(operationId, (tuple *) buffer,
                count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
    }
  }

  command void LocalTupleSpace.rdg(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    init_iterator(&iterator, templ, IT_DEFAULT);

    atomic {
      signal LocalTupleSpace.tupleReady(operationId, &iterator);
    }
  }


  command void LocalTupleSpace.ing(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    init_iterator(&iterator, templ, IT_DEFAULT | IT_REMOVE);

    atomic {
	  signal LocalTupleSpace.tupleReady(operationId, &iterator);
    }
  }
  
  command void BridgeTupleSpace.ing(tuple *templ, TLOpId_t operationId) {
    TupleIterator iterator;
    char buffer[SLAB_SIZE];
    int count;

    init_iterator(&iterator, templ, IT_DEFAULT | IT_REMOVE);
    
    atomic {
#ifdef FLASH_SYNC_TIME
      if (templ->flags & FLAG_PERSISTENT) {
        call FlashOperations.scheduleOperation(ING_OP, operationId, templ);
        return;
      }
#endif
      count = serialize_iterator(&iterator, operationId, buffer, SLAB_SIZE);
      if (count > 0)
        signal BridgeTupleSpace.tupleReady(operationId, (tuple *) buffer,
                count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(operationId, NULL, 0, FALSE);
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
  
  command void LocalTupleSpace.addReaction(tuple *templ,
					   TLOpId_t *operationId) {
    insertReaction(templ, operationId, FALSE);
  }
  
  command void BridgeTupleSpace.addReaction(tuple *templ,
					    TLOpId_t *operationId) {
    insertReaction(templ, operationId, FALSE);
  }
  
  error_t deleteReaction(TLOpId_t operationId) {

    uint8_t i;
    
    atomic {
      
      for (i=0; i<nextLocalReactionSlot; i++){
	if (localReactions[i].operationId.commandId == operationId.commandId
	    && localReactions[i].operationId.msgOrigin == operationId.msgOrigin) {
	  call SlabAllocator.removeExactTuple(localReactions[i].templ);
	  localReactions[i] = localReactions[--nextLocalReactionSlot];
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }
  
  command void LocalTupleSpace.removeReaction(TLOpId_t operationId) {
    deleteReaction(operationId);
  }

  command void BridgeTupleSpace.removeReaction(TLOpId_t operationId) {
    deleteReaction(operationId);
  }

  command tuple* BridgeTupleSpace.getNeighborTuple() {
    return nghTuple;
  }

  command void LocalTupleSpace.updateNeighborTuple(tuple *t) {
    // Replaces the local neighbor tuple
    nghTuple = replaceTuple(nghTuple, t, FALSE, FALSE);  
  }

  event void LogicalTime.fired() {

    tuple *newNghTuple;
    atomic {
      logicalTime = (logicalTime + 1) % 0xFFFF;
      
      // Prune expired tuples
      call SlabAllocator.pruneExpiredTuples(logicalTime);
      
      // Replaces the local neighbor tuple
      newNghTuple = signal LocalTupleSpace.reifyNeighborTuple();
      nghTuple = replaceTuple(nghTuple, newNghTuple, FALSE, FALSE);  
      
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
  
  event void SlabAllocator.slabInitDone() { }

  event void SlabAllocator.clearDone() { }

  event void SlabAllocator.addTupleDone(error_t error, tuple *t,
          TupleIterator *iterator) { }
  
  event void SlabAllocator.nextPositionDone(TupleIterator *iterator,
          TLOpId_t opId, bool found, error_t error) { }
 
#ifdef FLASH_SYNC_TIME
  event void FlashAllocator.slabInitDone() {
    call FlashOperations.operationCompleted();
  }

  event void FlashAllocator.clearDone() {
    call FlashOperations.operationCompleted();
  }

  event void FlashAllocator.addTupleDone(error_t error, tuple *t,
          TupleIterator *iterator) {
    if (error == SUCCESS) {
      triggerReactions(t, iterator);
    }
    call FlashOperations.operationCompleted();
  }
  
  event void FlashAllocator.nextPositionDone(TupleIterator *iterator,
          TLOpId_t opId, bool found, error_t error) {
    tuple *found_tuple;
    int tuple_size;
      
    if (opId.msgOrigin == call AMPacket.address()) {
      /* We either found a tuple or exhausted the persistent tuple space.
       * Signal this to the application, which will call getTuple to fetch
       * the tuple. */
      signal LocalTupleSpace.tupleReady(opId, iterator);
      call FlashOperations.operationCompleted();
      return;
    }

    if (found == FALSE) {
      if (flash_count > 0)
        signal BridgeTupleSpace.tupleReady(opId, (tuple *) flash_buffer,
                flash_count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(opId, NULL, 0, FALSE);
      call FlashOperations.operationCompleted();
      return;
    }
    found_tuple = call FlashAllocator.getTuple(iterator);
    tuple_size = call TLObjects.tuple_sizeof(found_tuple);
    if (flash_offset + tuple_size - flash_buffer > SLAB_SIZE) {
      if (flash_count > 0)
        signal BridgeTupleSpace.tupleReady(opId, (tuple *) flash_buffer,
                flash_count, FALSE);
      else
        signal BridgeTupleSpace.tupleReady(opId, NULL, 0, FALSE);
      call FlashOperations.operationCompleted();
      return;
    }

    call TLObjects.copy_tuple((tuple *) flash_offset, found_tuple);

    flash_offset += tuple_size;
    flash_count++;
    call FlashAllocator.nextPosition(iterator, opId, logicalTime);
  }


  command void RunOp.runOperation(uint8_t operation, TLOpId_t operationId, 
          tuple *t) {
    TupleIterator iterator;
    flash_op = operation;
    flash_opId = operationId;
    flash_tuple = t;
    flash_count = 0;
    flash_offset = flash_buffer;

    switch (operation) {
      case OUT_OP:
        localOut(t, TRUE, TRUE);
        /* careful here: return immediately 'cause out does not require an 
         * iterator */
        return; 
      case RD_OP:
        init_iterator(&iterator, t, IT_ONE_TUPLE);
        break;
      case IN_OP:
        init_iterator(&iterator, t, IT_ONE_TUPLE | IT_REMOVE);
        break;
      case RDG_OP:
        init_iterator(&iterator, t, IT_DEFAULT);
        break;
      case ING_OP:
        init_iterator(&iterator, t, IT_DEFAULT | IT_REMOVE);
        break;
      case FLASH_INIT:
        call FlashAllocator.slabInit();
        return;
      case FLASH_CLEAR:
        call FlashAllocator.clear();
        return;
      default:
        return;
    }
    call FlashAllocator.nextPosition(&iterator, operationId,
            logicalTime);
  }
#endif // flash persistence functions
}
