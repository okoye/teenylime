/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 856 $
 * * DATE
 * *    $LastChangedDate: 2009-06-03 08:23:36 -0500 (Wed, 03 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: BridgeTupleSpace.nc 856 2009-06-03 13:23:36Z sguna $
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

#include "TupleSpace.h"

/**
 * Interface to bridge remote operations with the local tuple space.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

interface BridgeTupleSpace {

  // Standard operations
  command tuple * out(tuple *t, TLOpId_t operationId, bool can_delete, 
        bool can_match);
  command void rd(tuple *templ, TLOpId_t operationId);
  command void in(tuple *templ, TLOpId_t operationId);

  // To manage tuples internally
  command void remove(tuple *addr);
  command tuple * replace(tuple *old, tuple *t, bool can_delete,
        bool can_match);

  // Reliable group operations
  command void rdg(tuple *templ, TLOpId_t operationId);
  command void ing(tuple *templ, TLOpId_t operationId);

  // Managing reactions
  command void addReaction(tuple *templ, TLOpId_t *operationId);
  command void removeReaction(TLOpId_t operationId);

  // To obtain the current neighborTuple
  command tuple* getNeighborTuple();

  // Returning tuples
  event void tupleReady(TLOpId_t operationId, tuple *tuples, 
			    uint8_t number, bool reaction);

  // Makes a time tick goes by
  event void timeTick();
}

