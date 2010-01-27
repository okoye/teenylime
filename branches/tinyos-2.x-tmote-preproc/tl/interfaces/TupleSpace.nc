/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 843 $
 * * DATE
 * *    $LastChangedDate: 2009-05-18 03:46:04 -0500 (Mon, 18 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TupleSpace.nc 843 2009-05-18 08:46:04Z sguna $
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
 * The tuple space interface exported to application components.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

interface TupleSpace {

  command tuple *nextTuple(TLOpId_t opId, TupleIterator *iterator);
  command tuple *getTuple(TupleIterator *iterator);

#ifdef FLASH_SYNC_TIME
  command void nextSplitTuple(TLOpId_t opdId, TupleIterator *iterator);
#endif

  command void clear(TLTupleSpace_t ts);

  // Standard operations
  command void out(TLOpId_t *opId, bool reliable, 
		   TLTarget_t target, TLTupleSpace_t ts, tuple *t);
  command void rd(TLOpId_t *opId, bool reliable, 
		  TLTarget_t target, TLTupleSpace_t ts, tuple *templ);
  command void in(TLOpId_t *opId, bool reliable, 
		  TLTarget_t target, TLTupleSpace_t ts, tuple *templ);

  // Reliable group operations
  command void rdg(TLOpId_t *opId, bool reliable, 
		   TLTarget_t target, TLTupleSpace_t ts, tuple *templ);
  command void ing(TLOpId_t *opId, bool reliable, 
		   TLTarget_t target, TLTupleSpace_t ts, tuple *templ);

  // Managing reactions
  command void addReaction(TLOpId_t *opId, bool reliable, 
			   TLTarget_t target, TLTupleSpace_t ts, tuple *templ);
  command void removeReaction(TLOpId_t *opId, TLOpId_t reactionId);

  // Request to reify a capability tuple
  event void reifyCapabilityTuple(tuple* ct);

  // Returning tuples
  event void tupleReady(TLOpId_t operationId, TupleIterator *iterator); 

  // To signal exceptions
  event void operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target, 
                TLTupleSpace_t ts,  
				tuple* returningTuple);
}
