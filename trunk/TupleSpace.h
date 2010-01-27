/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 25 $
 * * DATE
 * *    $LastChangedDate: 2007-05-03 11:09:31 -0500 (Thu, 03 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: paolinux78 $
 * *
 * *	$Id: TupleSpace.h 25 2007-05-03 16:09:31Z paolinux78 $
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
#include "TLConf.h"

#ifdef FLOAT_SUPPORT
#include <float.h>
#endif


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
  TYPE_UINT16_T, TYPE_FLOAT, 
  TYPE_CHAR, TYPE_STR, 
  TYPE_RANGE_LOW_IN, TYPE_RANGE_LOW_OUT, 
  TYPE_RANGE_UP_IN, TYPE_RANGE_UP_OUT,
  TYPE_RANGE_LOW_UP_IN, TYPE_RANGE_LOW_UP_OUT,
  TYPE_RANGE_UP_LOW_IN, TYPE_RANGE_UP_LOW_OUT,
  TYPE_DONT_CARE
};

typedef union fieldValue {
  uint8_t int8;
  uint16_t int16;
#ifdef FLOAT_SUPPORT
  float flt;
#endif
  char c;
  char str[STR_SIZE];
  uint16_t range_int16;
} fieldValue;

typedef struct field {
  fieldType type;
  fieldValue value;
} field;
//__attribute__((__packed__)) field;

typedef struct BigField {
  field f[2];
} BigField;


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
  f.type = (TYPE_FORMAL | TYPE_RANGE_LOW_IN);
  
  f.value.range_int16 = bound;

  return f;
}

field lowerOutField(uint16_t bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_LOW_OUT);
  
  f.value.range_int16 = bound;

  return f;
}


field greaterField(uint16_t bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_UP_IN);
  
  f.value.range_int16 = bound;

  return f;
}

field greaterOutField(uint16_t bound) {
  field f;
  f.type = (TYPE_FORMAL | TYPE_RANGE_UP_OUT);
  
  f.value.range_int16 = bound;

  return f;
}


BigField rangeField(uint16_t lower_bound, uint16_t upper_bound) {

  BigField rField;

  rField.f[0].type = (TYPE_FORMAL | TYPE_RANGE_LOW_UP_IN);
  rField.f[0].value.range_int16 = lower_bound;

  rField.f[1].type = (TYPE_FORMAL | TYPE_RANGE_UP_LOW_IN);
  rField.f[1].value.range_int16 = upper_bound;
  
  return rField;
}


