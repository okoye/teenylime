/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 169 $
 * * DATE
 * *    $LastChangedDate: 2007-10-29 05:32:44 -0500 (Mon, 29 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: BridgeTupleSpace.nc 169 2007-10-29 10:32:44Z bronwasser $
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
 * The interface to bridge remote operations with the local tuple space.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

interface BridgeTupleSpace {

  // Standard operations
  command tupleWrapper *out(Tuple *tuples);
  command result_t rd(Query *q, TLOpId_t *operationId);
  command result_t in(Query *q, TLOpId_t *operationId);

  // To remove tuples internally
  command result_t remove(tupleWrapper *t);
  command tupleWrapper *replace(tupleWrapper *t, Tuple *newTuple);

  // Reliable group operations
  command result_t rdg(Query *q, TLOpId_t *operationId);
  command result_t ing(Query *q, TLOpId_t *operationId);

  // Managing reactions
  command result_t addReaction(Query *q, TLOpId_t *operationId, uint8_t expire);
  command result_t removeReaction(TLOpId_t *operationId);
  command result_t refreshReaction(TLOpId_t *operationId, uint8_t expire);

  // To obtain the current neighborTuple
  command Tuple *getNeighborTuple();

  // Returning tuples
  event result_t tupleReady(TLOpId_t *operationId, Tuple *tuples[],
          uint8_t number, bool reaction);
}

