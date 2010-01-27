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
 * *	$Id: TuningTest.nc 856 2009-06-03 13:23:36Z sguna $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "TupleSpace.h"

#define TIMER 1000

module TuningTest {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface Tuning;

    interface AMPacket;

    interface Random;

    interface TeenyLIMEExceptions;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  NeighborTuple<uint16_t> neighborTuple;

  event void Boot.booted() {
    
    neighborTuple = newTuple(actualField(call AMPacket.address()));
    call TimerApp.startOneShot(TIMER);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TimerApp.fired() {

    if (call Tuning.get(KEY_RADIO_CONTROL) == RADIO_ON) {
      call Leds.led2Off();
      call Tuning.set(KEY_RADIO_CONTROL,RADIO_OFF);
    } else {
      call Leds.led2On();
      call Tuning.set(KEY_RADIO_CONTROL,RADIO_ON);    
    }
  }

  event void Tuning.setDone(uint8_t key, uint16_t value){
    call Leds.led1Toggle();
    call TimerApp.startOneShot(TIMER);    
  }

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) { 
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return (tuple *) &neighborTuple;
  }

  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,  
				   tuple* returningTuple) {
  }


  event void TeenyLIMEExceptions.exception(uint8_t exceptionCode, void* data) {
    
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 
}

