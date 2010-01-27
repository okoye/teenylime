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

/**
 * Definition of data structures.
 *
 * @author Paolo Costa
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 *
 */

#ifndef TUPLE_SPACE_H
#define TUPLE_SPACE_H

#include <stdarg.h>
#include <string.h>

#include "tl_objs.h"
#include "TLConstants.h"
#include "TLConf.h"

/* #ifdef FLOAT_SUPPORT */
/* #include <float.h> */
/* #endif */

typedef uint16_t TLTupleSpace_t;
enum {
    RAM_TS,
    FLASH_TS,
#ifdef SECURE_TL
    RECONF_RAM_TS,
    RECONF_FLASH_TS
#endif
};

// Definition of possible operation target
typedef uint16_t TLTarget_t;
#define TL_LOCAL TOS_NODE_ID
#define TL_NEIGHBORHOOD TOS_BCAST_ADDR
/* TODO: #define TL_ANY TOS_BCAST_ADDR-1 */

// Application level TeenyLIME operation id 
typedef struct {
  bool reliable;
  uint8_t componentId;
  uint8_t commandId;
  uint16_t msgOrigin;
} TLOpId_t;

// This has dependencies with TeenyLimeM
#define PROCESS_OP(opId, processing)			\
  atomic {						\
    if (opId.commandId == operationId.commandId		\
	&& opId.commandId != TEENYLIME_NULL_OP) {	\
      if (opId.commandId > MAX_REACTIONS+1) {		\
	opId.commandId = TEENYLIME_NULL_OP;		\
      }							\
      processing					\
    }							\
  }

// This has dependencies with TeenyLimeM
#define CHECK_OP(opId, actualCompletionCode, processing)	\
  atomic {						\
    if (opId.commandId == operationId.commandId		\
	&& opId.commandId != TEENYLIME_NULL_OP		\
	&& completionCode == actualCompletionCode) {	\
      processing					\
    }							\
  }

// Field and tuple formal types
enum {
  MATCH_EQUAL = 0,
  MATCH_ACTUAL = 0, // i.e. equal
  MATCH_DONT_CARE,
  MATCH_GREATER,
  MATCH_GREATER_EQUAL,
  MATCH_LOWER,
  MATCH_LOWER_EQUAL,
  MATCH_DIFFERENT,
  MATCH_MASK
};

enum {
  FLAG_CAPABILITY = 0x01,
  FLAG_PERSISTENT = 0x02,
#ifdef SECURE_TL
  FLAG_SECURE_RECONF = 0x04
#endif
};

typedef nx_struct tuple {
  // In the case of a real tuple, the following is the timestamp when
  // the tuple was output, in case of a template, it specifies a
  // freshness requirement wrt to the local time
  nx_uint16_t logicalTime;
  // The number of epochs this tuple should survive
  nx_uint16_t expireIn;
  nx_uint8_t type;
  nx_uint8_t flags;

  nx_uint8_t contents[0];
} tuple;


// default - no flags
#define IT_DEFAULT     0x0000
// defines a remote operation
#define IT_REMOTE      0x0001
// next_tuple() removes current tuple from tuple space
#define IT_REMOVE      0x0002
// limits one tuple per result
#define IT_ONE_TUPLE   0x0004
// used for reactons
#define IT_REACTION    0x0008
// no more results can be returned
#define IT_FINISH      0x0010

typedef struct {
  int flags;
  union {
    struct {
      int id;
      int obj;
    } slab;
    struct {
      char *tuple;
      int count, max;
    } buffer;
  } data; 
  tuple *pattern;
} TupleIterator; 


// Range matching still to be tested on TMotes

/* typedef struct Field { */
/*   field f[2]; */
/* } Field; */

/* field lowerField(uint16_t bound) { */
/*   field f; */
/*   f.type = (TYPE_FORMAL | TYPE_RANGE_LOW_IN); */

/*   f.value.range_int16 = bound; */

/*   return f; */
/* } */

