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
 * *	$Id: LocalTeenyLime.nc 188 2007-11-04 21:26:29Z bronwasser $
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

/**
 * This component manages the set of locally stored tuples and reactions.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module LocalTeenyLime {
  provides {
    interface LocalTupleSpace as Local;
    interface BridgeTupleSpace as Bridge;
    interface StdControl;
    interface Init;
  }

  uses {
    interface AMPacket;
    interface Timer<TMilli> as EpochTimer;
    interface TinyMalloc as Mem;
  }
}

implementation {

  // Logical time stamp for inserted tuples
  uint16_t logicalTime = 0;

  // Data structure to store local reactions
  struct localReaction_str {
    list_t list;
    TLOpId_t opId;
    uint8_t expireIn;
    bool onlyOnce;
    Query query[];      // May be it's better to remove the [], but be careful with getLocalReactionSize()
  } PACKED;
  typedef struct localReaction_str lr_t;

  // First local reaction in the list
  lr_t *firstReaction;

  // The local neighbor tuple
  Tuple *nghTuple;

  // The partioned tuple space, one linked list for each tuple format.
  // This array stores a pointer to the first list item of each partition.
  list_t* TS[NR_FORMATS];


  /*
   * Return the size of a local reaction when it would contain this query
   * @param q: the query
   * @return the size of the local reaction in bytes
   */
  uint8_t getLocalReactionSize(Query *q) {
    return sizeof(lr_t) + getQuerySize(q);
  }

  /*
   * Remove a tuple from the tuple space. The partition to remove the tuple
   * from is determined by the formatID of the tuple.
   * @param t: a pointer to the list item that contains this tuple
   */
  void removeTuple(tupleWrapper *t) {
    removeFromList(&(TS[t->tuple.fmtID]), (list_t*) t);
    call Mem.free(t, getTupleWrapperSize(&(t->tuple)));
  }

  /*
   * Return the number of tuples in the tuple space,
   * in all partitions together.
   * @return the number of tuples
   */
  uint8_t nrTuples() {
    uint8_t count = 0, i;
    list_t *l;
    for (i = 0; i < NR_FORMATS; i++) {
      l = TS[i];
      while (l != NULL) {
        count++;
        l = l->next;
      }
    }
    return count;
  }

  /* Perform a query on the tuple space. This is a generic function, meaning that
   * it can be used to perform queries with any formatID. The partition to go through
   * is determined from the formatID in the query.
   * @param q: the query to perform on the tuple space
   * @param result: a pointer to an array where this function stores pointers to the tuples
   * that match the query.
   * @param number: the maximum number of tuple pointers to store in result.
   */
  uint8_t findTuples_GENERIC(Query *q, Tuple **result, uint8_t number) {
    tupleWrapper *t;
    uint8_t cmp; uint8_t found = 0;

    // Initialize query execution
    setCurrentFormat(q->fmtID);
    // Get correct tuple space partition
    t = (tupleWrapper*) TS[q->fmtID];

    while (t != NULL) {
      cmp = compareTuple_GENERIC1(q, t);
      if (cmp == TRUE) {
//        dbg3("tuple found at %hu\n",t);
        result[found++] = &(t->tuple);
        if (number == found) {
          return found;
        }
      }
      t = (tupleWrapper *)t->list.next;
    }
    return found;
  }

  /*
   * Delete a local reaction. The local reaction is removed from the list
   * of local reactions.
   * @param l: a pointer to the local reaction to be removed
   */
  void deleteReaction(lr_t *l) {
    list_t *first = (list_t*) firstReaction;
    // Remove local reaction from the list
    removeFromList(&first, (list_t*)l);
    call Mem.free(l, getLocalReactionSize(&(l->query[0])));
  }


  /*
   * Fire a reaction. The tuple that triggered this reaction
   * is sent to the application that installed this reaction.
   * If the reaction is an only-once reaction (which is used for capability tuples)
   * then the reaction is deleted afterwards.
   * @param r: the reaction to fire
   * @param t: the tuple that triggered this reaction
   */
  void fireReaction(lr_t *r, tupleWrapper *t) {
    // Yes! Fire this reaction!

    // Put tuple pointer in an array:
    Tuple *tArray[1] = {&(t->tuple)};
    dbg3("Firing reaction\n");

    if (isCapabilityTuple(&(t->tuple))) {
      signal Local.reifyCapabilityTuple(&(t->tuple), &(r->opId));
    } else {
      if (r->opId.msgOrigin == TOS_LOCAL_ADDRESS) {
        signal Local.tupleReady(&(r->opId), tArray, 1);
      } else {
        mydbg (DBG_USR1, "Triggering remote reaction\n");
        // Only once reactions are used for capability tuples
        // '!(r->onlyOnce)' means: do not treat the result tuple as a reaction firing,
        // but as a normal query result.
        signal Bridge.tupleReady(&(r->opId), tArray, 1, !(r->onlyOnce));
      }
    }
    if (r->onlyOnce) {
      dbg(DBG_USR3, "Removing one shot reaction\n");
      deleteReaction(r);
    }
  }

  /*
   * Compare the tuple with all reactions and trigger the ones that match
   * the tuple. This is a generic function, meaning that it can be used to
   * match a tuple with any formatID.
   * @param t: a pointer to a list item that contains a tuple
   */
  void triggerReactions_GENERIC(tupleWrapper *t) {
    lr_t *r = firstReaction, *_next;

    // Initialize query matching: set
    setCurrentFormat(t->tuple.fmtID);

    while (r != NULL) {
      if (t->tuple.fmtID == r->query[0].fmtID && // fmtIDs match?
            compareTuple_GENERIC2(&(r->query[0]),t) == TRUE) { // tuple matches query?
        // The tuple matches! Fire this reaction.

        // Store next local reaction before it possibly gets deleted by fireReaction()
        _next = r->list.next;
        fireReaction(r, t);
        r = _next;
      } else {
        r = r->list.next;
      }
    }
  }


