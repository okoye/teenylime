/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 235 $
 * * DATE
 * *    $LastChangedDate: 2007-12-06 23:10:28 +0100 (gio, 06 dic 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: FakeTimeSynch.nc 235 2007-12-06 22:10:28Z mceriotti $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#include "Constants.h"
#include "TupleSpace.h"

/**
 * A component to achieve coarse-grained time synch.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */


#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

module DataTimeSynch {

  uses {
    interface Boot;
    interface TupleSpace as TS;
	
    interface AMPacket;

    interface Leds;
 	interface GlobalTime;
 	#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  TLOpId_t inId;
  uint16_t round = 0;

  event void Boot.booted() {
    call GlobalTime.startTimer();
    #ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
    TLOpId_t outId;
    tuple roundTuple;

    atomic{
	    round++;
	    roundTuple = newTuple(2, 
				  actualField_uint8(ROUND_TYPE), 
				  actualField_uint16(round));
#ifdef PRINTF_SUPPORT
      //printf ("OUT %u - %u\n", round, ROUND_TYPE);
      //call PrintfFlush.flush();
#endif   
	    call TS.out(&outId, FALSE, TL_LOCAL, &roundTuple); 
  	}
  }

  event void TS.reifyCapabilityTuple(tuple* ct) { }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
  }
  
  event void GlobalTime.synced(){
  	call Leds.led1On();
  }
    
  event void GlobalTime.lostSynced(){
  call Leds.led0Off();
  }

  event void GlobalTime.timeEvent(){
  	atomic {
	    tuple prevRoundTuple = newTuple(2, 
					    actualField_uint8(ROUND_TYPE), 
					    actualField_uint16(round));
		
	    call TS.in(&inId, FALSE, TL_LOCAL, &prevRoundTuple);
    }
    call Leds.led0Toggle();
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

