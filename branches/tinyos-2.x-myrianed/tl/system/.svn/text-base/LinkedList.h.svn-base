/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision:19 $
 * * DATE
 * *    $LastChangedDate:2007-05-03 14:29:53 +0200 (Thu, 03 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy:bronwasser $
 * *
 * *  $Id:TupleSpace.h 19 2007-05-03 12:29:53Z bronwasser $
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
 * Linked list functions.
 *
 * @author Laurens Bronwasser
 *
 */


// Tuples, reactions, etc, which are stored in a linked list,
// use this data type to maintain the list.
typedef struct {
  void *next;
  char data[];
} list_t;



  // We wouldn't have to search here if the items were implemented
  // as a double linked list. We have a memory<->cpu tradeoff here. Right
  // now we're choosing in favour of memory.
  // Instead of using a double linked list,
  // most of the time we only delete an item from the list after
  // we've done a linear search to find it. In that case there is some
  // optimization possible, because we've already seen the previous item.
  // A double linked list is not necessary in this case.
  // This is implemented in removeNextFromList().

list_t *getPreviousListItem(list_t *first, list_t *item) {
  list_t *previous = first;
  if (item == first) return NULL;

  while (previous != NULL) {
    if (previous->next == item) break;
    previous = (list_t *) previous->next;
  }
  return previous;
}


void removeFromList(list_t **first, list_t *trash) {
  // Remove trash from a linked list where first is the first item in the
  // list, and trash is the item to be deleted.
  list_t *previous;
  asm("fromlist0:");
  previous = getPreviousListItem(*first, trash);
  if (previous == NULL) {
    *first = trash->next;
  } else {
    previous->next = trash->next;
  }
  asm("fromlist1:");
  return;
}



void removeNextFromList(list_t **first, list_t *previous, list_t *trash) {
  // Remove 'trash' from a linked list where 'first' indicates
  // the first item in the list, and 'previous' is the list item in front of
  // 'trash'. (previous->next == trash)
  if (previous == NULL || trash == *first) {
    *first = trash->next;
  } else {
    previous->next = trash->next;
  }
}
