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
 * *	$Id: TeenyLimeM.nc 4 2007-04-27 15:22:42Z paolinux78 $
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

includes TupleSpace;

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
    interface TupleSpace[uint8_t componentId];
    interface TeenyLIMESystem;
    interface StdControl;
  }
  uses {
    interface LocalTupleSpace;
    interface StdControl as LocalTupleSpaceControl;
    interface DistributedTupleSpace;
    interface StdControl as DistributedTupleSpaceControl;
  }
}

implementation {

  uint16_t nextCommandId = 1;

  command result_t StdControl.init() {
    call LocalTupleSpaceControl.init();
    call DistributedTupleSpaceControl.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call LocalTupleSpaceControl.start();
    call DistributedTupleSpaceControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call LocalTupleSpaceControl.stop();
    call DistributedTupleSpaceControl.stop();
   return SUCCESS;
  }

  TLOpId_t createNewOpId(uint8_t componentId, bool reliable) {

    TLOpId_t currentOpId;
    atomic{
      currentOpId.componentId = componentId;
      currentOpId.commandId = nextCommandId++;
      currentOpId.msgOrigin = TOS_LOCAL_ADDRESS;
      currentOpId.reliable = reliable;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.out[uint8_t componentId](bool reliable, 
						       TLTarget_t target, 
						       tuple *t) {

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable); 

    if(target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "Out called for local TS\n");
      result = call LocalTupleSpace.out(t, currentOpId);
    } else {
      mydbg(DBG_USR1, "Out called for %d\n", target);
      result = call DistributedTupleSpace.out(target, t, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.rd[uint8_t componentId](bool reliable, 
						      TLTarget_t target, 
						      tuple *templ) {

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable); 

    if(target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "Rd called for local TS\n");
      result = call LocalTupleSpace.rd(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "Rd called for %d\n", target);
      result = call DistributedTupleSpace.rd(target, templ, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.in[uint8_t componentId](bool reliable, 
						      TLTarget_t target, 
						      tuple *templ) {

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable); 

    if(target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "In called for local TS\n");
      result = call LocalTupleSpace.in(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "In called for %d\n", target);
      result = call DistributedTupleSpace.in(target, templ, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.rdg[uint8_t componentId](bool reliable, 
						       TLTarget_t target, 
						       tuple *templ) {

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable); 

    if(target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "Rdg called for local TS\n");
      result = call LocalTupleSpace.rdg(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "Rdg called for %d\n", target);
      result = call DistributedTupleSpace.rdg(target, templ, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.ing[uint8_t componentId](bool reliable, 
						       TLTarget_t target, 
						       tuple *templ) {

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable); 

    if(target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "Ing called for local TS\n");
      result = call LocalTupleSpace.ing(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "Ing called for %d\n", target);
      result = call DistributedTupleSpace.ing(target, templ, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.addReaction[uint8_t componentId](bool reliable, 
							       TLTarget_t target, 
							       tuple *templ){

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, reliable);

    if (target == TOS_LOCAL_ADDRESS) {
      mydbg(DBG_USR1, "AddReaction called for local TS\n");
      result = call LocalTupleSpace.addReaction(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "AddReaction called for %d\n", target);
      result = call DistributedTupleSpace.addReaction(target, templ, currentOpId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }

  command TLOpId_t TupleSpace.removeReaction[uint8_t componentId](TLOpId_t operationId){

    result_t result;
    TLOpId_t currentOpId = createNewOpId(componentId, FALSE); 

    if (call LocalTupleSpace.isLocalReaction(operationId)){
      mydbg(DBG_USR1, "RemoveReaction called for local TS\n");
      result = call LocalTupleSpace.removeReaction(operationId);    
    } else {
      mydbg(DBG_USR1, "RemoveReaction called for distributed TS\n");
      result = call DistributedTupleSpace.removeReaction(operationId);
    }

    if (result == FAIL) {
      currentOpId.commandId = TL_OP_FAIL;
    }
    return currentOpId;
  }
  
  event result_t LocalTupleSpace.tupleReady(TLOpId_t operationId, 
					    tuple* tuples, uint8_t number) {
    return signal TupleSpace.tupleReady[operationId.componentId](operationId, tuples, number);
  }

  event result_t DistributedTupleSpace.tupleReady(TLOpId_t operationId, 
						  tuple* tuples, uint8_t number) {
    return signal TupleSpace.tupleReady[operationId.componentId](operationId, 
								 tuples, number);
  }

  default event result_t TupleSpace.reifyCapabilityTuple[uint8_t componentId](tuple* ct) {
    return SUCCESS;
  }

  default event result_t TupleSpace.tupleReady[uint8_t componentId](TLOpId_t operationId, 
								    tuple* tuples, 
								    uint8_t number){
    return SUCCESS;
  }

  event result_t LocalTupleSpace.reifyCapabilityTuple(tuple* ct, 
						      TLOpId_t operationId) {
    signal TupleSpace.reifyCapabilityTuple[operationId.componentId](ct); 
    return SUCCESS;
  }

  event tuple* LocalTupleSpace.reifyNeighborTuple() {
    return signal TeenyLIMESystem.reifyNeighborTuple();
  }
}
