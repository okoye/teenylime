/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 12:42:42 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: LocalGroupOps.nc 289 2008-02-19 10:42:42Z lmottola $
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

#include "Constants.h"
#include "TupleSpace.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * Program a mote with id 11. Let the mote to run for FLASH_SYNC_TIME.
 * Reprogram the same mote with an id != 11. Normally, only the blue led
 * should be on. Let the mote run for FLASH_SYNC_TIME.
 * Reset the mote. Normally, only the yellow led should be on.
 *
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */


module FlashPersistence {

  uses {
    interface Boot;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface TLObjects;

    interface Random;
    
    interface AMPacket;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint8_t op = 0;
  tuple<uint16_t> neighborTuple;
  TLOpId_t outId, ingId;
  int number = 0;
  
  event void Boot.booted() {
    tuple<uint8_t, uint16_t> p = newTuple(dontCare(), dontCare()),
        t = newTuple( actualField(FAKE_DATA), actualField(FAKE_DATA));

    neighborTuple = newTuple(actualField(call AMPacket.address()));
    if (call AMPacket.address() == PEER_A_ID) {
      call TS.clear(FLASH_TS);
      call TS.out(&outId, FALSE, TL_LOCAL, FLASH_TS, (tuple *) &t);
    } else 
      call TS.ing(&ingId, FALSE, TL_LOCAL, FLASH_TS, (tuple *) &t);
    call Leds.set(6);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 

    tuple<uint8_t, uint16_t> *tmp;
    
    tmp = (tuple<uint8_t, uint16_t> *) call TS.getTuple(iterator);
    if (tmp != NULL && number == 0) {
      number++;
      if (tmp->value0 == FAKE_DATA && tmp->value1 == FAKE_DATA)
        call Leds.led1Toggle();
      call TS.nextSplitTuple(operationId, iterator);
      return;
    }
    if (tmp != NULL) {
      number++;
      call TS.nextSplitTuple(operationId, iterator);
      return;
    }
    if (number != 1)
      call Leds.led2Toggle();
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return (tuple *) &neighborTuple;
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,
                   TLTupleSpace_t ts,
				   tuple* returningTuple) {
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
