/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 282 $
 * * DATE
 * *    $LastChangedDate: 2008-02-16 11:27:02 -0600 (Sat, 16 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: SystemMonitorM.nc 282 2008-02-16 17:27:02Z lmottola $
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
 * The component in charge of providing monitoring information on a
 * node's status .
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module SystemMonitorM {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface Read<uint16_t> as ReadVoltage;
    interface Timer<TMilli> as MonitorPeriod;

    interface CollectionInfo;

    interface AMPacket;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint8_t minuteTick = 0;

  event void Boot.booted() {

    call MonitorPeriod.startPeriodic(MINUTE);

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }
  
  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
    
  }

  event void MonitorPeriod.fired() {

    minuteTick++;
    if (minuteTick % MONITOR_PERIOD == 0) { 
      call ReadVoltage.read();
    }
  }

  event void ReadVoltage.readDone(error_t result, uint16_t val) {

    TLOpId_t outId;
    tuple tMonitor = newTuple(6,
			      actualField_uint8(NODE_INFO_TYPE),
			      actualField_uint16(call AMPacket.address()),
			      actualField_uint16(call CollectionInfo.currentParent()),
			      actualField_uint16(call CollectionInfo.parentCost()),
			      actualField_uint16(call CollectionInfo.forwardedTuples()),
			      actualField_uint16(val));
    call TS.out(&outId, FALSE, TL_LOCAL, &tMonitor);

#ifdef PRINTF_SUPPORT
    printf ("V %u\n", val);
    call PrintfFlush.flush();
#endif    
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

