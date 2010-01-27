/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 185 $
 * * DATE
 * *    $LastChangedDate: 2007-11-03 13:27:51 -0500 (Sat, 03 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TeenyLimeM.nc 185 2007-11-03 18:27:51Z bronwasser $
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
    interface LocalTupleSpace as LTS;
    interface StdControl as LTSControl;
    interface Init as LTSInit;
    interface DistributedTupleSpace as DTS;
    interface StdControl as DTSControl;
    interface Init as DTSInit;
    interface AMPacket;
  }
}

implementation {

  uint16_t nextCommandId = 1;

  command result_t Init.init() {
    call LTSInit.init();
    call DTSInit.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call LTSControl.start();
    call DTSControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call LTSControl.stop();
    call DTSControl.stop();
   return SUCCESS;
  }

  void createNewOpId(TLOpId_t *opId, uint8_t componentId, bool reliable) {
    // TODO: make sure that nextCommandId != TL_OP_FAIL!!

    atomic {
      opId->msgOrigin = call AMPacket.address();
      opId->componentId = componentId;
      opId->commandId = nextCommandId++;
      opId->reliable = reliable;
    }

    return;
  }


  command void TupleSpace.out[uint8_t componentId](
                    TLOpId_t *opId, bool reliable,
                    TLTarget_t target, Tuple *t) {

    result_t result;
    asm("opid0:");
    createNewOpId(opId, componentId, reliable);
asm("opid1:");
    if(target == call AMPacket.address()) {
      result = call LTS.out(t, opId);
    } else {
      dbg("TeenyLimeM", "Out called for address: %d\n", target);
      result = call DTS.out(target, t, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
    return;
  }


  command void TupleSpace.rd[uint8_t componentId](
                    TLOpId_t *opId, bool reliable,
                    TLTarget_t target, Query *q) {

    result_t result;
    createNewOpId(opId, componentId, reliable);

    if(target == call AMPacket.address()) {
      mydbg(DBG_USR1, "Rd called for local TS\n");
      result = call LTS.rd(q, opId);
    } else {
      mydbg(DBG_USR1, "Rd called for %d\n", target);
      result = call DTS.rd(target, q, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }

  command void TupleSpace.in[uint8_t componentId](
                    TLOpId_t *opId, bool reliable,
                    TLTarget_t target, Query *q) {

    result_t result;
    createNewOpId(opId, componentId, reliable);

    if(target == call AMPacket.address()) {
      mydbg(DBG_USR1, "IN called for local TS\n");
      result = call LTS.in(q, opId);
    } else {
      mydbg(DBG_USR1, "IN called for address %d\n", target);
      result = call DTS.in(target, q, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }

  command void TupleSpace.rdg[uint8_t componentId](
                   TLOpId_t *opId, bool reliable,
                   TLTarget_t target,
                   Query *q) {

    result_t result;
    createNewOpId(opId, componentId, reliable);

    if(target == call AMPacket.address()) {
      mydbg(DBG_USR1, "Rdg called for local TS\n");
      result = call LTS.rdg(q, opId);
    } else {
      mydbg(DBG_USR1, "Rdg called for %d\n", target);
      result = call DTS.rdg(target, q, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }

  command void TupleSpace.ing[uint8_t componentId](
                   TLOpId_t *opId, bool reliable,
                   TLTarget_t target, Query *q) {

    result_t result;
    createNewOpId(opId, componentId, reliable);

    if(target == call AMPacket.address()) {
      mydbg(DBG_USR1, "Ing called for local TS\n");
      result = call LTS.ing(q, opId);
    } else {
      mydbg(DBG_USR1, "Ing called for %d\n", target);
      result = call DTS.ing(target, q, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }

  command void TupleSpace.addReaction[uint8_t componentId](
                    TLOpId_t *opId, bool reliable,
                    TLTarget_t target, Query *q){

    result_t result;
    createNewOpId(opId, componentId, reliable);

    if (target == call AMPacket.address()) {
      mydbg(DBG_USR1, "AddReaction called for local TS\n");
//      uart_puts("AddReaction called for local TS\n");
      result = call LTS.addReaction(q, opId);
    } else {
      mydbg(DBG_USR1, "AddReaction called for %d\n", target);
      result = call DTS.addReaction(target, q, opId);
    }

    if (result == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }


  command void TupleSpace.removeReaction[uint8_t componentId](TLOpId_t *opId){

    if (call LTS.removeReaction(opId) == SUCCESS) {
      dbg("TeenyLimeM", "RemoveReaction called for local TS\n");
      return;
    }
    dbg("TeenyLimeM", "RemoveReaction called for distr TS\n");
    if (call DTS.removeReaction(opId) == FAIL) {
      opId->commandId = TL_OP_FAIL;
    }
  }

  event result_t LTS.tupleReady(TLOpId_t *opId, Tuple *tuples[], uint8_t n) {
    return signal TupleSpace.tupleReady[opId->componentId](opId, tuples, n);
  }

  event result_t DTS.tupleReady(TLOpId_t *opId, Tuple *tuples[], uint8_t n) {
    return signal TupleSpace.tupleReady[opId->componentId](opId, tuples, n);
  }

  default event result_t TupleSpace.reifyCapabilityTuple[uint8_t componentId](Tuple *ct) {
    return SUCCESS;
  }

  default event result_t TupleSpace.tupleReady[uint8_t componentId](TLOpId_t *opId,
                    Tuple *tuples[], uint8_t number){
    return SUCCESS;
  }

  event result_t LTS.reifyCapabilityTuple(Tuple *ct, TLOpId_t *opId) {
    // TODO: Well, it's not entirely correct to use the componentId of a remote node
    signal TupleSpace.reifyCapabilityTuple[opId->componentId](ct);
    return SUCCESS;
  }

  command uint8_t TeenyLIMESystem.setNeighborTuple(Tuple *t) {
    return call LTS.setNeighborTuple(t);
  }
}
