/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 9 $
 * * DATE
 * *    $LastChangedDate: 2007-04-28 10:57:00 -0500 (Sat, 28 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TupleSpace.h 9 2007-04-28 15:57:00Z lmottola $
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

#include <stdarg.h>
#include <stdio.h>
#include <float.h>
#include "TLConf.h"

// Definition of possible targets for operations
#define TL_LOCAL TOS_LOCAL_ADDRESS
#define TL_NEIGHBORHOOD TOS_BCAST_ADDR
/* TODO: #define TL_ANY TOS_BCAST_ADDR-1 */

// To distinguish between actual and formal fields
#define TYPE_ACTUAL 0
#define TYPE_FORMAL 128

// To tag tuples with no epoch requirement
#define TIME_UNDEFINED 0

// TeenyLIME internal constants
#define STR_SIZE 4
#define TEENYLIME_SYSTEM_OPERATION 0
#define TEENYLIME_SYSTEM_COMPONENT 0
#define UINT16_MIN 0
#ifndef pc
#define UINT16_MAX 0xFFFF
#define UINT32_MAX 0xFFFFFFFF
#endif

typedef uint16_t TLTarget_t;
typedef uint8_t fieldType;

typedef struct {
  uint8_t componentId;
  uint8_t commandId;
  uint16_t msgOrigin;
  bool reliable;
}  TLOpId_t;
//__attribute__((__packed__)) TLOpId_t;

enum {
  TYPE_EMPTY, TYPE_UINT8_T,  
  TYPE_UINT16_T, TYPE_UINT32_T, 
  TYPE_FLOAT, TYPE_CHAR, TYPE_STR, 
  TYPE_RANGE_IN, TYPE_RANGE_OUT, TYPE_DONT_CARE
};

typedef union fieldValue {
  uint8_t int8;
  uint16_t int16;
  uint32_t int32;	
  float flt;
  char c;
  char str[STR_SIZE];
  uint16_t range_int16[2];
} fieldValue;

typedef struct field {
  fieldType type;
  fieldValue value;
} field;
//__attribute__((__packed__)) field;

typedef struct tuple {
  // In the case of a real tuple, the following is the timestamp when
  // the tuple was output, in case of a template, it specifies a
  // freshness requirement wrt to the local time
  uint16_t logicalTime;
  // The number of epochs this tuple should survive
  uint16_t expireIn;
  bool capabilityT;
  field fields[MAX_FIELDS];
} tuple;
//__attribute__((__packed__)) tuple;

// To return a code error to the application, this must use isFailed() to check
#define TL_OP_FAIL 0
bool isFailed(TLOpId_t* opId) {
  if (opId->commandId == 0) return TRUE;
  else return FALSE;
}

field formalField(fieldType type) {
  field f;
  f.type = (TYPE_FORMAL | type);
  
  return f;
}

field lowerField(uint16_t bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_IN);
  
  f.value.range_int16[0] = UINT16_MIN;
  f.value.range_int16[1] = bound;

  return f;
}

field greaterField(uint16_t bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_IN);
  
  f.value.range_int16[0] = bound;
  f.value.range_int16[1] = UINT16_MAX;

  return f;
}

field rangeField(uint16_t lower_bound, uint16_t upper_bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_IN);
  
  f.value.range_int16[0] = lower_bound;
  f.value.range_int16[1] = upper_bound;

  return f;
}

field rangeOutField(uint16_t lower_bound, uint16_t upper_bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_OUT);
  
  f.value.range_int16[0] = lower_bound;
  f.value.range_int16[1] = upper_bound;

  return f;
}

field actualField_uint8(uint8_t value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_UINT8_T);
  f.value.int8 = value;

  return f;
}

field actualField_uint16(uint16_t value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_UINT16_T);
  f.value.int16 = value;

  return f;
}

field actualField_uint32(uint32_t value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_UINT32_T);
  f.value.int32 = value;

  return f;
}

field actualField_float(float value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_FLOAT);
  f.value.flt = value;

  return f;
}

field actualField_char(char value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_CHAR);
  f.value.c = value;

  return f;
}

field actualField_str(char value[]) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_STR);
  strncpy(f.value.str, value, STR_SIZE-1);
  f.value.str[STR_SIZE-1] = '\0';

  return f;
}

field emptyField() {
  field f;
  f.type = TYPE_EMPTY | TYPE_FORMAL;

  return f;
}

field dontCareField() {
  field f;
  f.type = (TYPE_FORMAL | TYPE_DONT_CARE);
  
  return f;
}

tuple newTuple(uint8_t numFields, ...) {
  tuple t;
  int i = 0;
  va_list ap;
  va_start(ap, numFields);
 
  while(i < numFields && i < MAX_FIELDS) {
    t.fields[i] = va_arg(ap, field);
    i++;
  }    

  while(i < MAX_FIELDS) {
    t.fields[i] = emptyField(); 
    i++;
  }

  t.logicalTime = TIME_UNDEFINED;
  t.expireIn = TIME_UNDEFINED;
  t. capabilityT = FALSE;

  return t;
}

