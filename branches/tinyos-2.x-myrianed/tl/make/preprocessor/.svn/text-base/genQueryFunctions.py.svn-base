

from Classes import *

# === Writing the Query Functions === #

def genQueryFunc(tFmt):
  code = """
uint8_t findTuples_%FMT_NAME(Query *q, Tuple **result, uint8_t number) {
  // Perform a query on all tuples of format %FMT_NAME
  tupleWrapper *t;
  uint8_t cmp; uint8_t found = 0;
  t = (tupleWrapper*) TS[%FMT_ID];
  while (t != NULL) {
    cmp = compareQuery_%FMT_NAME(q,t);
    if (cmp == TRUE) {
      result[found++] = &(t->tuple);
      if (number == found) {
        return found;
      }
    }
    t = (tupleWrapper *)t->list.next;
  }
  return found;
}
"""
  code = code.replace('%FMT_NAME', tFmt.name)
  code = code.replace('%FMT_ID', str(tFmt.fmtID))
  return code


def genQueryFuncs(tFmts):
  code = ""

  # Write the query functions
  for tFmt in tFmts.getArray():
    if not (tFmt.useStdQuery):
      code += genQueryFunc(tFmt)

  # Initialize the function pointer array
  funcPtrs = 'queryFunc_t queryFuncs[NR_FORMATS] = {\n'
  for i in range(tFmts.getHighestFmtID()+1):
    tFmt = tFmts.getByFmtID(i)
    if tFmt == None or tFmt.useStdQuery:
      funcPtrs += '  NULL,\n'
    else:
      funcPtrs += '  findTuples_' + tFmt.name + ',\n'
  funcPtrs += '};'

  code += funcPtrs
  return code



def genTriggerReactionFunc(tFmt):
  code = """

void triggerReactions_%FMT_NAME(tupleWrapper *t) {
  lr_t *r = firstReaction, *_next;

  // Initialize query matching: set formatID to be used within the query
  setCurrentFormat(%FMT_ID);

  while (r != NULL) {
    if (r->query[0].fmtID == %FMT_ID && // fmtIDs match?
          compareReaction_%FMT_NAME(&(r->query[0]),t) == TRUE) { // tuple matches query?

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
"""
  code = code.replace('%FMT_NAME', tFmt.name)
  code = code.replace('%FMT_ID', str(tFmt.fmtID))
  return code



def genTriggerReactionFuncs(tFmts):
  code = ""

  # Write the query functions
  for tFmt in tFmts.getArray():
    if not (tFmt.useStdReactionFunc):
      code += genTriggerReactionFunc(tFmt)

  # Initialize the function pointer array
  funcPtrs = '\ntriggerReactionsFunc_t triggerReactionFuncs[NR_FORMATS] = {\n'
  for i in range(tFmts.getHighestFmtID()+1):
    tFmt = tFmts.getByFmtID(i)
    if tFmt == None or tFmt.useStdReactionFunc:
      funcPtrs += '  NULL,\n'
    else:
      funcPtrs += '  triggerReactions_' + tFmt.name + ',\n'
  funcPtrs += '};'

  code += funcPtrs
  return code



# === Writing the Comparison Functions === #
# The comparison functions compare a single tuple with a query

def genFieldCmpFunc(tFmt, i):
  # Generate the code that compares one tuple field with a query condition

  if tFmt.getFieldType(i).startswith("TYPE_"):
    # Compare a normal tuple field with a query condition
    code = """
  if (q->conds[currentCond].fieldNr == %FIELD_INDEX) {
    //dbg3("%FMT_NAME: Cmp fields #%d: tuple: %d, query: %d\\n",%FIELD_INDEX,t->tuple.fields[%FIELD_INDEX].int16,q->conds[currentCond].value.int16);
    compareField_%FIELD_TYPE(t->tuple.fields[%FIELD_INDEX], q->conds[currentCond]);
    currentCond++;
    if (currentCond == q->nrConds) return TRUE;
  }
  """
  elif tFmt.getFieldType(i) == TIMESTAMP_KEYW:
    # Compare a timestamp field with the freshness requirement of the query
    code = """
  if (q->conds[currentCond].cmpFunc == COND_FRESHNESS) {
    if (currentTime - t->tuple.fields[%TIMESTAMP_INDEX].int16 < q->conds[currentCond].value.int16) return FALSE;
    currentCond++;
    if (currentCond == q->nrConds) return TRUE;
  }
  """
  else:
    # EXPIRE_IN field. Not used for queries
    code = ""

  code = code.replace('%FIELD_TYPE',tFmt.getFieldType(i))
  code = code.replace('%FIELD_INDEX',str(i))
  code = code.replace('%TIMESTAMP_INDEX',str(tFmt.getTimestampField()))
  return code


def genCmpFunc(tFmt, funcName):
  # Generate a function that compares a query to a tuple
  code = """
bool %FUNC_NAME_%FMT_NAME(Query *q, tupleWrapper *t) {
  %DECL_CURRENT_COND
  if (q->nrConds == 0) {
    return TRUE;
  }
"""
  for i in range(tFmt.nrFields()):
    code += genFieldCmpFunc(tFmt, i)

  code += 'return FALSE;\n}\n'
  code = code.replace('%FMT_NAME', tFmt.name)
  code = code.replace('%FUNC_NAME', funcName)

  # Avoid 'unused variable warning for tuples without fields
  if tFmt.nrFields() != 0:
    code = code.replace('%DECL_CURRENT_COND', 'uint8_t currentCond = 0;\n')
  else:
    code = code.replace('%DECL_CURRENT_COND', '')
  return code


def genCmpFuncs(tFmts):
  code = ""
  # Write the query functions
  for tFmt in tFmts.getArray():
    # Generate all functions twice.
    # This makes the compiler inline the compare functions
    # into the generated findTuples() and triggerReactions() functions.
    # Queries perform about 25% faster with inlining
    if not (tFmt.useStdQuery):
      code += genCmpFunc(tFmt, "compareQuery")
    if not (tFmt.useStdReactionFunc):
      code += genCmpFunc(tFmt, "compareReaction")
  return code

