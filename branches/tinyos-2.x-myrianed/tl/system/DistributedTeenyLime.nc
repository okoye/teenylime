/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 188 $
 * * DATE
 * *    $LastChangedDate: 2007-11-04 15:26:29 -0600 (Sun, 04 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: DistributedTeenyLime.nc 188 2007-11-04 21:26:29Z bronwasser $
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

#include "TupleSpace.h"
#include "TupleMsg.h"

/**
 * The component implementing distributed operations.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module DistributedTeenyLime {

  provides {
    interface DistributedTupleSpace as DTS;
    interface StdControl;
    interface Init;
    interface NeighborSystem;
  }

  uses {
    interface TLSend;
    interface TLReceive;
    interface BridgeTupleSpace as Bridge;
    interface Timer<TMilli> as PendingOpTimer;
    interface Timer<TMilli> as EpochTimer;
    interface Leds;
    interface Init as CommInit;
    interface TinyMalloc as Mem;
  }
}

implementation {

  // Data structure to maintain remote reactions
  typedef struct activeReaction {
    list_t list;
    TLOpId_t operationId;
    TLTarget_t target;
    Query query[0];
  } activeReaction;

  // Data structure for pending remote operations
  struct pendingOp_str {
    list_t list;
    TLOpId_t operationId;
    tupleWrapper *firstTuple;
    uint8_t number;
    uint8_t countDown : 7;
    bool singleAnswer : 1;
  } PACKED;
  typedef struct pendingOp_str pendingOp;


  // Data structure for maintaining the neighbor set
  typedef struct {
    list_t list;
    TLTarget_t deviceId;
    tupleWrapper *nghTuple;
    uint16_t lastSeen;
  } neighborData;

  uint16_t localTime;
  TLOpId_t teenyLimeSystemOp;

  list_t *firstActiveReaction = NULL;
  list_t *firstUnrelPendingOp = NULL, *firstRelPendingOp = NULL;
  list_t *firstNeighbor = NULL;


  neighborData *getNeighborData(list_t *l) {
    return (neighborData *) &(l->data);
  }

  uint8_t getActiveReactionSize(Query *q) {
    return sizeof(activeReaction) + getQuerySize(q);
  }

  result_t addActiveReaction(TLOpId_t *operationId, Query *q, TLTarget_t target) {
    activeReaction *a;
    // TODO: check size we malloc here
    a = (activeReaction *) call Mem.malloc(getActiveReactionSize(q));
    if (a == NULL) return FAIL;
    a->list.next = firstActiveReaction;
    firstActiveReaction = (list_t*) a;

    a->operationId = *operationId;
    a->target = target;
    copyQuery(&(a->query[0]),q);
    return SUCCESS;
  }


  result_t removeActiveReaction(TLOpId_t *operationId) {
    activeReaction *a = (activeReaction*) firstActiveReaction;
    activeReaction *prv = (activeReaction*) firstActiveReaction;

    while (a != NULL) {
      if (a->operationId.commandId == operationId->commandId) {
        dbg("DTL","Removing active reaction\n");
        removeNextFromList((list_t **)&firstActiveReaction, (list_t*)prv, (list_t*)a);
        call Mem.free(a, sizeof(activeReaction));
        return SUCCESS;
      }
      prv = a;
      a = a->list.next;
    }
    return FAIL;
  }


  void pruneTeenyLIMESystem() {
    list_t *l = firstNeighbor, *prv = firstNeighbor;

    while (l != NULL) {
      if (getNeighborData(l)->lastSeen + NEIGHBOR_LOST_REFRESH < localTime) {
        call Bridge.remove(getNeighborData(l)->nghTuple);
        removeNextFromList(&firstNeighbor, prv, l);
        call Mem.free(l,sizeof(neighborData));
      }
      prv = l;
      l = l->next;
    }
  }

  pendingOp *getPendingOp(TLOpId_t *opId) {
    pendingOp *op;

    if (opId->reliable) {
      op = (pendingOp*)firstRelPendingOp;
    } else {
      op = (pendingOp*)firstUnrelPendingOp;
    }
    while (op != NULL) {
      if (op->operationId.commandId == opId->commandId) {
        return op;
      }
      op = (pendingOp *) op->list.next;
    }
    return NULL;
  }


  void deletePendingOp(pendingOp *op) {
    tupleWrapper *t, *nextTuple;

    // Remove operation from the list of pending ops
    if (op->operationId.reliable) {
      removeFromList((list_t **) &firstRelPendingOp, (list_t *)op);
    } else {
      removeFromList((list_t **) &firstUnrelPendingOp, (list_t *)op);
    }

    // Remove the linked tuples
    t = (tupleWrapper *) op->firstTuple;
    while (t != NULL) {
      nextTuple = (tupleWrapper *) t->list.next;
      // TODO: check real tuple size before doing free()!!
      call Mem.free(t, sizeof(tupleWrapper));
      t = nextTuple;
    }
    call Mem.free(op, sizeof(pendingOp));
  }


  void signalCompletion(pendingOp *op) {
    uint8_t i = 0;
    Tuple *tuples[op->number]; list_t *l;
    if (op->operationId.reliable) {
      mydbg(DBG_USR1, "Signalling completion of reliable operation %d\n", op->operationId.commandId);
    } else {
      mydbg(DBG_USR1, "Signalling completion of unreliable operation %d\n", op->operationId.commandId);
    }
    mydbg (DBG_USR1, "Firing event for operation %d\n", op->operationId.commandId);

    // We have to translate the linked list to an array of tuple pointers
    l = (list_t*) op->firstTuple;
    while (l != NULL) {
      tuples[i] = getTuple(l);
      l = l->next;
      i++;
    }
    signal DTS.tupleReady(&(op->operationId), tuples, op->number);
    deletePendingOp(op);
  }


  uint8_t addResultTuples(pendingOp *op, Tuple *tuples[], uint16_t number) {
    list_t *l; uint8_t j;

    if (number == 0) return SUCCESS;

    for (j = 0; j < number; j++) {
      l = (list_t*) call Mem.malloc(getTupleSize(tuples[j]));
      if (l == NULL) {
        // Returning FAIL indicates a memory problem, signalCompletion will be called.
        return FAIL;
      }
      copyTuple(getTuple(l),tuples[j]);
      l = l->next;
      op->number++;
    }
    return SUCCESS;
  }


  result_t addPendingOp(TLOpId_t *operationId, TLTarget_t target, Query *q, msg_t opType) {
    pendingOp *newOp;
    uint8_t result;

    newOp = (pendingOp *) call Mem.malloc(sizeof(pendingOp));
    if (newOp == NULL) return FAIL;

    newOp->operationId = *operationId;
    newOp->number = 0;
    newOp->firstTuple = NULL;
    if ((opType == RDG_OP || opType == ING_OP) && target != TOS_BCAST_ADDR) {
      newOp->singleAnswer = FALSE;
    } else {
      newOp->singleAnswer = TRUE;
    }
    if (operationId->reliable) {
      newOp->list.next = firstRelPendingOp;
      firstRelPendingOp = (list_t*) newOp;
      mydbg (DBG_USR1, "Adding reliable pending operation\n");
    } else {
      newOp->list.next = firstUnrelPendingOp;
      firstUnrelPendingOp = (list_t*) newOp;
      mydbg (DBG_USR1, "Adding unreliable pending operation\n");
    }
    result = call TLSend.sendQuery(target, q, opType, operationId);
    if (result == FAIL) {
      // Unable to send operation. Delete from the list.
      deletePendingOp(newOp);
    } else {
      if (!operationId->reliable) {
        newOp->countDown = PENDING_OP_TIME_OUT;
        if (!call PendingOpTimer.isRunning()) {
          // Start the timer for unreliable operations in case of success
          call PendingOpTimer.startPeriodic(PENDING_OP_TIMER_PERIOD);
        }
      }
    }
    return result;
  }


  bool isSingleAnswer(pendingOp *op) {
    return op->singleAnswer;
  }

  command result_t Init.init() {
    localTime = 0;

    // Preparing opId for TeenyLIME system
    teenyLimeSystemOp.commandId = TEENYLIME_SYSTEM_OPERATION;
    teenyLimeSystemOp.componentId = TEENYLIME_SYSTEM_COMPONENT;

    return call CommInit.init();
  }

  command result_t StdControl.start() {
    call EpochTimer.startPeriodic(EPOCH);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t DTS.out(TLTarget_t target, Tuple *t, TLOpId_t *operationId) {
    return call TLSend.sendTuples(target, &t, 1, OUT_OP, operationId);
  }

  command result_t DTS.rd(TLTarget_t target, Query *q, TLOpId_t *operationId) {
    return addPendingOp(operationId, target, q, RD_OP);
  }

  command result_t DTS.in(TLTarget_t target, Query *q, TLOpId_t *operationId) {
    return addPendingOp(operationId, target, q, IN_OP);
  }

  command result_t DTS.rdg(TLTarget_t target, Query *q, TLOpId_t *operationId) {
    return addPendingOp(operationId, target, q, RDG_OP);
  }

  command result_t DTS.ing(TLTarget_t target, Query *q, TLOpId_t *operationId) {
    return addPendingOp(operationId, target, q, ING_OP);
  }

  command result_t DTS.addReaction(TLTarget_t target, Query *q, TLOpId_t *operationId) {
    return addActiveReaction(operationId, q, target);
  }

  command result_t DTS.removeReaction(TLOpId_t *operationId) {
    // Remove outgoing reaction
    return removeActiveReaction(operationId);
  }

  event result_t Bridge.tupleReady(TLOpId_t *opId, Tuple *tuples[], uint8_t n,  bool reaction) {
    // compressing this function saved 100 bytes of program memory and some stack space.
    if (reaction) {
      return call TLSend.sendTuples(opId->msgOrigin, tuples, n, REACTION_FIRING, opId);
    } else {
      return call TLSend.sendTuples(opId->msgOrigin, tuples, n, QUERY_RESULT, opId);
    }
  }

//  bool isNeighbor(TLTarget_t deviceId) {
//    neighborData *n = firstNeighbor;
//
//    while (n != NULL) {
//      if (n->deviceId == deviceId) {
//        return TRUE;
//      }
//    }
//    return FALSE;
//  }

  event void PendingOpTimer.fired() {
    pendingOp *p = (pendingOp*) firstUnrelPendingOp, *nextOp;
    // Timer fires for unreliable operations
    while (p != NULL) {
      p->countDown--;
      // Store the next operation in the list
      // This information might be lost if signalCompletion removes the current op.
      nextOp = (pendingOp*) p->list.next;
      if (p->countDown == 0) {
        // TODO: check whether operation has been sent already, because it
        // doesn't make sense to signal completion if the message is still in the Q.
        // Using huge time outs isn't a good solution because delay gets too long.
        // Note that this an issue for multi-answer ops, where we always wait until time out.
        signalCompletion(p);
      }
      p = nextOp;
    }
    if (firstUnrelPendingOp == NULL) {
      call PendingOpTimer.stop();
    }
  }

  event result_t TLReceive.operationCompleted(TLOpId_t *operationId) {
    pendingOp *op;
    // All neighbors responded to our request (or they have been lost in the mean time)
    // Note that OUT operations wont be signaled, because they are not in the pending list.
    op = getPendingOp(operationId);
    if (op != NULL) {
      signalCompletion(op);
    }
    return SUCCESS;
  }

  event void EpochTimer.fired() {
    activeReaction *a = (activeReaction*) firstActiveReaction;
    uart_puts("p");
    localTime++;

    // Refreshing remote reactions
    while (a != NULL) {
      // TODO: don't send them all at the same time, to avoid queue overflow
      call TLSend.sendQuery(a->target, &(a->query[0]),REACT, &(a->operationId));
      mydbg(DBG_USR1, "Operation id reliable %d\n", a->operationId.reliable);
      a = (activeReaction *) a->list.next;
    }

    // Pruning the TeenyLIME system
    pruneTeenyLIMESystem();
  }

  event result_t TLSend.sendDone(TLOpId_t *operationId, result_t success) {
    return SUCCESS;
  }

  event result_t TLReceive.receiveTuples(Tuple* tuples[], uint8_t tupleNumber,
              msg_t operation, TLOpId_t *operationId) {
    pendingOp *op; uint8_t result;

    switch (operation) {
      case OUT_OP:
        // Assuming exactly one tuple per OUT operation.
        call Bridge.out(tuples[0]);
        break;
      case QUERY_RESULT:
        mydbg (DBG_USR1, "Query result received\n");
        // Search the pending operation
        op = getPendingOp(operationId);
        if (op == NULL) break;
        result = addResultTuples(op, tuples, tupleNumber);
        // result == FAIL indicates a memory problem. signalCompletion immediately.
        if (isSingleAnswer(op) || result == FAIL) {
          signalCompletion(op);
        }
        break;

      case REACTION_FIRING:
        signal DTS.tupleReady(operationId, tuples, 1);
        break;

      default:
    }
    return SUCCESS;
  }


  event result_t TLReceive.receiveQuery(Query *q, msg_t operation, TLOpId_t *operationId) {
    result_t result;

    switch (operation) {
      case RD_OP:
        call Bridge.rd(q, operationId);
        break;
      case IN_OP:
        call Bridge.in(q, operationId);
        break;
      case RDG_OP:
        mydbg (DBG_USR1, "Rdg operation received\n");
        call Bridge.rdg(q, operationId);
        break;
      case ING_OP:
        call Bridge.ing(q, operationId);
        break;
      case REACT:
          result = call Bridge.refreshReaction(operationId, REACTION_LOST_REFRESH);
          if (result != SUCCESS) {
            // hmm.. reaction not found, add reaction to local tuple space.
            call Bridge.addReaction(q, operationId, REACTION_LOST_REFRESH);
          }
        break;
      default: ;
    }

    return SUCCESS;
  }


  command Tuple *NeighborSystem.getNeighborTuple() {
    return call Bridge.getNeighborTuple();
  }


  /*
   * Search for a neighbor and update the neighbor tuple.
   * We assume that neighbor tuples cannot be deleted by IN and ING operations.
   * This is implemented by marking all neighbor tuples with a special flag.
   *
   * In this way, pointers to neighbor tuples that are stored in
   * the tuple space are guaranteed to be valid, and incoming neighbor tuples
   * can updated by means of the Bridge.replace() operation.
   * This replace operation is much cheaper than the original implementation,
   * which uses expensive IN and OUT operations to update the neighbor tuple.
   *
   * This is explained in detail in the paper [bronwasser]
   */
  command void NeighborSystem.update(TLTarget_t msgOrigin, Tuple *nghTuple) {
    neighborData *n = (neighborData*)firstNeighbor;

    while (n != NULL) {
      if (n->deviceId == msgOrigin) {
        // We found the neighbor, update neighbor tuple.
        n->lastSeen = localTime;
        n->nghTuple = call Bridge.replace(n->nghTuple, nghTuple);
        return;
      }
      n = (neighborData *) n->list.next;
    }
    // Neighbor not found. Add new neighbor to the list.
    n = (neighborData *) call Mem.malloc(sizeof(neighborData));
    if (n == NULL) {
      err("No more space to add a new neighbor!\n");
      return;
    }
    mydbg(DBG_USR1, "Adding new neighbor %d to TLSystem\n", msgOrigin);
    n->deviceId = msgOrigin;
    n->lastSeen = localTime;
    n->nghTuple = call Bridge.out(nghTuple);
    if (n->nghTuple == NULL) {
      err("Unable to add neighbor tuple to local tuple space\n");
      call Mem.free(n, sizeof(neighborData));
      return;
    }
    // Update neighbor list
    n->list.next = firstNeighbor;
    firstNeighbor = (list_t*)n;
  }
}
