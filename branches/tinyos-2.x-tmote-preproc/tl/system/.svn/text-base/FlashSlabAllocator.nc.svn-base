/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 579 $
 * * DATE
 * *    $LastChangedDate: 2008-07-22 12:21:13 +0200 (Tue, 22 Jul 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: PersistentSlabAllocator.nc 579 2008-07-22 10:21:13Z sguna $
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
#include "TMoteTuning.h"
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
 * The component that provides the memory allocator. The data is persisted on
 * the flash.
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 */

module FlashSlabAllocator {
  provides {
    interface SlabAllocator;
    interface SlabSerializer;
  }

  uses {
    interface TLDebug;
    interface TLObjects;
    interface FlashStorage;
    interface FlashOperations;
    interface Leds;
    interface Timer<TMilli> as PersistenceSyncTimer;
    interface Tuning;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  struct slab_header {
    uint8_t type_size;
    uint16_t used_count;
    uint16_t invalid_count;
    uint8_t used[PSLAB_BITMAP_SIZE];
    uint8_t invalid[PSLAB_BITMAP_SIZE];
  };

  TLOpId_t operation_id;
  bool busy = FALSE;

  /* used by applications */
  TupleIterator iterator;
  char pattern_buffer[MAX_TUPLE_SIZE];
  /* The slab headers are kept in RAM and periodically dumped on the flash. */
  struct slab_header headers[PSLABS_NUM];

  char tuple_buffer[MAX_TUPLE_SIZE], tuple_tmp[MAX_TUPLE_SIZE];
  
  int it_slab_idx, it_tuple_idx;
  bool it_finished;
  
  bool save_meta_req = FALSE;


  /* TODO: put the bit functions in a library to share them with
   * TeenySlabAllocator */
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
    bitmap[i] &= ~(0x01 << r);
  }


  // Find First Set Bit
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


  int find_position(uint8_t used[], uint8_t invalid[])
  {
    int i;
    for (i = 0; i < SLAB_BITMAP_SIZE; i++) {
      if (used[i] != 0xFF && invalid[i] != 0xFF) {
        int bit = ffsb(~used[i] & ~invalid[i]);
        return (i << 3) + bit;
      }
    }
    return -1;
  }


  void local_lock()
  {
    busy = TRUE;
    call Tuning.set(KEY_RADIO_CONTROL, RADIO_OFF);
  }


  void local_unlock()
  {
    if (save_meta_req) {
      call FlashOperations.lock();
      call FlashStorage.saveMeta(headers, sizeof(headers));
    }
    else {
      busy = FALSE;
      call Tuning.set(KEY_RADIO_CONTROL, RADIO_ON);
    }
  }


  task void swap()
  {
    if (busy) {
      post swap();
      return;
    }
    local_lock();
    call FlashOperations.lock();
    call FlashStorage.swap();
  }


  void schedule_sync()
  {
    if (call PersistenceSyncTimer.isRunning())
      return;
    call PersistenceSyncTimer.startOneShot(FLASH_SYNC_TIME);
  }



  command error_t SlabAllocator.slabInit()
  {
    local_lock();
    return call FlashStorage.loadMeta(headers, sizeof(headers));
  }


  event void FlashStorage.resetDone(error_t error)
  {
    local_unlock();
    schedule_sync();
    signal SlabAllocator.clearDone();
  }


  command int SlabAllocator.countTuples()
  {
    /* TODO */ 
    return -1;
  }

  command int SlabAllocator.count_app_tuples()
  {
    /* TODO */
    return -1;
  }

  command tuple * SlabAllocator.addTuple(tuple *t, bool unused1, bool unused2,
          TupleIterator *unused)
  {
    int i;
    int size = call TLObjects.tuple_sizeof(t);
    int dest_slab_idx = -1, empty_slab_idx = -1;
    int max_objs = PSLAB_SIZE / size;
    int position;
    uint32_t dest;

    if (busy)
      return NULL;

    /* 
     * Algorithm: select the partial filled slab (with objects of the same
     * size). If there is no such slab, select the first empty slab.
     */
    for (i = 0; i < PSLABS_NUM; i++) {
      if (headers[i].used_count == 0 && headers[i].invalid_count == 0
              && empty_slab_idx == -1)
        empty_slab_idx = i;

      if (headers[i].type_size == size &&
              headers[i].used_count + headers[i].invalid_count < max_objs) {
        dest_slab_idx = i;
        break;
      }
    }

    /* TODO: maybe we need to swap some slab */
    /* out of memory */
    if (dest_slab_idx == -1 && empty_slab_idx == -1) {
      call TLDebug.triggerErr(TUPLE_SPACE_FULL);
      return NULL; 
    }

    if (dest_slab_idx == -1)
      dest_slab_idx = empty_slab_idx;

    headers[dest_slab_idx].type_size = size;
    headers[dest_slab_idx].used_count++;
    position = find_position(headers[dest_slab_idx].used,
            headers[dest_slab_idx].invalid);
    set_bit(headers[dest_slab_idx].used, position);
   
    dest = dest_slab_idx * PSLAB_SIZE + position * size;
    local_lock();
    call TLObjects.copy_tuple((tuple *) tuple_buffer, t);
    if (call FlashStorage.write(dest, tuple_buffer, size) != SUCCESS)
      return NULL;
    return (tuple *) tuple_tmp;
  }


  command tuple * SlabAllocator.getTuple(TupleIterator *i)
  {
    if ((i->flags & IT_FINISH) != 0) 
      return NULL;
    return (tuple *) tuple_buffer;
  }

  
  command void SlabAllocator.removeTuple(TupleIterator *i, TLOpId_t opId)
  {
    int max_objs;
    if ((i->flags & IT_FINISH) != 0 || (i->flags & IT_REMOVE) == 0) 
      return;
    max_objs = PSLAB_SIZE / headers[i->data.slab.id].type_size;
    clear_bit(headers[i->data.slab.id].used, i->data.slab.obj);
    headers[i->data.slab.id].used_count--;
    set_bit(headers[i->data.slab.id].invalid, i->data.slab.obj);
    headers[i->data.slab.id].invalid_count++;
    schedule_sync();
    if (headers[i->data.slab.id].invalid_count == max_objs)
        post swap();
  }


  int search_slab(int slab_idx, int start_obj)
  {
    struct slab_header *haystack = headers + slab_idx;
    int max_objs = SLAB_SIZE / haystack->type_size;
    uint32_t len, addr;
    int i;

    for (i = start_obj; i < max_objs; i++) {
      if (!test_bit(haystack->used, i))
        continue;

      iterator.data.slab.id = slab_idx;
      iterator.data.slab.obj = i;
      
      local_lock();
      len = headers[slab_idx].type_size;
      addr = slab_idx * PSLAB_SIZE + i * len;
      call FlashStorage.read(addr, tuple_tmp, len);
      return 1;
    }
    return 0;
  }

  
  command bool SlabAllocator.nextPosition(TupleIterator *i, TLOpId_t opId,
                    uint16_t unused)
  {
    int j;
    int start_slab, start_obj;
    int size = call TLObjects.tuple_sizeof(i->pattern);
    (void) unused;

    memcpy(&operation_id, &opId, sizeof(TLOpId_t));
    /* hack: persist the iterator */
    if (i != &iterator) {
      call TLObjects.copy_tuple((tuple *) pattern_buffer, i->pattern);
      memcpy(&iterator, i, sizeof(TupleIterator));
      iterator.pattern = (tuple *) pattern_buffer;
      i = &iterator;
    }
    
    if ((i->flags & IT_FINISH) != 0) {
      call TLObjects.copy_tuple((tuple *) tuple_buffer, (tuple *) tuple_tmp);
      signal SlabAllocator.nextPositionDone(i, opId, FALSE, SUCCESS);
      return FALSE;
    }

    if (busy || i->pattern == NULL) {
      i->flags |= IT_FINISH;
      signal SlabAllocator.nextPositionDone(i, opId, FALSE, FAIL);
      return FALSE;
    }

    start_slab = start_obj = 0;
    if (i->data.slab.id != -1) {
      if ((i->flags & IT_ONE_TUPLE) != 0) {
        i->flags |= IT_FINISH;
        signal SlabAllocator.nextPositionDone(i, operation_id, FALSE, SUCCESS);
        return FALSE;
      }
      start_slab = i->data.slab.id;
      start_obj = i->data.slab.obj + 1;
    }

    for (j = start_slab; j < SLABS_NUM; j++) {
      if (headers[j].type_size == size && headers[j].used_count > 0) {
        if (search_slab(j, start_obj))
          return TRUE;
      }
      start_obj = 0;
    }

    i->flags |= IT_FINISH;
    signal SlabAllocator.nextPositionDone(i, operation_id, FALSE, SUCCESS);
    return TRUE;
  }


  command void SlabAllocator.removeExactTuple(tuple *t)
  {
    /* not supported - no memory to point to :) */
  }


  command error_t SlabAllocator.replaceTuple(tuple *old_tuple,
                    tuple *new_tuple, TupleIterator *i)
  {
    /* not supported - no memory to point to :) */
    return FAIL;
  }


  command void SlabAllocator.pruneExpiredTuples(uint16_t logicalTime)
  {
    /* TODO */
  }

  command void SlabAllocator.clear()
  {
    local_lock();
    memset(headers, 0, sizeof(headers));
    call FlashStorage.reset();
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif


  event void FlashStorage.writeDone(uint32_t addr, void *buf,
          uint32_t len, error_t error) 
  {
    local_unlock();

    iterator.flags = IT_ONE_TUPLE | IT_REACTION;
    iterator.pattern = NULL;
    schedule_sync();

    signal SlabAllocator.addTupleDone(error, (tuple *) buf, &iterator);
  }


  event void FlashStorage.readDone(uint32_t addr, void *buf,
          uint32_t len, error_t error) 
  {
    local_unlock();
    if (error != SUCCESS) {
      signal SlabAllocator.nextPositionDone(&iterator, operation_id, FALSE,
              error);
      return;
    }

    /* no match, next one */
    if (call TLObjects.compare_tuple((tuple *) buf, iterator.pattern) != 
            TRUE) {
      call SlabAllocator.nextPosition(&iterator, operation_id, 0 /*TODO*/); 
      return;
    } 

    call TLObjects.copy_tuple((tuple *) tuple_buffer, (tuple *) buf);
    signal SlabAllocator.nextPositionDone(&iterator, operation_id, TRUE,
            SUCCESS);
  }


  event void FlashStorage.swapDone(error_t error)
  {
    int i;
    for (i = 0; i < PSLABS_NUM; i++) {
      memset(headers[i].invalid, 0, sizeof(PSLAB_BITMAP_SIZE));
      headers[i].invalid_count = 0;
    }
    local_unlock();
    schedule_sync();
    call FlashOperations.operationCompleted();
  }


  event void FlashStorage.saveMetaDone(error_t error)
  {
    save_meta_req = FALSE;
    local_unlock();
    // if anything is pending, run it
    call FlashOperations.operationCompleted();
  }


  event void FlashStorage.loadMetaDone(void *buf, uint32_t len,
          error_t error)
  {
    local_unlock();
    signal SlabAllocator.slabInitDone();
  }
  
  
  /* used by the persistence module */
  command void SlabSerializer.init()
  {
    it_slab_idx = -1;
    it_tuple_idx = -1;
    it_finished = FALSE;
  }


  /* used by the peristence module */
  command error_t SlabSerializer.nextPosition(uint32_t *addr, uint32_t *len)
  {
    int i, j, start_slab, start_tuple;
    if (it_finished)
      return FALSE;
    if (it_slab_idx == -1) {
      start_slab = 0;
      start_tuple = 0;
    } else {
      start_slab = it_slab_idx;
      start_tuple = it_tuple_idx;
    }
    for (i = start_slab; i < PSLABS_NUM; i++) {
      int max_tuples;
      if (headers[i].used_count == 0)
        continue;
      max_tuples = PSLAB_SIZE / headers[i].type_size;
      for (j = start_tuple; j < PSLAB_SIZE; j++) {
        if (test_bit(headers[i].used, j)) {
          *addr = i * PSLAB_SIZE + j * headers[i].type_size;
          *len = headers[i].type_size;
          it_slab_idx = i;
          it_tuple_idx = j + 1;
          return SUCCESS;
        }
      }
    }
    it_finished = TRUE;
    return FAIL;
  }


  event void PersistenceSyncTimer.fired()
  {
    save_meta_req = TRUE;
    if (busy) {
      schedule_sync();
      return;
    }
    call FlashStorage.saveMeta(headers, sizeof(headers));
  }

  event void Tuning.setDone(uint8_t key, uint16_t value)
  {
  }
}

