/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 939 $
 * * DATE
 * *    $LastChangedDate: 2009-11-16 05:40:01 -0600 (Mon, 16 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TeenyLimeM.nc 939 2009-11-16 11:40:01Z sguna $
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

#include "TupleSpace.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * The component implementing the tuple space interface offered to the 
 * application.
 * 
 * @author Paolo Costa 
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 * 
 */

module TeenyLimeM {

  provides {
    interface Init;
    interface TupleSpace[uint8_t componentId];
    interface TeenyLIMESystem;
    interface TeenyLIMEExceptions;
  }

  uses {
#ifdef FLASH_SYNC_TIME
    interface FlashOperations;
#endif
    interface TLObjects;
    interface LocalTupleSpace;
    interface DistributedTupleSpace;
    interface TeenyLIMEExceptions as SubTeenyLIMEExceptions;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint8_t nextCommandId = 0;  

  // Operation ids for reactions must be assigned so that no two active
  // reactions have the same opId, and no operation is assigned the same opId
  // of a reaction 
  bool reactionIdMap[MAX_REACTIONS];  
  
  command error_t Init.init() {
  
    uint8_t i;
    for (i=0; i<MAX_REACTIONS; i++) {
      reactionIdMap[i] = FALSE;
    }
    return SUCCESS;
  }

  void assignReactionId(TLOpId_t *opId, uint8_t componentId, bool reliable){    
    
    uint8_t i;
    atomic {
      for (i=0; i<MAX_REACTIONS; i++) {
	if (!reactionIdMap[i]) {
	  // Found a free id
	  reactionIdMap[i] = TRUE;
	  opId->commandId = i+1; // Id 0 is reserved for TEENYLIME_SYSTEM_OPERATION
	  break;
	}
      } 
      opId->componentId = componentId;
      opId->msgOrigin = TL_LOCAL;
      opId->reliable = reliable;
    }
  }

  void recallReactionId(TLOpId_t *opId) {

    atomic {
      reactionIdMap[opId->commandId-1] = FALSE;
    }
  }

  void createNewOpId(TLOpId_t *opId, uint8_t componentId, bool reliable) {

    // MAX_REACTIONS + 1 accounts for the offset we introduced above to avoid
    // clashing with TEENYLIME_SYSTEM_OPERATION
    atomic {
      nextCommandId++;
      if (nextCommandId <= MAX_REACTIONS+1) {
	nextCommandId = MAX_REACTIONS+2;
      }
      opId->commandId = nextCommandId;  
      opId->componentId = componentId;
      opId->msgOrigin = TL_LOCAL;
      opId->reliable = reliable;  
    }
  }


  void apply_flags(TLTupleSpace_t ts, tuple *t)
  {
    t->flags &= ~(FLAG_PERSISTENT
#ifdef SECURE_TL
            | FLAG_SECURE_RECONF
#endif
            ); 

    switch (ts) {
      case FLASH_TS:
        t->flags |= FLAG_PERSISTENT;
        break;
#ifdef SECURE_TL
      case RECONF_FLASH_TS:
        t->flags |= FLAG_PERSISTENT;
        /* fall through to apply reconfigure flag */
      case RECONF_RAM_TS:
        t->flags |= FLAG_SECURE_RECONF;
        break;
#endif
    }
  }

  
  uint16_t get_ts(tuple *t)
  {
#ifdef SECURE_TL
    if (t->flags & FLAG_SECURE_RECONF) {
      if (t->flags & FLAG_PERSISTENT)
        return RECONF_FLASH_TS;
      return RECONF_RAM_TS;
    }
#endif
    if (t->flags & FLAG_PERSISTENT)
      return FLASH_TS;
    return RAM_TS;
  }


#ifdef FLASH_SYNC_TIME
  command void TupleSpace.nextSplitTuple[uint8_t componentId](TLOpId_t opId,
          TupleIterator *iterator) {
    if (iterator->pattern == NULL ||
            (iterator->pattern->flags & FLAG_PERSISTENT) == 0 ||
            (iterator->pattern->flags & IT_REMOTE) != 0)
      return;
    call LocalTupleSpace.nextTuple(iterator, opId);
  }
#endif

  command tuple * TupleSpace.nextTuple[uint8_t componentId](TLOpId_t opId,
          TupleIterator *iterator) {
#ifdef FLASH_SYNC_TIME
    if (iterator->pattern != NULL &&
            iterator->pattern->flags & FLAG_PERSISTENT)
      return NULL;
#endif
    if ((iterator->flags & IT_REMOTE) != 0)
     return call DistributedTupleSpace.nextTuple(iterator, opId);
    return call LocalTupleSpace.nextTuple(iterator, opId);
  }

  command tuple *TupleSpace.getTuple[uint8_t componentId](
          TupleIterator *iterator) {
    if ((iterator->flags & IT_REMOTE) != 0)
      return call DistributedTupleSpace.getTuple(iterator);
    return call LocalTupleSpace.getTuple(iterator);
  }

  command void TupleSpace.clear[uint8_t componentId](TLTupleSpace_t ts)
  {
    TLOpId_t dummyTL;
    if (ts == FLASH_TS) 
#ifdef FLASH_SYNC_TIME
      call FlashOperations.scheduleOperation(FLASH_CLEAR, dummyTL, NULL);
#else
      return;
#endif
    call LocalTupleSpace.clear();

  }

  command void TupleSpace.out[uint8_t componentId](TLOpId_t *opId, 
						   bool reliable, 
						   TLTarget_t target,  
                           TLTupleSpace_t ts,
						   tuple *tpl) {  
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *t = (tuple *) buffer;
      call TLObjects.copy_tuple(t, tpl);
      
      createNewOpId(opId, componentId, reliable);
      apply_flags(ts, t);

      if(target == TL_LOCAL) {
#ifdef FLASH_SYNC_TIME
        if ((t->flags & FLAG_PERSISTENT) != 0) 
          call FlashOperations.scheduleOperation(OUT_OP, *opId, t);
        else
#endif
          call LocalTupleSpace.out(t, *opId); 
      } else {
	call DistributedTupleSpace.out(target, t, *opId);
      }
    }
  }


  command void TupleSpace.rd[uint8_t componentId](TLOpId_t *opId, 
						      bool reliable, 
						      TLTarget_t target, 
                              TLTupleSpace_t ts,
						      tuple *t) {
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *templ = (tuple *) buffer;
      call TLObjects.copy_tuple(templ, t);
      
      createNewOpId(opId, componentId, reliable); 
      apply_flags(ts, templ);

      if(target == TL_LOCAL) {
#ifdef FLASH_SYNC_TIME
        if ((templ->flags & FLAG_PERSISTENT) != 0)
          call FlashOperations.scheduleOperation(RD_OP, *opId, templ);
	    else
#endif
          call LocalTupleSpace.rd(templ, *opId);
      } else {
	call DistributedTupleSpace.rd(target, templ, *opId);
      }
    }
  }

  command void TupleSpace.in[uint8_t componentId](TLOpId_t *opId, 
						      bool reliable, 
						      TLTarget_t target,
                              TLTupleSpace_t ts,
						      tuple *t) {
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *templ = (tuple *) buffer;
      call TLObjects.copy_tuple(templ, t);

      createNewOpId(opId, componentId, reliable); 
      apply_flags(ts, templ);
      
      if(target == TL_LOCAL) {
#ifdef FLASH_SYNC_TIME
        if ((templ->flags & FLAG_PERSISTENT) != 0)
          call FlashOperations.scheduleOperation(IN_OP, *opId, templ);
	    else
#endif
          call LocalTupleSpace.in(templ, *opId);
      } else {
	call DistributedTupleSpace.in(target, templ, *opId);
      }
    }
  }

  command void TupleSpace.rdg[uint8_t componentId](TLOpId_t *opId, 
						       bool reliable, 
						       TLTarget_t target, 
                               TLTupleSpace_t ts,
						       tuple *t) {
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *templ = (tuple *) buffer;
      call TLObjects.copy_tuple(templ, t);
      
      createNewOpId(opId, componentId, reliable); 
      apply_flags(ts, templ);

      if(target == TL_LOCAL) {
#ifdef FLASH_SYNC_TIME
        if ((templ->flags & FLAG_PERSISTENT) != 0)
          call FlashOperations.scheduleOperation(RDG_OP, *opId, templ);
	    else
#endif
          call LocalTupleSpace.rdg(templ, *opId);
      } else {
	call DistributedTupleSpace.rdg(target, templ, *opId);
      }
    }
  }

  command void TupleSpace.ing[uint8_t componentId](TLOpId_t *opId,
						   bool reliable, 
						   TLTarget_t target, 
                           TLTupleSpace_t ts,
						   tuple *t) {
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *templ = (tuple *) buffer;
      call TLObjects.copy_tuple(templ, t);
      
      createNewOpId(opId, componentId, reliable); 
      apply_flags(ts, templ);
      
      if(target == TL_LOCAL) {
#ifdef FLASH_SYNC_TIME
        if ((templ->flags & FLAG_PERSISTENT) != 0)
          call FlashOperations.scheduleOperation(ING_OP, *opId, templ);
	    else
#endif
	      call LocalTupleSpace.ing(templ, *opId);
      } else {
	call DistributedTupleSpace.ing(target, templ, *opId);
      }
    }
  }

  command void TupleSpace.addReaction[uint8_t componentId](TLOpId_t *opId,
							   bool reliable, 
							   TLTarget_t target,
                               TLTupleSpace_t ts,
							   tuple *t){
    atomic {
      char buffer[MAX_TUPLE_SIZE];
      tuple *templ = (tuple *) buffer;
      call TLObjects.copy_tuple(templ, t);
      
      assignReactionId(opId, componentId, reliable);
      apply_flags(ts, templ);
      
      if (target == TL_LOCAL) {
	call LocalTupleSpace.addReaction(templ, opId);
      } else {
	call DistributedTupleSpace.addReaction(target, 
					       templ, 
					       opId);
      }
    }
  }

  command void TupleSpace.removeReaction[uint8_t componentId](TLOpId_t *opId, 
							      TLOpId_t reactionId){

    atomic {
      
      createNewOpId(opId, componentId, FALSE); 
      
      if (call LocalTupleSpace.isLocalReaction(reactionId)){
	call LocalTupleSpace.removeReaction(reactionId);    
      } else {
	call DistributedTupleSpace.removeReaction(reactionId);
      }
      
      recallReactionId(&reactionId); 
    }
  }

  event void LocalTupleSpace.tupleReady(TLOpId_t operationId,
          TupleIterator *iterator) {
    signal TupleSpace.tupleReady[operationId.componentId](operationId,
            iterator);
  }

  event void DistributedTupleSpace.tupleReady(TLOpId_t operationId, 
          TupleIterator *iterator) {

    signal TupleSpace.tupleReady[operationId.componentId](operationId,
            iterator);
  }

  event void LocalTupleSpace.reifyCapabilityTuple(tuple* ct, 
						     TLOpId_t operationId) {
    signal TupleSpace.reifyCapabilityTuple[operationId.componentId](ct); 
  }

  event tuple* LocalTupleSpace.reifyNeighborTuple() {
    return signal TeenyLIMESystem.reifyNeighborTuple();
  }

  command void TeenyLIMESystem.updateNeighborTuple(tuple *t) {
    call LocalTupleSpace.updateNeighborTuple(t);
  }
  
  event void DistributedTupleSpace.operationCompleted(uint8_t completionCode, 
						      TLOpId_t operationId, 
						      TLTarget_t target,  
						      tuple* returningTuple) {

    signal TupleSpace.operationCompleted[operationId.componentId](completionCode, 
								  operationId, 
								  target,
                                  get_ts(returningTuple),
								  returningTuple);
  }

  event void SubTeenyLIMEExceptions.exception(uint8_t exceptionCode, void* data) {
  
    signal TeenyLIMEExceptions.exception(exceptionCode, data);    
  }


  // Default event to make it possible not to wire this interface if not needed
  default event void TeenyLIMEExceptions.exception(uint8_t exceptionCode, 
						  void* data) {}

  default event void TupleSpace.reifyCapabilityTuple[uint8_t componentId](tuple* ct) {
  }

  default event void TupleSpace.tupleReady[uint8_t componentId](TLOpId_t operationId, 
								TupleIterator *iterator) {
  }

  default event void TupleSpace.operationCompleted[uint8_t componentId](uint8_t completionCode, 
									TLOpId_t operationId, 
									TLTarget_t target,
                                    TLTupleSpace_t ts,
									tuple* returningTuple) {
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