tuple newCapabilityTuple(uint8_t numFields, ...) {
  tuple t;
  int i = 0;
  va_list ap;
  va_start(ap, numFields);
 
  while(i < numFields && i < MAX_FIELDS) {
    t.fields[i] = va_arg(ap, field);
    i++;
  }    

  while(i < MAX_FIELDS) {
    t.fields[i] = emptyField(); 
    i++;
  }

  t.logicalTime = TIME_UNDEFINED;
  t.expireIn = TIME_UNDEFINED;
  t.capabilityT = TRUE;

  return t;
}

// TODO: Shall we check if templ is indeed a template? 
void setFreshness(tuple* templ, uint16_t freshness) {
  templ->logicalTime = freshness;
}

void setExpireIn(tuple* t, uint16_t expireIn) {
  t->expireIn = expireIn;
}

uint16_t getFreshness(tuple* t) {
  return t->logicalTime;
}

tuple emptyTuple() {
  return newTuple(0);
}

tuple dontCareTuple() {
  tuple t;
  uint8_t i;

  for(i = 0; i < MAX_FIELDS; i++) {
    t.fields[i] = dontCareField();
  }

  t.logicalTime = TIME_UNDEFINED;
  t.expireIn = TIME_UNDEFINED;
  t. capabilityT = FALSE;

  return t;
}


bool isEmptyField(field *f) {
  return f->type % TYPE_FORMAL == TYPE_EMPTY;
}

bool isCapabilityTuple(tuple *t) {
  return t->capabilityT;
}

bool isEmptyTuple(tuple *t) {
  uint8_t i;

  for(i = 0; i < MAX_FIELDS; i++) {
    if(isEmptyField(&(t->fields[i])) == FALSE) {
      return FALSE;
    }    
  }

  return TRUE;
}

uint8_t getTupleSize(tuple *t) {
  uint8_t i = 0;

  while(i < MAX_FIELDS && !isEmptyField(&(t->fields[i]))) {
    i++;
  }

  return i;
}

bool isFormalField(field *f) {
  return ((f->type & TYPE_FORMAL) == TYPE_FORMAL);
}

fieldType getFieldType(field *f) {
  return (f->type % TYPE_FORMAL);
}

field* getField(tuple* t, uint8_t loc) {
  if(loc >= MAX_FIELDS || isEmptyField(&(t->fields[loc]))) {
    return NULL;
  }
  else {
    return &(t->fields[loc]);
  }
}

void printTuple(tuple *t, char tupleString[]) { 

  #ifndef mica2
  
  uint8_t i;  
  sprintf(tupleString, "[");

  for(i = 0; i < MAX_FIELDS; i++) {
    if((t->fields[i].type % TYPE_FORMAL) == TYPE_EMPTY) {
      sprintf(tupleString, "%s ", tupleString);
      break;
    }
    else if((t->fields[i].type % TYPE_FORMAL) == TYPE_DONT_CARE) {
      sprintf(tupleString, "%s (don't care),", tupleString);
      continue;
    }
    
    switch(t->fields[i].type % TYPE_FORMAL) {
    case TYPE_UINT8_T:
      sprintf(tupleString, "%s (uint8_t,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s %d),", tupleString, t->fields[i].value.int8);
      break;
    case TYPE_UINT16_T:
      sprintf(tupleString, "%s (uint16_t,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s %d),", tupleString, t->fields[i].value.int16);
      break;
    case TYPE_UINT32_T:
      sprintf(tupleString, "%s (uint32_t,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
      	sprintf(tupleString, "%s %d),", tupleString, t->fields[i].value.int32);
      break;
    case TYPE_FLOAT:
      sprintf(tupleString, "%s (float,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s %.2f),", tupleString, t->fields[i].value.flt);
      break;
    case TYPE_CHAR:
      sprintf(tupleString, "%s (char,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s \'%c\'),", tupleString, t->fields[i].value.c);
      break;
    case TYPE_STR:
      sprintf(tupleString, "%s (string,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s \"%s\"),", 
		tupleString, t->fields[i].value.str);
      break;
    case TYPE_RANGE_IN:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s [%d:%d]),", 
	      tupleString, t->fields[i].value.range_int16[0], 
	      t->fields[i].value.range_int16[1]);
      break;
    case TYPE_RANGE_OUT:
      sprintf(tupleString, "%s (range out,", tupleString);
      sprintf(tupleString, "%s [%d:%d]),", tupleString, 
	      t->fields[i].value.range_int16[0], 
	      t->fields[i].value.range_int16[1]);
      break;
    default:
      sprintf(tupleString, "%s (unknown type,", tupleString);
      break;
    }

    if(isFormalField(&(t->fields[i])) == TRUE && getFieldType(&(t->fields[i])) != TYPE_RANGE_IN && getFieldType(&(t->fields[i])) != TYPE_RANGE_OUT) {
      sprintf(tupleString, "%s formal),", tupleString);
    }
  }

  tupleString[strlen(tupleString)-1] = ' ';
  sprintf(tupleString, "%s]", tupleString);    

  #endif
}

