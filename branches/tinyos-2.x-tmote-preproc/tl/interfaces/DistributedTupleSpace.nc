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
 * *	$Id: DistributedTupleSpace.nc 856 2009-06-03 13:23:36Z sguna $
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
 * The tuple space interface for distributed operations.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

interface DistributedTupleSpace {
  command tuple * nextTuple(TupleIterator *iterator, TLOpId_t operationId);
  command tuple * getTuple(TupleIterator *iterator);

  // Standard operations
  command void out(TLTarget_t target, tuple *t, TLOpId_t operationId);
  command void rd(TLTarget_t target, tuple *templ, TLOpId_t operationId);
  command void in(TLTarget_t target, tuple *templ, TLOpId_t operationId);

  // Reliable group operations
  command void rdg(TLTarget_t target, tuple *templ, TLOpId_t operationId);
  command void ing(TLTarget_t target, tuple *templ, TLOpId_t operationId);

  // Managing reactions
  command void addReaction(TLTarget_t target, tuple *templ, 
			       TLOpId_t *operationId);
  command void removeReaction(TLOpId_t operationId);

  // Returning tuples
  event void tupleReady(TLOpId_t operationId, TupleIterator *iterator); 

  // To signal exceptions
  event void operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* returningTuple);
}