/* field lowerOutField(uint16_t bound) { */
/*   field f; */
/*   f.type = (TYPE_FORMAL | TYPE_RANGE_LOW_OUT); */

/*   f.value.range_int16 = bound; */

/*   return f; */
/* } */

/* field greaterField(uint16_t bound) { */
/*   field f; */
/*   f.type = (TYPE_FORMAL | TYPE_RANGE_UP_IN); */

/*   f.value.range_int16 = bound; */

/*   return f; */
/* } */

/* field greaterOutField(uint16_t bound) { */
/*   field f; */
/*   f.type = (TYPE_FORMAL | TYPE_RANGE_UP_OUT); */

/*   f.value.range_int16 = bound; */

/*   return f; */
/* } */

/* Field rangeField(uint16_t lower_bound, uint16_t upper_bound) { */

/*   Field rField; */

/*   rField.f[0].type = (TYPE_FORMAL | TYPE_RANGE_LOW_UP_IN); */
/*   rField.f[0].value.range_int16 = lower_bound; */

/*   rField.f[1].type = (TYPE_FORMAL | TYPE_RANGE_UP_LOW_IN); */
/*   rField.f[1].value.range_int16 = upper_bound; */

/*   return rField; */
/* } */

/* Field rangeOutField(uint16_t lower_bound, uint16_t upper_bound) { */
/*   Field rField; */

/*   rField.f[0].type = (TYPE_FORMAL | TYPE_RANGE_LOW_UP_OUT); */
/*   rField.f[0].value.range_int16 = lower_bound; */

/*   rField.f[1].type = (TYPE_FORMAL | TYPE_RANGE_UP_LOW_OUT); */
/*   rField.f[1].value.range_int16 = upper_bound; */

/*   return rField; */

/* } */

/* field actualField_str(char value[]) { */
/*   field f; */
/*   f.type = (TYPE_ACTUAL | TYPE_STR); */
/*   strncpy(f.value.str, value, STR_SIZE-1); */
/*   f.value.str[STR_SIZE-1] = '\0'; */

/*   return f; */
/* } */

// Freshness and capability tuples still to be tested on TMotes

/* tuple newCapabilityTuple(uint8_t numFields, ...) { */
/*   tuple t; */
/*   int i = 0; */
/*   va_list ap; */
/*   va_start(ap, numFields); */

/*   while(i < numFields && i < MAX_FIELDS) { */
/*     t.fields[i] = va_arg(ap, field); */
/*     i++; */
/*   } */

/*   while(i < MAX_FIELDS) { */
/*     t.fields[i] = emptyField(); */
/*     i++; */
/*   } */

/*   t.logicalTime = TIME_UNDEFINED; */
/*   t.expireIn = TIME_UNDEFINED; */
/*   t.capabilityT = TRUE; */

/*   return t; */
/* } */

/* // TODO: Shall we check if templ is indeed a template? */
/* void setFreshness(tuple* templ, uint16_t freshness) { */
/*   templ->logicalTime = freshness; */
/* } */

inline void setExpireIn(tuple* t, uint16_t expireIn) {
  t->expireIn = expireIn;
}

inline uint16_t getExpireIn(tuple* t) {
  return t->expireIn;
}

bool isCapabilityTuple(tuple *t) {
  return (t->flags & FLAG_CAPABILITY);
}

/* bool compareRangeLowUpFields(field *range, field* actual, uint8_t rangeCont) { */
/*   uint16_t lower_bound, upper_bound; */

/*   if(isMatchDontCare(&(actual[rangeCont]))) */
/*     return FALSE; */

/*   lower_bound = range[rangeCont].value.range_int16; */
/*   upper_bound = range[rangeCont+1].value.range_int16; */