#if QUERY_METHOD == GENERIC_QUERIES
  // No query function generation based on formatID.
  // Redirect all calls to findTuples() and triggerReactions() to
  // their generic implementations.
  #define findTuples findTuples_GENERIC
  #define triggerReactions triggerReactions_GENERIC
#endif


#if QUERY_METHOD == GENERATED_QUERIES
  // Queries are generated from tuple formats

  // Function pointers to the generated functions
  typedef bool (*queryFunc_t)(Query *,Tuple **, uint8_t number);
  typedef void (*triggerReactionsFunc_t)(tupleWrapper *);

  #include "Queries.h"

  /*
   * findTuples handler. Dispatch call to a generated function if present.
   * If such a function does not exist for the formatID contained in the query <q>,
   * call the generic findTuples() function instead.
   * @param t: a pointer to a list item that contains a tuple/
   */
  uint8_t findTuples(Query *q, Tuple **result, uint8_t number) @C() {
    queryFunc_t query = queryFuncs[q->fmtID];
    uint8_t num;
    asm("findtup0:");
    if (query != NULL) {
      // Generated function present, use it.
      num = query(q, result, number);
    } else {
      // No generated function present. Use standard function
      num = findTuples_GENERIC(q, result, number);
    }
    asm("findtup1:");
    return num;
  }

  /*
   * TriggerReactions handler. Dispatch call to a generated function if present.
   * If such a function does not exist for the formatID contained in <t>,
   * call the generic triggerReactions() function instead.
   * @param t: a pointer to a list item that contains a tuple.
   */
  void triggerReactions(tupleWrapper *t) @C() {
    triggerReactionsFunc_t trigger;
    asm("trigger0:");
    trigger = triggerReactionFuncs[t->tuple.fmtID];
    if (trigger != NULL) {
      // Generated function present, use it.
      trigger(t);
    } else {
      // No generated function present. Use standard function
      triggerReactions_GENERIC(t);
    }
    asm("trigger1:");
  }
