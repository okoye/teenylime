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
 * *	$Id: TeenySlabAllocator.nc 843 2009-05-18 08:46:04Z sguna $
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
#include "TLConf.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

//#define SLAB_STATS

#if defined(SLAB_STATS) && defined(PRINTF_SUPPORT)
#define stat_printf(...) printf(__VA_ARGS__)
#define pflush() call PrintfFlush.flush()
#else
#define stat_printf(...)
#define pflush()
#endif

/**
 * The component that provides the memory allocator.
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 */

module TeenySlabAllocator {
  provides {
    interface SlabAllocator;
  }

  uses {
    interface TLDebug;
    interface TLObjects;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  struct slab {
    uint8_t type_size;
    uint16_t count;
    uint8_t used[SLAB_BITMAP_SIZE];
    uint8_t can_delete[SLAB_BITMAP_SIZE];
    uint8_t can_match[SLAB_BITMAP_SIZE];
    uint8_t data[SLAB_SIZE];
  };

  uint8_t slab_initialized = 0;
  struct slab slabs[SLABS_NUM];

  int test_bit(uint8_t bitmap[], int idx)
  {
    int i = idx >> 3;
    int r = idx - (i << 3);
    return (bitmap[i] >> r) & 0x01;
  }


  void set_bit(uint8_t bitmap[], int idx)
  {
    int i = idx >> 3;
    int r = idx - (i << 3);
    bitmap[i] |= 0x01 << r;
  }


  void clear_bit(uint8_t bitmap[], int idx)
  {
    int i = idx >> 3;
    int r = idx - (i << 3);
    dbg("DBG_SLAB", "tuple clear idx=%d, i=%d, r=%d, result=%x\n", idx, i, r, ~(0x01 << r));
    bitmap[i] &= ~(0x01 << r);
  }


  int ffsb(uint8_t mask)
  {
    int bit;
    if (mask == 0) {
      return 0;
    }
    for (bit = 0; !(mask & 1); bit++)
      mask = (uint8_t) mask >> 1;
    return bit;
  }


  int find_position(uint8_t bitmap[])
  {
    int i;
    for (i = 0; i < SLAB_BITMAP_SIZE; i++) {
      if (bitmap[i] != 0xFF) {
        int bit = ffsb(~bitmap[i]);
        return (i << 3) + bit;
      }
    }
    return -1;
  }


  command error_t SlabAllocator.slabInit()
  {
    if (slab_initialized)
      return FAIL;

    memset(slabs, 0, sizeof(slabs)); 
    slab_initialized = 1;
    return SUCCESS;
  }


  command int SlabAllocator.countTuples()
  {
    int i, n = 0;
    for (i = 0; i < SLABS_NUM; i++)
      n += slabs[i].count;
    return n;
  }


  command int SlabAllocator.count_app_tuples()
  {
    uint16_t i, j, n = 0;
    for (i = 0; i < SLABS_NUM; i++) { 
      int max_objs;
      if (slabs[i].count < 1)
        continue;
      max_objs = SLAB_SIZE / slabs[i].type_size;
      for (j = 0; j < max_objs; j++) 
        if (test_bit(slabs[i].used, j) && test_bit(slabs[i].can_delete, j) &&
                test_bit(slabs[i].can_match, j))
          n++;
    }
    return n;
  }


  command tuple * SlabAllocator.addTuple(tuple *t, bool can_delete,
        bool can_match, TupleIterator *iterator)
  {
    int i;
    int size = call TLObjects.tuple_sizeof(t);
    struct slab *dest_slab = NULL, *empty_slab = NULL;
    int max_objs = SLAB_SIZE / size;
    int position;
    unsigned char *dest;


    /* 
     * Algorithm: select the partial filled slab (with type_id objects). If
     * there is none partial slab, select the first empty slab.
     */
    for (i = 0; i < SLABS_NUM; i++) {
      if (slabs[i].count == 0 && empty_slab == NULL)
        empty_slab = slabs + i;

      if (slabs[i].type_size == size && slabs[i].count < max_objs) {
        dest_slab = slabs + i;
        break;
      }
    }

    /* out of memory */
    if (dest_slab == NULL && empty_slab == NULL) {
/* #ifdef PRINTF_SUPPORT     */
/*       printf("out of memory\n"); */
/*       call PrintfFlush.flush(); */
/* #endif */
      call TLDebug.triggerErr(TUPLE_SPACE_FULL);
      return NULL; 
    }

    if (dest_slab == NULL)
      dest_slab = empty_slab;

    dest_slab->type_size = size;
    dest_slab->count++;
    position = find_position(dest_slab->used);
    set_bit(dest_slab->used, position);
    
    if (can_delete)
      set_bit(dest_slab->can_delete, position);
    else
      clear_bit(dest_slab->can_delete, position);

    if (can_match)
      set_bit(dest_slab->can_match, position);
    else
      clear_bit(dest_slab->can_match, position);

    // special iterator for reactions: returns the added tuple
    if (iterator != NULL) {
      iterator->data.slab.id = dest_slab - slabs;
      iterator->data.slab.obj = position;
      iterator->flags = IT_ONE_TUPLE | IT_REACTION;
      iterator->pattern = NULL;
    }
    
    dest = dest_slab->data + position * size;
    call TLObjects.copy_tuple((tuple *) dest, t);

    dbg("DBG_SLAB", "tuple added at %d.%d\n", dest_slab - slabs, position);
    stat_printf("+[%d.%d],%d,%d%%\n", dest_slab - slabs, position,
            dest_slab->count, dest_slab->count * 100 / max_objs);
    pflush();
    
    return (tuple *) dest; 
  }


  struct slab * fetch_slab(TupleIterator *iterator)
  {
    struct slab *slab = slabs + iterator->data.slab.id;
    int max_objs;

    if (iterator->data.slab.id < 0 || iterator->data.slab.id >= SLABS_NUM)
      return NULL;
    
    max_objs = SLAB_SIZE / slab->type_size;
    if (iterator->data.slab.obj < 0 || iterator->data.slab.obj >= max_objs)
      return NULL;

    return slab;     
  }


  tuple * get_tuple(TupleIterator *iterator)
  {
    struct slab *slab = fetch_slab(iterator);
    tuple *result;

    if (slab == NULL)
      return NULL;

    result =
        (tuple *) (slab->data + iterator->data.slab.obj * slab->type_size);
    return result;
  }


  command tuple * SlabAllocator.getTuple(TupleIterator *iterator)
  {
    return get_tuple(iterator);
  }


  command void SlabAllocator.removeTuple(TupleIterator *iterator, TLOpId_t opId)
  {
    struct slab * slab = fetch_slab(iterator);
    if (slab == NULL)
      return;

    if ((iterator->flags & IT_REMOVE) == 0)
      return;

    if (test_bit(slab->can_delete, iterator->data.slab.obj)) {
      clear_bit(slab->used, iterator->data.slab.obj);
      slab->count--;
      dbg("DBG_SLAB", "tuple removed from %d.%d\n", iterator->data.slab.id,
              iterator->data.slab.obj);
      stat_printf("-[%d.%d],%d,%d%%\n", iterator->data.slab.id,
              iterator->data.slab.obj, slab->count,
              slab->count * 100 / max_objs);
      pflush();
    }
  }


  int search_slab(TupleIterator *iterator, int slab_idx, int start_obj,
          uint16_t logicalTime)
  {
    struct slab *haystack = slabs + slab_idx;
    int max_objs = SLAB_SIZE / haystack->type_size;
    int i;

    for (i = start_obj; i < max_objs; i++) {
      tuple *tmp;
      if ( !(test_bit(haystack->used, i) && test_bit(haystack->can_match, i)))
        continue;

      tmp = (tuple *)(haystack->data + i * haystack->type_size);
      
      if (call TLObjects.compare_tuple(tmp, iterator->pattern) == FALSE)
        continue;
      if (isCapabilityTuple(tmp))
        continue;

      iterator->data.slab.id = slab_idx;
      iterator->data.slab.obj = i;

      return i;
    }
    return -1;
  }


  command bool SlabAllocator.nextPosition(TupleIterator *iterator,
          TLOpId_t operationId, uint16_t logicalTime)
  {
    int i, start_slab = 0, start_obj = 0;
    int size;

    if ((iterator->flags & IT_FINISH) != 0)
      return FALSE;

    // special iterator for reactions: returns the added tuple
    if ((iterator->flags & IT_REACTION) != 0) {
      iterator->flags |= IT_FINISH;
      return TRUE;
    }

    if (iterator->pattern == NULL)
      return FALSE;

    if (iterator->data.slab.id != -1) {
      if ((iterator->flags & IT_ONE_TUPLE) != 0)
        return FALSE;
      start_slab = iterator->data.slab.id;
      start_obj = iterator->data.slab.obj + 1;
    }
    
    size = call TLObjects.tuple_sizeof(iterator->pattern);

    for (i = start_slab; i < SLABS_NUM; i++) {
      if (slabs[i].type_size == size && slabs[i].count > 0) {
        int j = search_slab(iterator, i, start_obj, logicalTime);
        if (j >= 0) {
          dbg("DBG_SLAB", "tuple found at %d.%d\n", i, j);
          return TRUE;
        }
      }
      start_obj = 0; 
    }
    return FALSE;
  }


  int find_slab(void *addr)
  {
    int i;
    if (addr < (void *) slabs || addr >= (void *) (slabs + SLABS_NUM))
      return -1;
    
    for (i = 0; i < SLABS_NUM; i++) {
      if ((void *) (slabs + i) < addr && addr < (void *) (slabs + i + 1))
        return i;
    }
    return -1;
  }


  command void SlabAllocator.removeExactTuple(tuple *t)
  {
    int i, j;
    
    i = find_slab((void *) t);
    if (i < 0 || i >= SLABS_NUM)
      return;

    j = ((char *) t - (char *) &slabs[i].data) / slabs[i].type_size;
    if (!test_bit(slabs[i].used, j))
      return;
    clear_bit(slabs[i].used, j);
    slabs[i].count--;
    stat_printf("x-[%d.%d],%d,%d%%\n", i, j, slabs[i].count,
            slabs[i].count * 100 / (SLAB_SIZE / slabs[i].type_size));
    pflush();
  }


  command error_t SlabAllocator.replaceTuple(tuple *old_tuple,
                    tuple *new_tuple, TupleIterator *iterator)
  {
    int i, j;

    if (old_tuple->type != new_tuple->type)
      return FAIL;

    i = find_slab((void *) old_tuple);
    if (i < 0 || i >= SLABS_NUM)
      return FAIL;

    j = ((char *) old_tuple - (char *) &slabs[i].data) / slabs[i].type_size;
    if (!test_bit(slabs[i].used, j))
      return FAIL;
    
    if (iterator != NULL) {
      iterator->data.slab.id = i;
      iterator->data.slab.obj = j;
      iterator->flags = IT_ONE_TUPLE | IT_REACTION;
      iterator->pattern = NULL;
    }

    call TLObjects.copy_tuple(old_tuple, new_tuple);
    return SUCCESS;
  }


  void prune_slab(struct slab *slab, uint16_t ts)
  {
    int max_objs = SLAB_SIZE / slab->type_size;
    int i;

    for (i = 0; i < max_objs; i++) {
      tuple *tmp;
      if (!test_bit(slab->used, i))
        continue;

      tmp = (tuple *)(slab->data + i * slab->type_size);
      if (tmp->expireIn != TIME_UNDEFINED &&
          tmp->logicalTime + tmp->expireIn <= ts &&
          test_bit(slab->can_delete, i)) { 
        clear_bit(slab->used, i);
        dbg("DBG_SLAB", "tuple removed from %d.%d\n", slab - slabs, i);
        slab->count--;
        stat_printf("-[%d.%d],%d,%d%%\n", slab - slabs, i, slab->count,
                slab->count * 100 / max_objs);
      }
    }
        pflush();
  }


  command void SlabAllocator.pruneExpiredTuples(uint16_t logicalTime)
  {
    int i;

    for (i = 0; i < SLABS_NUM; i++) {
      if (slabs[i].count == 0)
        continue;
      prune_slab(slabs + i, logicalTime);
    }
  }

  command void SlabAllocator.clear()
  {
    uint16_t i, j;
    for (i = 0; i < SLABS_NUM; i++) { 
      int max_objs;
      if (slabs[i].count < 1)
        continue;
      max_objs = SLAB_SIZE / slabs[i].type_size;
      for (j = 0; j < max_objs; j++) 
        if (test_bit(slabs[i].used, j) && test_bit(slabs[i].can_delete, j) &&
                test_bit(slabs[i].can_match, j)) {
          clear_bit(slabs[i].used, j);
          slabs[i].count--;
        }
    }
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
 
}
