/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 173 $
 * * DATE
 * *    $LastChangedDate: 2007-10-31 20:40:56 +0100 (Wed, 31 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TeenyLimeM.nc 173 2007-10-31 19:40:56Z bronwasser $
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
    interface Init;
  }
  uses {
    interface LocalTupleSpace;
    interface StdControl as LocalTupleSpaceControl;
    interface Init as LocalTupleSpaceInit;
    interface DistributedTupleSpace;
    interface StdControl as DistributedTupleSpaceControl;
    interface Init as DistributedTupleSpaceInit;
    interface AMPacket;
  }
}

implementation {

  uint16_t nextCommandId = 1;

  command result_t Init.init() {
    call LocalTupleSpaceInit.init();
    call DistributedTupleSpaceInit.init();
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
      currentOpId.msgOrigin = call AMPacket.address();
      currentOpId.reliable = reliable;
    }


    return currentOpId;
  }


  command TLOpId_t TupleSpace.out[uint8_t componentId](bool reliable,
                   TLTarget_t target,
                   tuple *t) {
    TLOpId_t currentOpId;
    result_t result;

    asm("createOpId0:");
    currentOpId = createNewOpId(componentId, reliable);
    asm("createOpId1:");
    if(target == call AMPacket.address()) {
      result = call LocalTupleSpace.out(t, currentOpId);
    } else {
      dbg("TeenyLimeM", "Out called for address: %d\n", target);
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

    if(target == call AMPacket.address()) {
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

    if(target == call AMPacket.address()) {
      mydbg(DBG_USR1, "IN called for local TS\n");
      result = call LocalTupleSpace.in(templ, currentOpId);
    } else {
      mydbg(DBG_USR1, "IN called for %d\n", target);
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

    if(target == call AMPacket.address()) {
      dbg("TeenyLimeM", "Rdg called for local TS\n");
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

    if(target == call AMPacket.address()) {
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
    if (target == call AMPacket.address()) {
      mydbg(DBG_USR1, "AddReaction called for local TS\n");
//      uart_puts("AddReaction called for local TS\n");
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
      dbg("TeenyLimeM", "RemoveReaction called for local TS\n");
      result = call LocalTupleSpace.removeReaction(operationId);
    } else {
      dbg("TeenyLimeM", "RemoveReaction called for distr TS\n");
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