#endif


  /*
   * Debugging, print all tuples in the tuple space
   */
  void printTupleSpace() {
    char s[100];
    uint8_t count = 0, i;
    list_t *l;
    for (i = 0; i < NR_FORMATS; i++) {
      l = TS[i];
      while (l != NULL) {
        printTuple(getTuple(l), s);
        mydbg(DBG_USR1, "%s\n", s);
        l = l->next;
      }
    }
  }

  /*
   * Debugging, print all local reactions
   */
  void printLocalReactions() {
    char s[100];
    lr_t *l = firstReaction;
    Query *q;

    while(l != NULL) {
      printQuery((Query*) &(l->query), s);
      mydbg(DBG_USR1, "%s\n", s);
      l = l->list.next;
    }
  }


  /*
   * Allocated memory for a new tuple, and insert it in the local
   * tuple space
   */
  tupleWrapper* localOut(Tuple *t) {
    tupleWrapper *w;

    // Allocate memory for new tuple
    w = (tupleWrapper *) call Mem.malloc(getTupleWrapperSize(t));
    if (w == NULL) return NULL;

    // Timestamp the tuple (if timestamp field present in this format)
    setLogicalTime(t, logicalTime);

    // Insert in linked list and copy the tuple data
    w->list.next = TS[t->fmtID];
    TS[t->fmtID] = (list_t*) w;
    copyTuple(&(w->tuple),t);

    if(w != NULL) {
      triggerReactions(w);
    }
    return w;
  }

  /*
   * Allocate memory for a new local reaction and install it locally
   */
  result_t insertReaction(Query *q, TLOpId_t *opId, bool onlyOnce, uint8_t expire) {
    lr_t *l;

    l = (lr_t*) call Mem.malloc(getLocalReactionSize(q));
    if (l == NULL) return FAIL;
    copyQuery(l->query, q);
    l->opId = *opId;
    l->onlyOnce = onlyOnce;
    l->expireIn = expire;
    l->list.next = firstReaction;
    firstReaction = l;
    return SUCCESS;
  }

  /*
   * A capability tuple has been triggered by a query.
   * Install a reaction that serves to direct the actual
   * tuple once output. Then signal the application.
   * @param opID: The operationID of the query
   * @param q: The query
   * @param t: The capability tuple
   */
  void triggerCapabilityTuple(TLOpId_t *opID, Query *q, Tuple *t) {
    insertReaction(q, opID, TRUE, TIME_UNDEFINED);
    signal Local.reifyCapabilityTuple(t, opID);
  }

  command result_t Init.init() {
    declareTuple(nt, STD_NGH_FMT);

    // Create standard neighbor tuple.
    newTuple_STD_NGH_FMT(nt, call AMPacket.address());
    call Local.setNeighborTuple(nt);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call EpochTimer.startPeriodic(EPOCH);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg3("Nr tuples: %d\n",nrTuples());
    return SUCCESS;
  }

  command result_t Local.out(Tuple *t, TLOpId_t *operationId) {

    mydbg(DBG_USR1, "Local out op\n");
    if (localOut(t) == NULL) {
      return FAIL;
    } else {
      return SUCCESS;
    }
  }

  command tupleWrapper *Bridge.out(Tuple *t) {
    mydbg(DBG_USR1, "LTL: Received tuple from Bridge, will insert in local tuple space.\n");
    return localOut(t);
  }

  command result_t Bridge.rd(Query *q, TLOpId_t *opID) {
    uint8_t num; Tuple* result[1] = {NULL};

    num = findTuples(q, result, 1);
    if (num == 1 && isCapabilityTuple(result[0])) {
      triggerCapabilityTuple(opID, q, result[0]);
    } else {
      signal Bridge.tupleReady(opID, result, num, FALSE);
    }
    return SUCCESS;
  }

  command result_t Local.rd(Query *q, TLOpId_t *opID) {
    uint8_t num;  Tuple* result[1] = {NULL};

    num = findTuples(q, result, 1);
    if (num == 1 && isCapabilityTuple(result[0])) {
      triggerCapabilityTuple(opID, q, result[0]);
    } else {
      signal Local.tupleReady(opID, result, num);
    }
    return SUCCESS;
  }

  command result_t Bridge.in(Query *q, TLOpId_t *opID) {
    Tuple *result[1] = {NULL};

    if (findTuples(q, result, 1) == 1) {
      if (!isCapabilityTuple(result[0])) {
        signal Bridge.tupleReady(opID, result, 1, FALSE);
        if (!isNeighborTuple(result[0])) {
          // Translate back to the position of the tuple container and remove
          removeTuple((tupleWrapper*) (result[0] - offsetof(tupleWrapper, tuple)));
        }
        return SUCCESS;
      } else {
        triggerCapabilityTuple(opID, q, result[0]);
      }
    }
    signal Bridge.tupleReady(opID, NULL, 0, FALSE);
    return SUCCESS;
  }


  command result_t Local.in(Query *q, TLOpId_t *opID) {
    Tuple *result[1] = {NULL}; uint8_t num;

    num = findTuples(q, result, 1);
    if (num == 1 && !isNeighborTuple(result[0])) {
      // Translate back to the position of the tuple container and remove
      removeTuple((tupleWrapper*) (result[0] - offsetof(tupleWrapper, tuple)));
    }
    signal Local.tupleReady(opID, result, num);
    return SUCCESS;
  }


  command result_t Bridge.rdg(Query *q, TLOpId_t *opID) {
    Tuple *result[MAX_RETURN_TUPLES];
    uint8_t i, num, resultNum = 0;

    num = findTuples(q, result, MAX_RETURN_TUPLES);
    mydbg(DBG_USR1, "Found %d matching tuple(s)\n", num);

    // Filtering out capability tuples
    for (i = 0; i < num; i++) {
      if (!isCapabilityTuple(result[i])) {
        if (resultNum != i) {
          result[resultNum] = result[i];
        }
        resultNum++;
      } else {
        triggerCapabilityTuple(opID, q, result[i]);
      }
    }
    signal Bridge.tupleReady(opID, result, resultNum, FALSE);
    return SUCCESS;
  }


  command result_t Local.rdg(Query *q, TLOpId_t *opID) {
    Tuple *result[MAX_RETURN_TUPLES];
    uint8_t i, num, resultNum;

    num = findTuples(q, result, MAX_RETURN_TUPLES);

    // Filtering out capability tuples
    for (i = 0; i < num; i++) {
      if (!isCapabilityTuple(result[i])) {
        if (resultNum != i) {
          result[resultNum] = result[i];
        }
        resultNum++;
      } else {
        triggerCapabilityTuple(opID, q, result[i]);
      }
    }
    signal Local.tupleReady(opID, result, resultNum);
    return SUCCESS;
  }


  command result_t Bridge.ing(Query *q, TLOpId_t *opID) {
    Tuple *result[MAX_RETURN_TUPLES];
    uint8_t i, num, resultNum = 0;

    num = findTuples(q, result, MAX_RETURN_TUPLES);
    mydbg(DBG_USR1, "Found %d matching tuple(s)\n", num);

    // Filtering out capability tuples
    for (i = 0; i < num; i++) {
      if (!isCapabilityTuple(result[i])) {
        if (resultNum != i) {
          result[resultNum] = result[i];
        }
        resultNum++;
      } else {
        triggerCapabilityTuple(opID, q, result[i]);
      }
    }
    signal Bridge.tupleReady(opID, result, resultNum, FALSE);
    for (i = 0; i < resultNum; i++) {
      if (!isNeighborTuple(result[i])) {
        // Translate back to the position of the tuple container and remove
        removeTuple((tupleWrapper*) (result[i] - offsetof(tupleWrapper, tuple)));
      }
    }
    return SUCCESS;
  }


  command result_t Local.ing(Query *q, TLOpId_t *opID) {
    Tuple *result[MAX_RETURN_TUPLES];
    uint8_t i, num;

    num = findTuples(q, result, MAX_RETURN_TUPLES);
    mydbg(DBG_USR1, "Found %hu matching tuple(s) for local ING\n",num);

    // Note that we're not filtering out capability tuples
    // Local apps are allowed to remove capability tuples
    signal Local.tupleReady(opID, result, num);
    for (i = 0; i < num; i++) {
      if (!isNeighborTuple(result[i])) {
        // Translate back to the position of the tuple container and remove
        removeTuple((tupleWrapper*) (result[i] - offsetof(tupleWrapper, tuple)));
      }
    }
    return SUCCESS;
  }


  command result_t Bridge.remove(tupleWrapper *t) {
    mydbg(DBG_USR1, "TeenyLIME removing tuple\n");
    removeTuple(t);
    return SUCCESS;
  }

  command tupleWrapper *Bridge.replace(tupleWrapper *t, Tuple * newTuple) {
    if (getTupleSize(getTuple((list_t*)t)) == getTupleSize(newTuple)) {
      copyTuple(getTuple((list_t*)t), newTuple);
      triggerReactions(t);
    } else {
      removeTuple(t);
      t = localOut(newTuple);
    }
    return t;
  }

  command result_t Bridge.refreshReaction(TLOpId_t *opId, uint8_t expire){
    lr_t *l = firstReaction;
    while (l != NULL) {
      if (l->opId.commandId == opId->commandId
                 && l->opId.msgOrigin == opId->msgOrigin) {
        // Local reaction found. Update expiration field.
        l->expireIn = expire;
        return SUCCESS;
      }
      l = l->list.next;
    }
    return FAIL;
  }

  command result_t Local.addReaction(Query *q, TLOpId_t *opId) {
    return insertReaction(q, opId, FALSE, TIME_UNDEFINED);
  }

  command result_t Bridge.addReaction(Query *q, TLOpId_t *operationId, uint8_t expire) {
    return insertReaction(q, operationId, FALSE, expire);
  }

  result_t deleteReactionByOpId(TLOpId_t *opId) {
    lr_t *l = firstReaction;
    // TODO: We might want to keep track of the previous reaction in the list.
    // This saves another linear search in removeFromList() in deleteReaction().
    // Have a look at removeActiveReaction() in DTL to see how this is done.
    // But on the other hand, the list might not be that long...
    while (l != NULL) {
      if (l->opId.commandId == opId->commandId
          && l->opId.msgOrigin == opId->msgOrigin) {
        deleteReaction(l);
        return SUCCESS;
      }
      l = l->list.next;
    }
    return FAIL;
  }

  command result_t Local.removeReaction(TLOpId_t *operationId) {
    return deleteReactionByOpId(operationId);
  }

  command result_t Bridge.removeReaction(TLOpId_t *operationId) {
    mydbg (DBG_USR1, "Removing remote reaction\n");
    return deleteReactionByOpId(operationId);
  }

  command Tuple *Bridge.getNeighborTuple() {
    return nghTuple;
  }

  void pruneExpiredTuples() {
    tupleWrapper *t; uint8_t expireField, i;

    for (i = 0; i < NR_FORMATS; i++) {
      t = (tupleWrapper*) TS[i];
      while(t != NULL) {
        // Decouple logicalTime and expireIn, use expireIn as a count down field
        expireField = formats[t->tuple.fmtID].expireIn;
        if (expireField != NO_EXPIRE_IN) {
          if (t->tuple.fields[expireField].int16-- == 0) {
            mydbg (DBG_USR1, "Removing expired tuple\n");
            removeTuple(t);
          }
        }
        t = (tupleWrapper*) t->list.next;
      }
    }
  }

  void pruneExpiredReactions() {
    lr_t *l = firstReaction;

    while(l != NULL) {
      if (l->expireIn != TIME_UNDEFINED) {
        l->expireIn--;
        if (l->expireIn == 0) {
          mydbg(DBG_USR1, "Removing expired reaction\n");
          deleteReaction(l);
        }
      }
      l = l->list.next;
    }
  }

  command uint8_t Local.setNeighborTuple(Tuple *t) {
    // Replace current neighbor tuple
    // Purposely not store in the tuple space

    if (nghTuple != NULL) {
      // nghTuple currently not NULL, let's check if we have to delete it:
      if (t == NULL || getTupleSize(t) != getTupleSize(nghTuple)) {
        // New neighbor tuple has different size. remove mem block
        call Mem.free(nghTuple, getTupleSize(nghTuple));
      }
    }
    if (t != NULL) {
      // Alloc new mem block
      nghTuple = (Tuple*) call Mem.malloc(getTupleSize(t));
      if (nghTuple == NULL) return FAIL;
      copyTuple(nghTuple, t);
      nghTuple->isNeighborTuple = TRUE;
    }
    return SUCCESS;
  }

  event void EpochTimer.fired() {
    logicalTime++;

    // Prune expired tuples
    pruneExpiredTuples();
    pruneExpiredReactions();

    // Update logical time for queries
    setCurrentTime(logicalTime);
  }

}

