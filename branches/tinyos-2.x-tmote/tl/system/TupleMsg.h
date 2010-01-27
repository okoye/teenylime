/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 230 $
 * * DATE
 * *    $LastChangedDate: 2007-12-06 01:11:10 -0600 (Thu, 06 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TupleMsg.h 230 2007-12-06 07:11:10Z lmottola $
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

enum {
  TUPLE_AM
};

enum {
  OUT_OP = 1,
  RD_OP = 2,
  IN_OP = 3,
  RDG_OP = 4,
  ING_OP = 5,
  REACT = 6,
  QUERY_RESULT = 7,
  REACTION_FIRING = 8,
  BEACON = 9,  // To remove
  NULL_MSG = 10  // To remove
};

typedef struct TupleMsg {
  uint8_t tupleNumber;  // TODO: Can get rid of this
  uint8_t operation;
  TLOpId_t operationId;
  tuple nghTuple;
  tuple tuples[MAX_TUPLES_MSG];
} TupleMsg;

#endif //TUPLEMSG_H