BigField rangeOutField(uint16_t lower_bound, uint16_t upper_bound) {
  BigField rField;

  rField.f[0].type = (TYPE_FORMAL | TYPE_RANGE_LOW_UP_OUT);
  rField.f[0].value.range_int16 = lower_bound;

  rField.f[1].type = (TYPE_FORMAL | TYPE_RANGE_UP_LOW_OUT);
  rField.f[1].value.range_int16 = upper_bound;
  
  return rField;

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

#ifdef FLOAT_SUPPORT
field actualField_float(float value) {
  field f;
  f.type = (TYPE_ACTUAL | TYPE_FLOAT);
  f.value.flt = value;

  return f;
}
#endif

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

bool isEmptyField(field *f) {
  return f->type % TYPE_FORMAL == TYPE_EMPTY;
}

field dontCareField() {
  field f;
  f.type = (TYPE_FORMAL | TYPE_DONT_CARE);
  
  return f;
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

tuple newTuple(uint8_t numFields, ...) {
  tuple t;
  int i = 0;
  va_list ap;
  va_start(ap, numFields);
 
  while(i < numFields && i < MAX_FIELDS) {
    t.fields[i] = va_arg(ap, field);
    if(getFieldType(&(t.fields[i])) == TYPE_RANGE_LOW_UP_IN || getFieldType(&(t.fields[i])) == TYPE_RANGE_LOW_UP_OUT) {
      numFields++;
    }
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
      else
	 sprintf(tupleString, "%s formal),", tupleString);
      break;
    case TYPE_UINT16_T:
      sprintf(tupleString, "%s (uint16_t,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s %d),", tupleString, t->fields[i].value.int16);
      else
	 sprintf(tupleString, "%s formal),", tupleString);
      break;
#ifdef FLOAT_SUPPORT
    case TYPE_FLOAT:
      sprintf(tupleString, "%s (float,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s %.2f),", tupleString, t->fields[i].value.flt);
      else
	 sprintf(tupleString, "%s formal),", tupleString);
      break;
#endif
    case TYPE_CHAR:
      sprintf(tupleString, "%s (char,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s \'%c\'),", tupleString, t->fields[i].value.c);
      else
	 sprintf(tupleString, "%s formal),", tupleString);
      break;
    case TYPE_STR:
      sprintf(tupleString, "%s (string,", tupleString);
      if(isFormalField(&(t->fields[i])) == FALSE)
	sprintf(tupleString, "%s \"%s\"),", 
		tupleString, t->fields[i].value.str);
      else
	 sprintf(tupleString, "%s formal),", tupleString);
      break;
    case TYPE_RANGE_LOW_IN:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s <= %d),", tupleString, t->fields[i].value.range_int16);
      break;
    case TYPE_RANGE_LOW_OUT:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s < %d),", tupleString, t->fields[i].value.range_int16);
      break;
    case TYPE_RANGE_UP_IN:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s >= %d),", tupleString, t->fields[i].value.range_int16);
      break;
    case TYPE_RANGE_UP_OUT:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s < %d),", tupleString, t->fields[i].value.range_int16);
      break;
    case TYPE_RANGE_LOW_UP_IN:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s [%d,%d]),", tupleString, t->fields[i].value.range_int16,t->fields[i+1].value.range_int16);
      i++;
      break;
    case TYPE_RANGE_LOW_UP_OUT:
      sprintf(tupleString, "%s (range,", tupleString);
      sprintf(tupleString, "%s (%d,%d)),", tupleString, t->fields[i].value.range_int16,t->fields[i+1].value.range_int16);
      i++;
      break;
    default:
      sprintf(tupleString, "%s (unknown type,", tupleString);
      break;
    }
  }
  tupleString[strlen(tupleString)-1] = ' ';
  sprintf(tupleString, "%s]", tupleString);
  
#endif
}

bool compareRangeLowUpFields(field *range, field* actual, uint8_t rangeCont) {
  uint16_t lower_bound, upper_bound;

  if(isFormalField(&(actual[rangeCont])))
    return FALSE;

  lower_bound = range[rangeCont].value.range_int16;
  upper_bound = range[rangeCont+1].value.range_int16;

  switch(getFieldType(&(actual[rangeCont]))) {
  case TYPE_UINT8_T:
    return (actual[rangeCont].value.int8 <= upper_bound && actual[rangeCont].value.int8 >= lower_bound);
  case TYPE_UINT16_T:
    return (actual[rangeCont].value.int16 <= upper_bound && actual[rangeCont].value.int16 >= lower_bound);
#ifdef FLOAT_SUPPORT
  case TYPE_FLOAT:
    return (actual[rangeCont].value.flt <= upper_bound && actual[rangeCont].value.flt >= lower_bound);
#endif
  default:
    return FALSE;
  }
}

bool compareRangeLowUpOutFields(field *range, field* actual, uint8_t rangeCont) {
  uint16_t lower_bound, upper_bound;

  if(isFormalField(&(actual[rangeCont])))
    return FALSE;

  lower_bound = range[rangeCont].value.range_int16;
  upper_bound = range[rangeCont+1].value.range_int16;

  switch(getFieldType(&(actual[rangeCont]))) {
  case TYPE_UINT8_T:
    return (actual[rangeCont].value.int8 < upper_bound && actual[rangeCont].value.int8 > lower_bound);
  case TYPE_UINT16_T:
    return (actual[rangeCont].value.int16 < upper_bound && actual[rangeCont].value.int16 > lower_bound);
#ifdef FLOAT_SUPPORT
  case TYPE_FLOAT:
    return (actual[rangeCont].value.flt < upper_bound && actual[rangeCont].value.flt > lower_bound);
#endif
  default:
    return FALSE;
  }
}

