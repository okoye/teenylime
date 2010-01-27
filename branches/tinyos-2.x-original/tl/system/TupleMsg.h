/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 28 $
 * * DATE
 * *    $LastChangedDate: 2007-05-04 16:08:54 +0200 (Fri, 04 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TupleMsg.h 28 2007-05-04 14:08:54Z bronwasser $
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
 * Definition of network messages.
 * 
 * @author Paolo Costa 
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 * 
 */

#ifndef TUPLEMSG_H
#define TUPLEMSG_H

#include "TupleSpace.h"
#include "TLConf.h"

#ifndef mica2
char tupleMsgString[100];
#endif

typedef enum {
  OUT_OP,
  RD_OP,
  IN_OP,
  RDG_OP,
  ING_OP,
  REACT,
  QUERY_RESULT,
  REACTION_FIRING,
  BEACON,
/*   SIM_MSG, // DEBUG: This is used in the simulation to represent background */
/* 	   // load */
  NULL_MSG
} msg_t;

typedef struct TupleMsg {
  tuple nghTuple;
  tuple tuples[MAX_TUPLES_MSG];
  uint8_t tupleNumber;
  msg_t operation;
  TLOpId_t operationId;
} TupleMsg;

enum {
  TUPLE_AM
};

#ifndef mica2
char* printTupleMsg(TupleMsg *tupleMsg) {
  char type[20];
  char target[10];
  char reliable[20];
  char id[5];

  switch(tupleMsg->operation) {
  case OUT_OP:
    sprintf(type, "OUT_OP");
    break;
  case RD_OP:
    sprintf(type, "RD_OP");
    break;
  case RDG_OP:
    sprintf(type, "RDG_OP");
    break;
  case QUERY_RESULT:
    sprintf(type, "QUERY_RESULT");
    break;
  case REACT:
    sprintf(type, "REACT");
    break;
  case REACTION_FIRING:
    sprintf(type, "REACTION_FIRING");
    break;
  case BEACON:
    sprintf(type, "BEACON");
    break;
/*   case SIM_MSG: */
/*     sprintf(type, "SIM_MSG"); */
/*     break; */
  default:
    sprintf(type, "UNKNOWN_TYPE");
  }

  sprintf(tupleMsgString, "[type:%s, id:%s, from:%d, to:%s, size:%d, %s]", type, id, tupleMsg->operationId.msgOrigin, target, (int) sizeof(TupleMsg), reliable);

  return tupleMsgString;
}
#endif

#endif //TUPLEMSG_H
