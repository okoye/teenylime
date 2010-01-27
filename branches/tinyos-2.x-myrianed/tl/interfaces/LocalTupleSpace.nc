/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 172 $
 * * DATE
 * *    $LastChangedDate: 2007-10-31 14:38:56 -0500 (Wed, 31 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: LocalTupleSpace.nc 172 2007-10-31 19:38:56Z bronwasser $
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
 * The interface for the local tuple space.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

interface LocalTupleSpace {

  // Standard operations
  command result_t out(Tuple *t, TLOpId_t *operationId);
  command result_t rd(Query *q, TLOpId_t *operationId);
  command result_t in(Query *q, TLOpId_t *operationId);

  // Reliable group operations
  command result_t rdg(Query *q, TLOpId_t *operationId);
  command result_t ing(Query *q, TLOpId_t *operationId);

  // Managing reactions
  command result_t addReaction(Query *q, TLOpId_t *operationId);
  command result_t removeReaction(TLOpId_t *operationId);

  // Request to reify a capability tuple
  event result_t reifyCapabilityTuple(Tuple* ct, TLOpId_t *operationId);

  // Request to set new neighbor tuple
  command uint8_t setNeighborTuple(Tuple *t);

  // Returning tuples
  event result_t tupleReady(TLOpId_t *operationId, Tuple *tuples[], uint8_t number);
}

