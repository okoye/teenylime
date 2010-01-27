/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 847 $
 * * DATE
 * *    $LastChangedDate: 2009-05-21 02:46:03 -0500 (Thu, 21 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: dfacchin $
 * *
 * *	$Id: FakeTimeSyncP.nc 847 2009-05-21 07:46:03Z dfacchin $
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

#include "TimeSynchConf.h"

#warning "*** USING FAKE TIME SYNCHRONIZATION ***"

module FakeTimeSyncP {

  provides interface GlobalTime;

  uses {
    interface Boot;
    interface Timer<TMilli> as EpochTimer;
    interface TupleSpace as TS;
    interface Leds;    
    interface Tuning;

#ifdef PRINTF_SUPPORTTS
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
} 

implementation {
  
  // Local time
  uint16_t localEpoch = 0;
  
  // Used to generate timeEvent 
  bool generateEvent;
	
  event void Boot.booted() {
    call EpochTimer.startOneShot(EPOCH_RATE);
  }

  event void TS.tupleReady(TLOpId_t operationId,
                           TupleIterator *iterator) {

  }
  
  event void TS.operationCompleted(uint8_t completionCode, 
                                   TLOpId_t operationId, 
                                   TLTarget_t target, 
				   TLTupleSpace_t ts,
                                   tuple* returningTuple){
  }  

  event void TS.reifyCapabilityTuple(tuple* ct){}
  
  event void EpochTimer.fired() {

    atomic {
      localEpoch++;		
      if (generateEvent == TRUE
	  && localEpoch % TIME_EVENT_MULTIPLIER == 0){
	signal GlobalTime.timeEvent();
      }
    }

    call EpochTimer.startOneShot(EPOCH_RATE);
  }

  event void Tuning.setDone(uint8_t key, uint16_t value) {
  
  }

  async command uint16_t GlobalTime.getLocalTime() {
    return localEpoch;
  }
  
  async command uint16_t GlobalTime.getGlobalTime() { 
    return localEpoch;
  }
  
  async command void GlobalTime.startTimer() {
    atomic generateEvent = TRUE;
  }
  
  async command void GlobalTime.stopTimer(){
    atomic generateEvent = FALSE;
  }
  
  async command void  GlobalTime.startSync() {
  }

#ifdef PRINTF_SUPPORTTS
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}
  
  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

