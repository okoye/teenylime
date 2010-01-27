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
 * *	$Id: SlabAllocator.nc 856 2009-06-03 13:23:36Z sguna $
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
 * The interface to the slab-like memory allocator for the tuple space.
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 */

interface SlabAllocator {

  command error_t slabInit();
  event void slabInitDone();
  command int count_app_tuples();

  command int countTuples();

  command tuple * addTuple(tuple *t, bool can_delete, bool can_match,
          TupleIterator *iterator);
  event void addTupleDone(error_t error, tuple *t, TupleIterator *iterator);

  command void removeExactTuple(tuple *t);
  command error_t replaceTuple(tuple *old_tuple, tuple *new_tuple,
          TupleIterator *iterator);

  command tuple * getTuple(TupleIterator *iterator);

  command void removeTuple(TupleIterator *iterator, TLOpId_t opId);

  command bool nextPosition(TupleIterator *iterator, TLOpId_t opId,
          uint16_t logicalTime);
  event void nextPositionDone(TupleIterator *iterator, TLOpId_t opId, 
          bool found, error_t error);

  command void pruneExpiredTuples(uint16_t logicalTime);

  command void clear();
  event void clearDone();
}