/*   switch(getFieldType(&(actual[rangeCont]))) { */
/*   case TYPE_UINT8_T: */
/*     return (actual[rangeCont].value.int8 <= upper_bound &&  */
/* 	    actual[rangeCont].value.int8 >= lower_bound); */
/*   case TYPE_UINT16_T: */
/*     return (actual[rangeCont].value.int16 <= upper_bound &&  */
/* 	    actual[rangeCont].value.int16 >= lower_bound); */
/* #ifdef FLOAT_SUPPORT */
/*   case TYPE_FLOAT: */
/*     return (actual[rangeCont].value.flt <= upper_bound &&  */
/* 	    actual[rangeCont].value.flt >= lower_bound); */
/* #endif */
/*   default: */
/*     return FALSE; */
/*   } */
/* } */

/* bool compareRangeLowUpOutFields(field *range, field* actual, uint8_t rangeCont) { */
/*   uint16_t lower_bound, upper_bound; */

/*   if(isMatchDontCare(&(actual[rangeCont]))) */
/*     return FALSE; */

/*   lower_bound = range[rangeCont].value.range_int16; */
/*   upper_bound = range[rangeCont+1].value.range_int16; */

/*   switch(getFieldType(&(actual[rangeCont]))) { */
/*   case TYPE_UINT8_T: */
/*     return (actual[rangeCont].value.int8 < upper_bound &&  */
/* 	    actual[rangeCont].value.int8 > lower_bound); */
/*   case TYPE_UINT16_T: */
/*     return (actual[rangeCont].value.int16 < upper_bound &&  */
/* 	    actual[rangeCont].value.int16 > lower_bound); */
/* #ifdef FLOAT_SUPPORT */
/*   case TYPE_FLOAT: */
/*     return (actual[rangeCont].value.flt < upper_bound &&  */
/* 	    actual[rangeCont].value.flt > lower_bound); */
/* #endif */
/*   default: */
/*     return FALSE; */
/*   } */
/* } */

/* bool compareRangeFields(field* range, field* actual) { */

/*   uint8_t type = getFieldType(range); */

/*   if(isMatchDontCare(actual)) */
/*     return FALSE; */
  
/*   switch(getFieldType(actual)) { */
/*   case TYPE_UINT8_T: */
/*     if(type == TYPE_RANGE_LOW_IN) { */
/*       return (actual->value.int8 <= range->value.range_int16); */
/*     } */
/*     else { */
/*       // type == TYPE_RANGE_UP_IN */
/*       return (actual->value.int8 >= range->value.range_int16); */
/*     } */
/*   case TYPE_UINT16_T: */
/*     if(type == TYPE_RANGE_LOW_IN) { */
/*       return (actual->value.int16 <= range->value.range_int16); */
/*     } */
/*     else { */
/*       // type == TYPE_RANGE_UP_IN */
/*       return (actual->value.int16 >= range->value.range_int16); */
/*     } */
/* #ifdef FLOAT_SUPPORT */
/*   case TYPE_FLOAT: */
/*      if(type == TYPE_RANGE_LOW_IN) { */
/*        return (actual->value.flt <= range->value.range_int16); */
/*      } */
/*      else { */
/*        // type == TYPE_RANGE_UP_IN */
/*        return (actual->value.flt >= range->value.range_int16); */
/*      } */
/* #endif */
/*   default: */
/*     return FALSE; */
/*   } */
/* } */

/* bool compareRangeOutFields(field* range, field* actual) { */

/*   uint8_t type = getFieldType(range); */

/*   if(isMatchDontCare(actual)) */
/*     return FALSE; */

/*   switch(getFieldType(actual)) { */
/*      case TYPE_UINT8_T: */
/*        if(type == TYPE_RANGE_LOW_OUT) { */
/*    return (actual->value.int8 < range->value.range_int16); */
/*        } */
/*        else { */
/*    // type == TYPE_RANGE_UP_OUT */
/*    return (actual->value.int8 > range->value.range_int16); */
/*        } */
/*   case TYPE_UINT16_T: */
/*     if(type == TYPE_RANGE_LOW_OUT) { */
/*       return (actual->value.int16 < range->value.range_int16); */
/*     } */
/*     else { */
/*       // type == TYPE_RANGE_UP_OUT */
/*        return (actual->value.int16 > range->value.range_int16); */
/*     } */
/* #ifdef FLOAT_SUPPORT */
/*   case TYPE_FLOAT: */
/*      if(type == TYPE_RANGE_LOW_OUT) { */
/*        return (actual->value.flt < range->value.range_int16); */
/*      } */
/*      else { */
/*        // type == TYPE_RANGE_UP_OUT */
/*        return (actual->value.flt > range->value.range_int16); */
/*      } */
/* #endif */
/*   default: */
/*     return FALSE; */
/*   } */
/* } */

