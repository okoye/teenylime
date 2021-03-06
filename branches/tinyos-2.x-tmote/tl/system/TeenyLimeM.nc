/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 271 $
 * * DATE
 * *    $LastChangedDate: 2008-02-16 11:00:50 -0600 (Sat, 16 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TeenyLimeM.nc 271 2008-02-16 17:00:50Z lmottola $
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

#include <stdint.h>

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
  }

  uses {
    interface LocalTupleSpace;
    interface DistributedTupleSpace;
    interface AMPacket;
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
	  // This id is currently not assigned
	  reactionIdMap[i] = TRUE;
	  opId->commandId = i+1; // Id 0 is reserved for TEENYLIME_SYSTEM_OPERATION
	  break;
	}
      } 
      opId->componentId = componentId;
      opId->msgOrigin = call AMPacket.address();
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
      opId->msgOrigin = call AMPacket.address();
      opId->reliable = reliable;  
    }
  }

  command void TupleSpace.out[uint8_t componentId](TLOpId_t *opId, 
						   bool reliable, 
						   TLTarget_t target, 
						   tuple *t) {
    error_t result;
    
    atomic {
      createNewOpId(opId, componentId, reliable); 
      if(target == call AMPacket.address()) {
	result = call LocalTupleSpace.out(t, *opId); 
      } else {
	result = call DistributedTupleSpace.out(target, t, *opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }


  command void TupleSpace.rd[uint8_t componentId](TLOpId_t *opId, 
						      bool reliable, 
						      TLTarget_t target, 
						      tuple *templ) {

    error_t result;

    atomic {
      createNewOpId(opId, componentId, reliable); 
      
      if(target == call AMPacket.address()) {
	result = call LocalTupleSpace.rd(templ, *opId);
      } else {
	result = call DistributedTupleSpace.rd(target, templ, *opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }

  command void TupleSpace.in[uint8_t componentId](TLOpId_t *opId, 
						      bool reliable, 
						      TLTarget_t target, 
						      tuple *templ) {

    error_t result;

    atomic {
      createNewOpId(opId, componentId, reliable); 
      
      if(target == call AMPacket.address()) {
	result = call LocalTupleSpace.in(templ, *opId);
      } else {
	result = call DistributedTupleSpace.in(target, templ, *opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }

  command void TupleSpace.rdg[uint8_t componentId](TLOpId_t *opId, 
						       bool reliable, 
						       TLTarget_t target, 
						       tuple *templ) {

    error_t result;

    atomic {
      createNewOpId(opId, componentId, reliable); 

      if(target == call AMPacket.address()) {
	result = call LocalTupleSpace.rdg(templ, *opId);
      } else {
	result = call DistributedTupleSpace.rdg(target, templ, *opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }

  command void TupleSpace.ing[uint8_t componentId](TLOpId_t *opId,
						       bool reliable, 
						       TLTarget_t target, 
						       tuple *templ) {

    error_t result;

    atomic {
      createNewOpId(opId, componentId, reliable); 
      
      if(target == call AMPacket.address()) {
	result = call LocalTupleSpace.ing(templ, *opId);
      } else {
	result = call DistributedTupleSpace.ing(target, templ, *opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }

  command void TupleSpace.addReaction[uint8_t componentId](TLOpId_t *opId,
							   bool reliable, 
							   TLTarget_t target, 
							   tuple *templ){

    error_t result;

    atomic {
      assignReactionId(opId, componentId, reliable);
      
      if (target == call AMPacket.address()) {
	result = call LocalTupleSpace.addReaction(templ, opId);
      } else {
	result = call DistributedTupleSpace.addReaction(target, 
							templ, 
							opId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }
    }
  }

  command void TupleSpace.removeReaction[uint8_t componentId](TLOpId_t *opId, 
							      TLOpId_t reactionId){

    error_t result;

    atomic {
      
      createNewOpId(opId, componentId, FALSE); 
      
      if (call LocalTupleSpace.isLocalReaction(reactionId)){
	result = call LocalTupleSpace.removeReaction(reactionId);    
      } else {
	result = call DistributedTupleSpace.removeReaction(reactionId);
      }
      
      if (result == FAIL) {
	opId->commandId = TL_OP_FAIL;
      }

      recallReactionId(&reactionId); 
    }
  }
  
  event error_t LocalTupleSpace.tupleReady(TLOpId_t operationId, 
					tuple* tuples, uint8_t number) {
    signal TupleSpace.tupleReady[operationId.componentId](operationId, 
							  tuples, 
							  number);
    return SUCCESS;
  }

  event error_t DistributedTupleSpace.tupleReady(TLOpId_t operationId, 
						  tuple* tuples, 
						  uint8_t number) {

    signal TupleSpace.tupleReady[operationId.componentId](operationId, 
							  tuples, 
							  number);
    return SUCCESS;
  }

  event error_t LocalTupleSpace.reifyCapabilityTuple(tuple* ct, 
						      TLOpId_t operationId) {
    signal TupleSpace.reifyCapabilityTuple[operationId.componentId](ct); 
    return SUCCESS;
  }

  event tuple* LocalTupleSpace.reifyNeighborTuple() {
    return signal TeenyLIMESystem.reifyNeighborTuple();
  }
  
  event void DistributedTupleSpace.tupleSpaceError(uint8_t errCode, 
						   TLOpId_t operationId, 
						   TLTarget_t target,  
						   tuple* failedTuple) {

    signal TupleSpace.tupleSpaceError[operationId.componentId](errCode, 
							       operationId, 
							       target,  
							       failedTuple);
  }

  default event void TupleSpace.reifyCapabilityTuple[uint8_t componentId](tuple* ct) {
  }

  default event void TupleSpace.tupleReady[uint8_t componentId](TLOpId_t operationId, 
								tuple* tuples, 
								uint8_t number){
  }

  default event void TupleSpace.tupleSpaceError[uint8_t componentId](uint8_t errCode, 
								     TLOpId_t operationId,
								     TLTarget_t target,  
								     tuple* failedTuple) {
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
