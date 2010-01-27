/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 289 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 04:42:42 -0600 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TupleExpiration.nc 289 2008-02-19 10:42:42Z lmottola $
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

#include "TLConf.h"

/**
 * Test for tuple expiration timers.
 *
 * Under correct execution, the blue leds will start blinking after
 * MAX_TUPLES*EPOCH time instants.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module TupleExpiration {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerApp;

    interface TupleSpace as TS;
    interface TeenyLIMESystem;

    interface AMPacket;

    interface Random;

    interface Leds;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple neighborTuple;
  TLOpId_t outId, rdId;

  event void Boot.booted() {
    
    uint8_t i;
    tuple t = newTuple(2, 
		     actualField_char('a'), 
		     actualField_char('b'));

    neighborTuple = newTuple(1, actualField_uint16(call AMPacket.address()));
 
    for (i=0; i<MAX_TUPLES-1; i++) {
      setExpireIn(&t, i+1);
      call TS.out(&outId, FALSE, TL_LOCAL, &t);
    }

    call TimerApp.startPeriodic(EPOCH);
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();    
#endif
  }

  event void TimerApp.fired() {
    
    tuple p = newTuple(2, 
		       formalField(TYPE_CHAR), 
		       formalField(TYPE_CHAR));

    call TS.rdg(&rdId, FALSE, TL_LOCAL, &p); 
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {
    
#ifdef PRINTF_SUPPORT
    printf("Returned %d\n",number);
    call PrintfFlush.flush();
#endif

    if (number == 0) {
      call Leds.led2Toggle();
    }
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
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