bool compareRangeFields(field* range, field* actual) {

  fieldType type = getFieldType(range);

  if(isFormalField(actual))
    return FALSE;

  switch(getFieldType(actual)) {
     case TYPE_UINT8_T:
       if(type == TYPE_RANGE_LOW_IN) {
	 return (actual->value.int8 <= range->value.range_int16);
       }
       else {
	 // type == TYPE_RANGE_UP_IN
	 return (actual->value.int8 >= range->value.range_int16);
       }
  case TYPE_UINT16_T:
    if(type == TYPE_RANGE_LOW_IN) {
      return (actual->value.int16 <= range->value.range_int16);
    }
    else {
      // type == TYPE_RANGE_UP_IN
       return (actual->value.int16 >= range->value.range_int16);
    }
#ifdef FLOAT_SUPPORT
  case TYPE_FLOAT:
     if(type == TYPE_RANGE_LOW_IN) {
       return (actual->value.flt <= range->value.range_int16);
     }
     else {
       // type == TYPE_RANGE_UP_IN
       return (actual->value.flt >= range->value.range_int16);
     }
#endif
  default:
    return FALSE;
  }
}

bool compareRangeOutFields(field* range, field* actual) { 

  fieldType type = getFieldType(range);

  if(isFormalField(actual))
    return FALSE;

  switch(getFieldType(actual)) {
     case TYPE_UINT8_T:
       if(type == TYPE_RANGE_LOW_OUT) {
	 return (actual->value.int8 < range->value.range_int16);
       }
       else {
	 // type == TYPE_RANGE_UP_OUT
	 return (actual->value.int8 > range->value.range_int16);
       }
  case TYPE_UINT16_T:
    if(type == TYPE_RANGE_LOW_OUT) {
      return (actual->value.int16 < range->value.range_int16);
    }
    else {
      // type == TYPE_RANGE_UP_OUT
       return (actual->value.int16 > range->value.range_int16);
    }
#ifdef FLOAT_SUPPORT
  case TYPE_FLOAT:
     if(type == TYPE_RANGE_LOW_OUT) {
       return (actual->value.flt < range->value.range_int16);
     }
     else {
       // type == TYPE_RANGE_UP_OUT
       return (actual->value.flt > range->value.range_int16);
     }
#endif
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
  if(fieldType1 == TYPE_RANGE_UP_IN || fieldType1 == TYPE_RANGE_LOW_IN) {
    return compareRangeFields(f1, f2);
  } else if(fieldType2 == TYPE_RANGE_UP_IN || fieldType2 == TYPE_RANGE_LOW_IN) {
    return compareRangeFields(f2, f1);
  } 

  // Range out matching
  if(fieldType1 == TYPE_RANGE_UP_OUT || fieldType1 == TYPE_RANGE_LOW_OUT) {
    return compareRangeOutFields(f1, f2);
  } else if(fieldType2 == TYPE_RANGE_UP_OUT || fieldType2 == TYPE_RANGE_LOW_OUT) {
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
#ifdef FLOAT_SUPPORT
      case TYPE_FLOAT:
	return (f1->value.flt == f2->value.flt);
#endif
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
  uint8_t i1, i2;

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

  for(i1=0, i2=0; i1 < MAX_FIELDS; i1++,i2++) {
    if(getFieldType(&(t1->fields[i1])) == TYPE_RANGE_LOW_UP_IN) {
      if(compareRangeLowUpFields(t1->fields,t2->fields,i1) == FALSE) {
	return FALSE;
      }
      else {
	// If the template field is a range one, we need to skip the
	// next field because it contains the upper bound
	i1++; 
      }
    }
    else if(getFieldType(&(t1->fields[i1])) == TYPE_RANGE_LOW_UP_OUT) {
      if(compareRangeLowUpOutFields(t1->fields,t2->fields,i1) == FALSE) {
	return FALSE;
      }
      else {
	// If the template field is a range one, we need to skip the
	// next field because it contains the upper bound
	i1++;
      }
    }
    else if(compareFields(&(t1->fields[i1]), &(t2->fields[i2])) == FALSE) {
      return FALSE;
    }
  }
  
  return TRUE;
}

