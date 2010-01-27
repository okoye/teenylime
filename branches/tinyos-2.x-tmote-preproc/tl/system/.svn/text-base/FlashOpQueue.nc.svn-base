/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 843 $
 * * DATE
 * *    $LastChangedDate: 2009-05-18 10:46:04 +0200 (Mon, 18 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: FlashOpQueue.nc 843 2009-05-18 08:46:04Z sguna $
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

#include "tl_objs.h"
#include "TupleSpace.h"
#include "TLDebug.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif


module FlashOpQueue {
  uses {
    interface TLObjects;
    interface TLDebug;
    interface RunOp;
    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
  provides {
    interface FlashOperations;
  }
}

implementation {
  struct queue_entry {
    uint8_t operation;
    TLOpId_t operationId;
    char tuple_buffer[MAX_TUPLE_SIZE];
  };

  struct queue_entry queue[PERSIST_QUEUE_SIZE];
  int queue_size = 0;
  bool busy = FALSE;


  void run_next()
  {
    if (queue_size <= 0) {
      busy = FALSE;
      return;
    }
    busy = TRUE;

    call RunOp.runOperation(queue[0].operation, queue[0].operationId,
            (tuple *) queue[0].tuple_buffer);
  }


  void push_queue(uint8_t operation, TLOpId_t operationId, tuple *t)
  {
    if (queue_size >= PERSIST_QUEUE_SIZE) {
      call TLDebug.triggerErr(OP_QUEUE_OVERFLOW);
      return;
    }
    queue[queue_size].operation = operation;
    if (t != NULL) {
      queue[queue_size].operationId = operationId;
      call TLObjects.copy_tuple((tuple *) queue[queue_size].tuple_buffer, t);
    }
    queue_size++;
  }


  command void FlashOperations.scheduleOperation(uint8_t operation, 
          TLOpId_t operationId, tuple *t)
  {
    push_queue(operation, operationId, t);
    if (!busy)
      run_next();
  }


  command void FlashOperations.operationCompleted()
  {
    int i;
    for (i = 0; i < queue_size - 1; i++)
      memcpy(queue + i, queue + i + 1, sizeof(struct queue_entry));
    if (queue_size > 0)
      queue_size--;
    run_next();
  }


  command void FlashOperations.lock()
  {
    busy = TRUE;
  }


#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) 
  {
  }

  event void PrintfControl.stopDone(error_t error) 
  {
  }

  event void PrintfFlush.flushDone(error_t error) 
  {
  }
#endif
  
}
