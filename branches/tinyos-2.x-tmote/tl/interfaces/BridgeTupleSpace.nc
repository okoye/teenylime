/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 246 $
 * * DATE
 * *    $LastChangedDate: 2007-12-22 15:03:32 -0600 (Sat, 22 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: BridgeTupleSpace.nc 246 2007-12-22 21:03:32Z lmottola $
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
  command error_t out(tuple *t, TLOpId_t operationId);
  command error_t rd(tuple *templ, TLOpId_t operationId);
  command error_t in(tuple *templ, TLOpId_t operationId);

  // To manage tuples internally
  command error_t remove(tuple *templ);
  command error_t replace(tuple* old, tuple *t);

  // Reliable group operations
  command error_t rdg(tuple *templ, TLOpId_t operationId);
  command error_t ing(tuple *templ, TLOpId_t operationId);

  // Managing reactions
  command error_t addReaction(tuple *templ, TLOpId_t *operationId);
  command error_t removeReaction(TLOpId_t operationId);

  // To obtain the current neighborTuple
  command tuple* getNeighborTuple();

  // Returning tuples
  event error_t tupleReady(TLOpId_t operationId, tuple *tuples, 
			    uint8_t number, bool reaction);

  // Makes a time tick goes by...
  event void timeTick();
}