bool compareRangeFields(field* range, field* actual) {
  if(isFormalField(actual))
     return FALSE;

  switch(getFieldType(actual)) {
     case TYPE_UINT8_T:
       return (range->value.range_int16[0] <= actual->value.int8 
	       && range->value.range_int16[1] >= actual->value.int8);
  case TYPE_UINT16_T:
    return (range->value.range_int16[0] <= actual->value.int16 
	    && range->value.range_int16[1] >= actual->value.int16);
  case TYPE_FLOAT:
    return (range->value.range_int16[0] <= actual->value.flt 
	    && range->value.range_int16[1] >= actual->value.flt);
  default:
    return FALSE;
  }
}

bool compareRangeOutFields(field* range, field* actual) {

  if(isFormalField(actual))
     return FALSE;

  switch(getFieldType(actual)) {
     case TYPE_UINT8_T:
       return (range->value.range_int16[0] >= actual->value.int8 
	       || range->value.range_int16[1] <= actual->value.int8);
  case TYPE_UINT16_T:
    return (range->value.range_int16[0] >= actual->value.int16 
	    || range->value.range_int16[1] <= actual->value.int16);
  case TYPE_FLOAT:
    return (range->value.range_int16[0] >= actual->value.flt 
	    || range->value.range_int16[1] <= actual->value.flt);
  default:
    return FALSE;
  }
}
  
bool compareFields(field *f1, field *f2) {

  fieldType fieldType1 = getFieldType(f1);
  fieldType fieldType2 = getFieldType(f2);

  if(fieldType1 == TYPE_DONT_CARE || fieldType2 == TYPE_DONT_CARE) {
    return TRUE;
  }

  // Range matching
  if(fieldType1 == TYPE_RANGE_IN) {
    return compareRangeFields(f1, f2);
  } else if(fieldType2 == TYPE_RANGE_IN) {
    return compareRangeFields(f2, f1);
  } 

  // Range out matching
  if(fieldType1 == TYPE_RANGE_OUT) {
    return compareRangeOutFields(f1, f2);
  } else if(fieldType2 == TYPE_RANGE_OUT) {
    return compareRangeOutFields(f2, f1);
  } 

  if(fieldType1 != fieldType2) {
    return FALSE;  
  } else {
    if(isFormalField(f1) || isFormalField(f2)) {
      return TRUE;
    } else {
      switch(fieldType1) {
      case TYPE_UINT8_T:
	return (f1->value.int8 == f2->value.int8);
      case TYPE_UINT16_T:
	return (f1->value.int16 == f2->value.int16);
      case TYPE_UINT32_T:
	return (f1->value.int32 == f2->value.int32);
      case TYPE_FLOAT:
	return (f1->value.flt == f2->value.flt);
      case TYPE_CHAR:
	return (f1->value.c == f2->value.c);
      case TYPE_STR:
	return (strncmp(f1->value.str, f2->value.str, STR_SIZE) == 0);	
      default:
	return FALSE;
      }
    }
  }
}

bool compareFreshness (tuple* templ, tuple* t, uint16_t localTime) {

  if (isEmptyTuple(t)) { 
    return FALSE;
  } else if (templ->logicalTime == TIME_UNDEFINED) { 
    return TRUE;
  } else if (localTime - t->logicalTime < templ->logicalTime) {
    return TRUE;
  } else {
    return FALSE;
  }
}      

bool isTemplate(tuple* t) {
  uint8_t i;

  for(i=0; i < MAX_FIELDS; i++) {
    if (isFormalField(&(t->fields[i])) && !isEmptyField(&(t->fields[i]))) {
      return TRUE;
    }  
  }
  return FALSE;
}

bool compareTuples(tuple *t1, tuple *t2, uint16_t localTime) {
  uint8_t i;

  // Comparing freshness
  if (!isCapabilityTuple(t1) 
      &&isTemplate(t1) 
      &&!compareFreshness(t1,t2,localTime)) {
    return FALSE;
  } else if (!isCapabilityTuple(t2) 
	     && isTemplate(t2) 
	     && !compareFreshness(t2,t1,localTime)) {
    return FALSE;
  }

  for(i=0; i < MAX_FIELDS; i++) {
    if(compareFields(&(t1->fields[i]), &(t2->fields[i])) == FALSE) {
      return FALSE;
    }
  }
  
  return TRUE;
}