#define field_generic_cmp(t1, t2, v1, v2) \
    if (t1 == MATCH_DONT_CARE || t2 == MATCH_DONT_CARE) \
        return TRUE; \
    if (t1 != MATCH_ACTUAL && t2 != MATCH_ACTUAL) \
        return FALSE; \
    if (t1 == MATCH_GREATER || t2 == MATCH_LOWER) \
        return v1 < v2; \
    if (t1 == MATCH_LOWER || t2 == MATCH_GREATER) \
        return v1 > v2; \
    if (t1 == MATCH_GREATER_EQUAL || t2 == MATCH_LOWER_EQUAL) \
        return v1 <= v2; \
    if (t1 == MATCH_LOWER_EQUAL || t2 == MATCH_GREATER_EQUAL) \
        return v1 >= v2; \
    if (t1 == MATCH_DIFFERENT || t2 == MATCH_DIFFERENT) \
        return v1 != v2; \
    if (t2 == MATCH_MASK) \
        return (v1 & v2) == v1; \
    if (t1 == MATCH_MASK) \
        return (v1 & v2) == v2; \
    return v1 == v2; 

#define field_array_generic_cmp(t1, t2, v1, v2, array_count, basic_size) \
    if (t1 == MATCH_DONT_CARE || t2 == MATCH_DONT_CARE) \
        return TRUE; \
    if (t1 != MATCH_ACTUAL || t2 != MATCH_ACTUAL) \
        return FALSE; \
    if (memcmp(v1, v2, array_count * basic_size)) \
        return FALSE; \
    return TRUE;


bool field_uint8_t_cmp(uint8_t t1, uint8_t t2, nx_uint16_t v1, nx_uint16_t v2)
{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_array_uint8_t_cmp(uint8_t t1, uint8_t t2, nx_uint8_t *v1,
        nx_uint8_t *v2, int count)
{
    field_array_generic_cmp(t1, t2, v1, v2, count, 1);
}

bool field_uint16_t_cmp(uint8_t t1, uint8_t t2, nx_uint16_t v1, nx_uint16_t v2)
{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_array_uint16_t_cmp(uint8_t t1, uint8_t t2, nx_uint16_t *v1, 
        nx_uint16_t *v2, int count)
{
    field_array_generic_cmp(t1, t2, v1, v2, count, 2);
}

bool field_uint32_t_cmp(uint8_t t1, uint8_t t2, nx_uint32_t v1, nx_uint32_t v2)
{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_array_uint32_t_cmp(uint8_t t1, uint8_t t2, nx_uint32_t *v1, 
        nx_uint32_t *v2, int count)
{
    field_array_generic_cmp(t1, t2, v1, v2, count, 2);
}

bool field_lqi_cmp(uint8_t t1, uint8_t t2, nx_uint16_t v1, nx_uint16_t v2)
{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_rssi_cmp(uint8_t t1, uint8_t t2, nx_uint16_t v1, nx_uint16_t v2)
{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_char_cmp(uint8_t t1, uint8_t t2, nx_uint16_t v1, nx_uint16_t v2)

{
    field_generic_cmp(t1, t2, v1, v2);
}

bool field_array_char_cmp(uint8_t t1, uint8_t t2, char *v1, char *v2, int count)
{
    field_array_generic_cmp(t1, t2, v1, v2, count, 1);
}

#endif // TUPLE_SPACE_H
