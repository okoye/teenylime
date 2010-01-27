/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 523 $
 * * DATE
 * *    $LastChangedDate: 2008-06-27 16:20:36 +0200 (Fri, 27 Jun 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TMotePersistence.nc 523 2008-06-27 14:20:36Z lmottola $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * The component implementing the persistence interface for the Tmote flash
 * 
 * @author Stefan Guna 
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 * 
 */

module TMotePersistence {

  provides {
    interface FlashStorage;
  }

  uses {
    interface Boot;
    interface BlockWrite as BlockWriteA;
    interface BlockRead as BlockReadA;
    interface BlockWrite as BlockWriteB;
    interface BlockRead as BlockReadB;
    interface BlockWrite as BlockWriteMeta;
    interface BlockRead as BlockReadMeta;

    interface SlabSerializer;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {
  uint16_t active;
  uint8_t buffer[MAX_TUPLE_SIZE];
  bool swapping;
  void *meta;
  uint32_t meta_len;
  bool op_active;

  event void Boot.booted()
  {
  }

  
  command void FlashStorage.swap()
  {
    if (swapping) {
      signal FlashStorage.swapDone(FAIL);
      return;
    }
    swapping = TRUE;
    call SlabSerializer.init();
    switch (active) {
      case 0:
        call BlockWriteB.erase();
        return;
      case 1:
        call BlockWriteA.erase();
        return;
    }
    swapping = FALSE;
    signal FlashStorage.swapDone(FAIL);
  }


  command error_t FlashStorage.reset() 
  {
    active = 0;
    return call BlockWriteA.erase();
  }


  event void BlockWriteA.eraseDone(error_t error) 
  {
    uint32_t addr, len;
    if (!swapping) {
      signal FlashStorage.resetDone(SUCCESS);
      return;
    }
    if (call SlabSerializer.nextPosition(&addr, &len) == FAIL) {
      active = 0;
      swapping = FALSE;
      signal FlashStorage.swapDone(SUCCESS);
      return;
    }
    call BlockReadB.read(addr, &buffer, len);
  }


  event void BlockWriteB.eraseDone(error_t error) 
  {
    uint32_t addr, len;
    if (call SlabSerializer.nextPosition(&addr, &len) == FAIL) {
      active = 1;
      swapping = FALSE;
      signal FlashStorage.swapDone(SUCCESS);
      return;
    }
    call BlockReadA.read(addr, &buffer, len);
  }
  
  
  event void BlockWriteMeta.eraseDone(error_t error) 
  {
    call BlockWriteMeta.write(0, &active, sizeof(active));
  }


  command error_t FlashStorage.write(uint32_t addr, void *buf, 
          uint32_t len) 
  {
    if (swapping)
      return FAIL;
    switch (active) {
      case 0:
        return call BlockWriteA.write(addr, buf, len);
      case 1:
        return call BlockWriteB.write(addr, buf, len);
    }
    return FAIL;
  }


  event void BlockWriteA.writeDone(storage_addr_t addr, void *buf, 
          storage_len_t len, error_t error)
  {
    uint32_t taddr, tlen;
    if (!swapping) {
      signal FlashStorage.writeDone(addr, buf, len, error);
      return;
    }
    if (call SlabSerializer.nextPosition(&taddr, &tlen) == FAIL) {
      active = 0;
      swapping = FALSE;
      call BlockWriteA.sync();
      return;
    }
    call BlockReadB.read(taddr, &buffer, tlen);
  }


  event void BlockWriteB.writeDone(storage_addr_t addr, void *buf, 
          storage_len_t len, error_t error)
  {
    uint32_t taddr, tlen;
    if (!swapping) {
      signal FlashStorage.writeDone(addr, buf, len, error);
      return;
    }
    if (call SlabSerializer.nextPosition(&taddr, &tlen) == FAIL) {
      active = 1;
      swapping = FALSE;
      call BlockWriteB.sync();
      return;
    }
    call BlockReadA.read(taddr, &buffer, tlen);
  }


  command error_t FlashStorage.read(uint32_t addr, void *buf, uint32_t len)
  {
    if (swapping)
      return FAIL;
    switch (active) {
      case 0:
        return call BlockReadA.read(addr, buf, len);
      case 1:
        return call BlockReadB.read(addr, buf, len);
    }
    return FAIL;
  }


  event void BlockReadA.readDone(storage_addr_t addr, void *buf,
          storage_len_t len, error_t error)
  {
    if (swapping) {
      call BlockWriteB.write(addr, buf, len);
      return;
    }
    signal FlashStorage.readDone(addr, buf, len, error);
  }


  event void BlockReadB.readDone(storage_addr_t addr, void *buf,
          storage_len_t len, error_t error)
  {
    if (swapping) {
      call BlockWriteA.write(addr, buf, len);
      return;
    }
    signal FlashStorage.readDone(addr, buf, len, error);
  }


  event void BlockWriteA.syncDone(error_t error) 
  {
  }


  event void BlockWriteB.syncDone(error_t error)
  {
  }


  event void BlockReadA.computeCrcDone(storage_addr_t addr, storage_len_t len,
          uint16_t crc, error_t error) { }
 

  event void BlockReadB.computeCrcDone(storage_addr_t addr, storage_len_t len,
          uint16_t crc, error_t error) { }


  event void BlockReadMeta.computeCrcDone(storage_addr_t addr,
          storage_len_t len, uint16_t crc, error_t error) { }


  command error_t FlashStorage.loadMeta(void *buf, uint32_t len)
  {
    op_active = TRUE;
    meta = buf;
    meta_len = len;
    return call BlockReadMeta.read(0, &active, sizeof(active));
  }


  event void BlockReadMeta.readDone(storage_addr_t addr, void *buf,
          storage_len_t len, error_t error)
  {
    if (op_active) {
      op_active = FALSE;
      call BlockReadMeta.read(sizeof(active), meta, meta_len);
      return;
    }
    signal FlashStorage.loadMetaDone(buf, len, error);
  }


  command error_t FlashStorage.saveMeta(void *buf, uint32_t len)
  {
    op_active = TRUE;
    meta = buf;
    meta_len = len;
    return call BlockWriteMeta.erase();
  }


  event void BlockWriteMeta.writeDone(storage_addr_t addr, void *buf, 
          storage_len_t len, error_t error)
  {
    if (op_active) {
      op_active = FALSE;
      call BlockWriteMeta.write(sizeof(active), meta, meta_len);
      return;
    }
    call BlockWriteMeta.sync();
  }


  event void BlockWriteMeta.syncDone(error_t error)
  {
    signal FlashStorage.saveMetaDone(error);
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
