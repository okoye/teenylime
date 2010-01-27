/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision:19 $
 * * DATE
 * *    $LastChangedDate:2007-05-03 14:29:53 +0200 (Thu, 03 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy:bronwasser $
 * *
 * *  $Id:TupleSpace.h 19 2007-05-03 12:29:53Z bronwasser $
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

/**
 * Definition of data structures.
 *
 * @author Paolo Costa
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 *
 */

#ifndef TUPLE_SPACE_H
#define TUPLE_SPACE_H

#include "LinkedList.h"
#include "TLConf.h"
#include <stdarg.h>
#include <stdio.h>
#ifdef FLOAT_SUPPORT
  #include <float.h>
#endif


// Set packed attr and width of the pointer arithmetic data type
#if defined(pc) || defined(sim)
  // Pointers are 32 bits in tossim.
  #define ptr_arithm_t uint32_t
  // We use packed to avoid word aligning in tossim
  #define PACKED __attribute__((__packed__))
#else
  // On most nodes pointers are 16 bits.
  #define ptr_arithm_t uint16_t
  // We define PACKED as empty string, to turn it of for real nodes
  #define PACKED
#endif


// DEBUG
#define err(s...) dbg("ERROR",## s)

#ifndef mydbg
#define mydbg(d, s...) dbg(d, ## s)
#endif

// Definition of possible targets for operations
#define TL_LOCAL TOS_LOCAL_ADDRESS
#define TL_NEIGHBORHOOD TOS_BCAST_ADDR

// Value indicating that there is no time requirement in tuples, reactions
#define TIME_UNDEFINED 0

// Size of the string field. Increasing this makes all tuples bigger!
#define STR_SIZE 2

// TeenyLIME internal constants
#define TEENYLIME_SYSTEM_OPERATION 0
#define TEENYLIME_SYSTEM_COMPONENT 0

typedef uint16_t TLTarget_t;  // target node address
typedef uint8_t fieldType;    // this type is used to store the data type of a tuple field


enum FIELD_TYPES {
  TYPE_UINT8,
  TYPE_UINT16, TYPE_FLOAT,
  TYPE_CHAR, TYPE_STR,
  LOGICAL_TIME, EXPIRE_IN,
  TYPE_DONT_CARE
};


// OperationID data type.
// Each application call to TeenyLime is assigned a unique operationID
struct TLOpID_str {
  uint16_t msgOrigin;       // Address of the originating node
  uint8_t componentId :7;   // Application ID (TeenyLime allows multiple applications per node)
  uint8_t reliable :1;      // Is this a reliable operation?
  uint8_t commandId;        // Unique ID assigned to each subsequent TeenyLime call
} PACKED;
typedef struct TLOpID_str TLOpId_t;
// The attribute packed doesn't work in conjunction with typedef, therefore we first
// define the struct, then typedef the struct.


// Data type for the actual values stored in tuples and queries.
typedef union fieldValue {
  uint8_t int8;
  uint16_t int16;
#ifdef FLOAT_SUPPORT
  float flt;
#endif
  char c;
  char str[STR_SIZE];
} field_t;


// The tuple data type
struct tuple_str {
  uint8_t fmtID : 6;              // The tuple format of this tuple
  uint8_t isCapabilityTuple :1;   // Is this a capability tuple?
  uint8_t isNeighborTuple :1;     // Is this a neighbor tuple?
  field_t fields[];               // The tuple values
} PACKED;
typedef struct tuple_str Tuple;


// Create a wrapper around the tuple in order to store tuples in a linked list
typedef struct {
  list_t list;
  Tuple tuple;
} tupleWrapper;


// Comparison function IDs that can be used in query conditions
enum {
  COND_EQ,
  COND_LT,
  COND_GT,
  COND_GTE,
  COND_LTE,
  COND_FRESHNESS,
};

// Query condition data type
typedef struct {
  uint8_t fieldNr;  // The tuple field that should match this condition
  uint8_t cmpFunc;  // The comparison function to perform (EQ, LT, GT)
  field_t value;    // The value to compare the tuple field with
} Condition;


// Query data type
typedef struct {
  uint8_t fmtID;        // The format ID of the tuple we are looking for
  uint8_t nrConds;      // The number of conditions in this query
  Condition conds[0]; // The conditions of this query
} Query;


// To return an error to the application (This value is returned within TLOpId_t)
#define TL_OP_FAIL 0
// The application must use isFailed() to check for return errors
bool isFailed(TLOpId_t* opId) {
  if (opId->commandId == 0) return TRUE;
  else return FALSE;
}



// ===== TUPLE FORMATS ===== //

#define NO_LOGICAL_TIME 255 // This tuple format does not define the logicalTime field
#define NO_EXPIRE_IN 255    // This tuple format does not define the expireIn field

// The tuple format data type
typedef struct {
  fieldType types[MAX_FIELDS];    // The data types of the tuple fields
  uint8_t nrFields;     // The number of fields
  uint8_t size;         // The size (bytes) of a tuple of this format
  uint8_t logicalTime;  // The nr of the field containing the logicalTime of a tuple
  uint8_t expireIn;     // The nr of the field containing the expireIn value
} format_t;

// Include the generated tuple formats file
#include "TupleFormats.h"
// Include functions to create new tuples
#include "NewTuple.h"

// Prior to executing a query, a pointer to
// the tuple format is stored in this variable
format_t *currentFormat = NULL;

// The current time stored in this variable is used during query execution.
// This variable is updated each epoch by LocalTeenyLime
uint16_t currentTime = 0;




// ===== Application Functions ===== //

/*
 * Declare a tuple variable and create a pointer to it
 * @param name: the name of the pointer to the new tuple
 * @param fmtID: the tuple format ID
 */
#define declareTuple(name, fmtID) \
  char name##_buf [TUPLE_SIZE(fmtID##_FIELD_COUNT)];\
  Tuple *name = (Tuple *) &(name##_buf[0])

/*
 * Declare a query variable and create a pointer to it
 * @param name: the name of the pointer to the new query
 * @param nrConds: the number of conditions to reserve memory for
 */
#define declareQuery(name, nrConds) \
  char name##_buf [sizeof(Query) + sizeof(Condition) * nrConds];\
  Query *name = (Query *) name##_buf

/*
 * Return the tuple size in bytes
 * @param t: pointer to a tuple
 * @return the size of the tuple in bytes
 */
uint8_t getTupleSize(Tuple *t) {
  return (formats[t->fmtID].size);
}

/*
 * Return the query size in bytes
 * @param q: pointer to a query
 * @return the size of the query in bytes
 */
uint8_t getQuerySize(Query *q) {
  return q->nrConds * sizeof(Condition) + sizeof(Query);
}


/*
 * Copy a query
 * @param to: pointer to the destination query
 * @param from: pointer to the source query
 * @return pointer to the next byte after the destination query
 */
char *copyQuery(Query *to, Query *from) {
  uint8_t size = getQuerySize(from);
  memcpy(to,from,size);
  return (char*)((ptr_arithm_t)size + (ptr_arithm_t)to);
}

/*
 * Copy a tuple
 * @param to: pointer to the destination tuple
 * @param from: pointer to the source tuple
 * @return pointer to the next byte after the destination tuple
 */
char *copyTuple(Tuple *to, Tuple *from) {
  uint8_t size = getTupleSize(from);
  memcpy(to,from,size);
  return (char*)((ptr_arithm_t)size + (ptr_arithm_t)to);
}

/*
 * Condition macros are used (only) as parameters to the newQuery() function
 */
#define eqCond(fieldNr, fieldValue) COND_EQ, fieldNr, fieldValue
#define ltCond(fieldNr, fieldValue) COND_LT, fieldNr, fieldValue
#define gtCond(fieldNr, fieldValue) COND_GT, fieldNr, fieldValue
#define lteCond(fieldNr, fieldValue) COND_LTE, fieldNr, fieldValue
#define gteCond(fieldNr, fieldValue) COND_GTE, fieldNr, fieldValue
#define freshnessCond(fieldNr, fieldValue) COND_FRESHNESS, fieldNr, fieldValue

/*
 * Create a new query.
 * Generated query and reaction functions queries require all conditions
 * to respect the order of tuple fields:
 * newQuery(q, MY_FMT, 2, eqCond(0,80), eqCond(1,80)) is allowed,
 * newQuery(q, MY_FMT, 2, eqCond(1,80), eqCond(0,80)) is NOT allowed.
 * In addition, only 1 condition is allowed per tuple field:
 * newQuery(q, MY_FMT, 2, eqCond(0,80), eqCond(0,80)) is NOT allowed.
 *
 * For tuple formats that use generic queries (no code generation),
 * these restrictions do not exist.
 *
 * @param q: a pointer to query variable
 * @param fmtID: the tuple format ID of the tuples to be searched for with this query
 * @param nrConds: the number of conditions to be stored in this query
 * @param ...: the conditions, to be passed by means of the xxCond() macros
 */
void newQuery(Query *q, uint8_t fmtID, uint8_t nrConds, ...) {
  int i = 0;
  va_list ap;
  va_start(ap, nrConds);
  q->nrConds = nrConds;
  q->fmtID = fmtID;

  for (i = 0; i < nrConds; i++) {
    q->conds[i].cmpFunc = va_arg(ap, unsigned);
    q->conds[i].fieldNr = va_arg(ap, unsigned);
    q->conds[i].value = (field_t) va_arg(ap, field_t);
  }
}

/*
 * Return the tuple field on position <fieldNr> as an uint16_t value
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to return the value from
 * @return the value on position <fieldNr>
 */
uint16_t getUint16Field(Tuple *t, uint8_t fieldNr) {
  return t->fields[fieldNr].int16;
}

/*
 * Return the tuple field on position <fieldNr> as an uint8_t value
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to return the value from
 * @return the value on position <fieldNr>
 */
uint16_t getUint8Field(Tuple *t, uint8_t fieldNr) {
  return t->fields[fieldNr].int8;
}

/*
 * Return the tuple field on position <fieldNr> as a char value
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to return the value from
 * @return the value on position <fieldNr>
 */
char getCharField(Tuple *t, uint8_t fieldNr) {
  return t->fields[fieldNr].c;
}

/*
 * Set the value of tuple field on position <fieldNr>
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to set
 * @param value: the value to write in the tuple field
 */
void setUint16Field(Tuple *t, uint8_t fieldNr, uint16_t value) {
  t->fields[fieldNr].int16 = value;
}

/*
 * Set the value of tuple field on position <fieldNr>
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to set
 * @param value: the value to write in the tuple field
 */
void setUint8Field(Tuple *t, uint8_t fieldNr, uint8_t value) {
  t->fields[fieldNr].int8 = value;
}

/*
 * Set the value of tuple field on position <fieldNr>
 * @param t: a pointer to a tuple
 * @param fieldNr: the tuple field number to set
 * @param value: the value to write in the tuple field
 */
void setCharField(Tuple *t, uint8_t fieldNr, char value) {
  t->fields[fieldNr].int8 = value;
}

/*
 * Specify how long this tuple is allowed to live.
 * The tuple must contain an EXPIRE_IN field, i.e.
 * the EXPIRE_IN field must be defined in the tuple format.
 * @param t: a pointer to a tuple variable
 * @param expireIn: the number of epochs this tuple may live
 */
void setExpireIn(Tuple* t, uint16_t expireIn) {
  uint8_t i = formats[t->fmtID].expireIn;
  if (i != NO_EXPIRE_IN) {
    t->fields[i].int16 = expireIn;
  }
}

/*
 * Set the timestamp value of this tuple.
 * The tuple must contain an LOGICAL_TIME field, i.e.
 * the LOGICAL_TIME field must be defined in the tuple format.
 * @param t: a pointer to a tuple variable
 * @param logicalTime: The timestamp value
 */
void setLogicalTime(Tuple *t, uint16_t logicalTime) {
  uint8_t i = formats[t->fmtID].logicalTime;
  if (i != NO_LOGICAL_TIME) {
    t->fields[i].int16 = logicalTime;
  }
}

/*
 * Get the timestamp value of this tuple.
 * The tuple must contain an LOGICAL_TIME field, i.e.
 * the LOGICAL_TIME field must be defined in the tuple format.
 * @param t: a pointer to a tuple variable
 * @return the timestamp of this tuple, or TIME_UNDEFINED if the timestamp is not present
 */
uint16_t getLogicalTime(Tuple* t) {
  uint8_t i = formats[t->fmtID].logicalTime;
  if (i != NO_LOGICAL_TIME) {
    return t->fields[i].int16;
  } else {
    return TIME_UNDEFINED;
  }
}

/*
 * Return whether this tuple is a capability tuple
 * @param t: a pointer to a tuple variable
 * @return 1 if this tuple is a capability tuple, 0 otherwise
 */
bool isCapabilityTuple(Tuple *t) {
  return t->isCapabilityTuple;
}

/*
 * Return whether this tuple is a neighbor tuple
 * @param t: a pointer to a tuple variable
 * @return 1 if this tuple is a neighbor tuple, 0 otherwise
 */
bool isNeighborTuple(Tuple *t) {
  return t->isNeighborTuple;
}

/*
 * Print the contents and the format of a tuple into a string
 * @param t: the tuple to print
 * @param s: the string to write to
 */
void printTuple(Tuple *t, char s[]) {
  format_t *format; uint8_t i;
  format = &(formats[t->fmtID]);
  sprintf(s, "[");

  for(i = 0; i < MAX_FIELDS; i++) {
    switch(format->types[i]) {
    case TYPE_UINT8:  sprintf(s, "%s (uint8_t, %hu),", s, t->fields[i].int8); break;
    case TYPE_UINT16: sprintf(s, "%s (uint16_t, %d),", s, t->fields[i].int16); break;
#ifdef FLOAT_SUPPORT
    case TYPE_FLOAT:  sprintf(s, "%s (float, %.2f),", s, t->fields[i].flt); break;
#endif
    case TYPE_CHAR:   sprintf(s, "%s (char, \'%c\'),", s, t->fields[i].c); break;
    case TYPE_STR:    sprintf(s, "%s (string, \"%s\"),", s, t->fields[i].str); break;
    default: sprintf(s, "%s (unknown type)", s);
    }
  }
  s[strlen(s)-1] = ' ';
  sprintf(s, "%s]", s);
}




// ===== Functions for internal usage only ===== //
/*
 *  For internal usage: Returns the size of the tuple including the wrapper data.
 * @param t: pointer to a tuple
 * @return the size of this tuple in bytes, including the wrapper data, the
 * data that is needed to store this tuple in the linked list.
 */
uint8_t getTupleWrapperSize(Tuple *t) {
  return getTupleSize(t) + sizeof(list_t);
}

/*
 * For internal usage: Get pointer to tuple inside list item.
 * @param l: pointer to a list item
 * @return a pointer to the tuple contained in this list item
 */
Tuple *getTuple(list_t *l) {
  return (Tuple*)&(l->data);
}


/*
 * Print the contents of a query into a string
 * To be implemented...
 * @param t: the query to print
 * @param s: the string to write to
 */
void printQuery(Query *q, char s[]) {
  sprintf(s, "[Query]");
}


/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query.
 * This macro is used by the generated compareTuple_XXX functions.
 */
#define compareField_TYPE_UINT16(tupleValue, cond)\
{\
  switch (cond.cmpFunc) {\
    case COND_EQ: \
      if (tupleValue.int16 != cond.value.int16) return FALSE;\
      break; \
    case COND_LT: \
      if (tupleValue.int16 >= cond.value.int16) return FALSE; \
      break; \
    case COND_GT: \
      if (tupleValue.int16 <= cond.value.int16) return FALSE; \
      break; \
    case COND_LTE: \
      if (tupleValue.int16 > cond.value.int16) return FALSE; \
      break; \
    case COND_GTE: \
      if (tupleValue.int16 < cond.value.int16) return FALSE; \
      break; \
    default: \
      return FALSE; \
  } \
}


/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query.
 * This macro is used by the generated compareTuple_XXX functions.
 */
#define compareField_TYPE_UINT8(tupleValue, cond)\
{\
  switch (cond.cmpFunc) {\
    case COND_EQ: \
      if (tupleValue.int8 != cond.value.int8) return FALSE;\
      break; \
    case COND_LT: \
      if (tupleValue.int8 >= cond.value.int8) return FALSE; \
      break; \
    case COND_GT: \
      if (tupleValue.int8 <= cond.value.int8) return FALSE; \
      break; \
    case COND_LTE: \
      if (tupleValue.int8 > cond.value.int8) return FALSE; \
      break; \
    case COND_GTE: \
      if (tupleValue.int8 < cond.value.int8) return FALSE; \
      break; \
    default: \
      return FALSE; \
  } \
}


/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query.
 * This macro is used by the generated compareTuple_XXX functions.
 */
#define compareField_TYPE_CHAR_T(tupleValue, cond)\
{\
  switch (cond.cmpFunc) {\
    case COND_LT: \
      if (tupleValue.c >= cond.value.c) return FALSE; \
      break; \
    case COND_EQ: \
      if (tupleValue.c != cond.value.c) return FALSE; \
      break; \
    default: \
      return FALSE; \
  } \
}


/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareEQ(tupleValue, cond)\
{\
  switch (currentFormat->types[q->conds[i].fieldNr]) {\
    case TYPE_UINT16:\
      if (tupleValue.int16 != cond.value.int16) return FALSE; \
      break;\
    case TYPE_CHAR:\
      if (tupleValue.c != cond.value.c) return FALSE; \
      break;\
    case TYPE_UINT8:\
      if (tupleValue.int8 != cond.value.int8) return FALSE; \
      break;\
    default:\
      return FALSE;\
  }\
}

/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareLT(tupleValue, cond)\
{\
  switch (currentFormat->types[q->conds[i].fieldNr]) {\
    case TYPE_UINT16:\
      if (tupleValue.int16 >= cond.value.int16) return FALSE; \
      break;\
    case TYPE_UINT8:\
      if (tupleValue.int8 >= cond.value.int8) return FALSE; \
      break;\
    case TYPE_CHAR:\
      if (tupleValue.c >= cond.value.c) return FALSE; \
      break;\
    default:\
      return FALSE;\
  }\
}

/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareGT(tupleValue, cond)\
{\
  switch (currentFormat->types[q->conds[i].fieldNr]) {\
    case TYPE_UINT16:\
      if (tupleValue.int16 <= cond.value.int16) return FALSE; \
      break;\
    case TYPE_UINT8:\
      if (tupleValue.int8 <= cond.value.int8) return FALSE; \
      break;\
    case TYPE_CHAR:\
      if (tupleValue.c <= cond.value.c) return FALSE; \
      break;\
    default:\
      return FALSE;\
  }\
}

/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareLTE(tupleValue, cond)\
{\
  switch (currentFormat->types[q->conds[i].fieldNr]) {\
    case TYPE_UINT16:\
      if (tupleValue.int16 > cond.value.int16) return FALSE; \
      break;\
    case TYPE_UINT8:\
      if (tupleValue.int8 > cond.value.int8) return FALSE; \
      break;\
    case TYPE_CHAR:\
      if (tupleValue.c > cond.value.c) return FALSE; \
      break;\
    default:\
      return FALSE;\
  }\
}


/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareGTE(tupleValue, cond)\
{\
  switch (currentFormat->types[q->conds[i].fieldNr]) {\
    case TYPE_UINT16:\
      if (tupleValue.int16 < cond.value.int16) return FALSE; \
      break;\
    case TYPE_UINT8:\
      if (tupleValue.int8 < cond.value.int8) return FALSE; \
      break;\
    case TYPE_CHAR:\
      if (tupleValue.c < cond.value.c) return FALSE; \
      break;\
    default:\
      return FALSE;\
  }\
}

/*
 * Fragment of a compareTuple function.
 * Return false if the tuple does not meet the freshness condition of the query
 * This macro is used by the generic compareTuple func only.
 */
#define compareFreshness(t, cond)\
{\
  if (currentTime - getLogicalTime(&(t->tuple)) < (cond).value.int16) return FALSE;\
}


 /*
  * Generic query function. Compare a tuple against a query.
  * This function is an exact copy of compareTuple_GENERIC2().
  * Nr 1 is called from findTuples(), nr 2 is called from triggerReactions().
  * We have copied this function to force inlining. Inlining avoids many function calls
  * during query execution and the triggering of reactions.
  * Inlining makes queries perform 25% faster.
  * @param q: a pointer to the query to compare with this tuple
  * @param t: a pointer to the tuple to be comapred
  */
bool compareTuple_GENERIC1(Query *q, tupleWrapper *t) {
  uint8_t i;

  for (i = 0; i < q->nrConds; i++) {
    switch (q->conds[i].cmpFunc) {
      case COND_EQ:
        compareEQ(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_LT:
        compareLT(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_GT:
        compareGT(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_GTE:
        compareGTE(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_LTE:
        compareLTE(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_FRESHNESS:
        compareFreshness(t, q->conds[i]);
        break;
      default:
        return FALSE;
    }
  }
  return TRUE;
}

 /*
  * Generic query function. Compare a tuple against a query.
  * This function is an exact copy of compareTuple_GENERIC1().
  * Nr 1 is called from findTuples(), nr 2 is called from triggerReactions().
  * We have copied this function to force inlining. Inlining avoids many function calls
  * during query execution and the triggering of reactions.
  * Inlining makes queries perform 25% faster.
  * @param q: a pointer to the query to compare with this tuple
  * @param t: a pointer to the tuple to be comapred
  */
bool compareTuple_GENERIC2(Query *q, tupleWrapper *t) {
  uint8_t i;

  for (i = 0; i < q->nrConds; i++) {
    switch (q->conds[i].cmpFunc) {
      case COND_EQ:
        compareEQ(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_LT:
        compareLT(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_GT:
        compareGT(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_GTE:
        compareGTE(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_LTE:
        compareLTE(t->tuple.fields[q->conds[i].fieldNr], q->conds[i]);
        break;
      case COND_FRESHNESS:
        compareFreshness(t, q->conds[i]);
        break;
      default:
        return FALSE;
    }
  }
  return TRUE;
}


/*
 * Set the time to be used later in compareTuple_XXX()
 * The time value is used for queries with a freshness requirement.
 */
void setCurrentTime(uint16_t logicalTime) {
  currentTime = logicalTime;
}

/*
 * Set the format in preperation of calling compareTuple/compareQuery multiple times
 */
void setCurrentFormat(uint8_t fmtID) {
  currentFormat = &(formats[fmtID]);
}


 /*
  * An example compareTuple() function for query generation based on query formats.
  * Extremely fast: 73% faster than the generic query method (without code
  * generation) and 63% faster than query generation based on tuple formats.
  * However, this method is not used, because we want to avoid that the programmer
  * has to specify the queries in a seperated file.
  *
  * In addition to being faster, this method requires much less program memory than
  * the current code generation function.
  * This so called 'generated' function expects the programmer to define the query
  * in a special file, just like tuple formats. Condition functions like COND_EQ are
  * also defined in this file, only the actual values in the query are set at runtime.
  *
  * A query format looks like: q_fmt(QUERY_FMT_A, MY_TUPLE_FMT, eqCond(0), eqCond(2))
  * This query format would result in the following query function:
  */
bool compareTuple_QUERY_FMT_A(Query *q, tupleWrapper *t) {

  if ((t->tuple.fields[0].int16 == q->conds[0].value.int16) &&
      (t->tuple.fields[2].int16 == q->conds[2].value.int16)) {
        dbg3("match\n");
    return TRUE;
  } else {
    dbg3("compare failed\n");
    return FALSE;
  }
}


#endif // TUPLE_SPACE_H
