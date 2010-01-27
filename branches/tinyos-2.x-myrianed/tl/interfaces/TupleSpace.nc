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
 * *	$Id: TupleSpace.nc 169 2007-10-29 10:32:44Z bronwasser $
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
  command void out(TLOpId_t *opId, bool reliable, TLTarget_t target, Tuple *t);
  command void rd(TLOpId_t *opId, bool reliable, TLTarget_t target, Query *q);
  command void in(TLOpId_t *opId, bool reliable, TLTarget_t target, Query *q);

  // Reliable group operations
  command void rdg(TLOpId_t *opId, bool reliable, TLTarget_t target, Query *q);
  command void ing(TLOpId_t *opId, bool reliable, TLTarget_t target, Query *q);

  // Managing reactions
  command void addReaction(TLOpId_t *opId, bool reliable, TLTarget_t target, Query *q);
  command void removeReaction(TLOpId_t *opId);

  // Request to reify a capability tuple
  event error_t reifyCapabilityTuple(Tuple* ct);

  // Returning tuples
  event error_t tupleReady(TLOpId_t *opId, Tuple *tuples[], uint8_t number);
}
