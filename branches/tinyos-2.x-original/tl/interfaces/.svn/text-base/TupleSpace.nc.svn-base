/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 36 $
 * * DATE
 * *    $LastChangedDate: 2007-05-25 17:23:22 +0200 (Fri, 25 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TupleSpace.nc 36 2007-05-25 15:23:22Z bronwasser $
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
 * The tuple space interface exported to the application.
 * 
 * @author Paolo Costa 
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 * 
 */

interface TupleSpace {

  // Standard operations
  command TLOpId_t out(bool reliable, TLTarget_t target, tuple *t);
  command TLOpId_t rd(bool reliable, TLTarget_t target, tuple *templ);
  command TLOpId_t in(bool reliable, TLTarget_t target, tuple *templ);

  // Reliable group operations
  command TLOpId_t rdg(bool reliable, TLTarget_t target, tuple *templ);
  command TLOpId_t ing(bool reliable, TLTarget_t target, tuple *templ);

  // Managing reactions
  command TLOpId_t addReaction(bool reliable, TLTarget_t target, 
			       tuple *templ);
  command TLOpId_t removeReaction(TLOpId_t operationId);

  // Request to reify a capability tuple
  event error_t reifyCapabilityTuple(tuple* ct);

  // Returning tuples
  event error_t tupleReady(TLOpId_t operationId, tuple *tuples, 
			    uint8_t number);
}
