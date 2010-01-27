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
 * *	$Id: TLDebugM.nc 856 2009-06-03 13:23:36Z sguna $
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

#include "TLDebug.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * A component to provide debugging information.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

module TLDebugM {

  provides {
    interface TLDebug;
  }

  uses {
    interface Timer<TMilli> as BlinkTimer;
    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  uint8_t errorCode = 0;

  void signalError() {

    static bool on = TRUE;

    if (on) {
      call Leds.set(errorCode);
      on = FALSE;
    } else {
      call Leds.set(0);
      on = TRUE;
    }    
  }

  command void TLDebug.triggerErr(uint8_t code) {
    
    errorCode = code;
    signalError();
    call BlinkTimer.startPeriodic(BLINK_TIMER);
  }

  command void TLDebug.ledToggle(uint8_t code) {

    if (code == 0) {
      call Leds.led0Toggle();
    } else if (code == 1) {
      call Leds.led1Toggle();
    } else {
      call Leds.led2Toggle();    
    }
  }

  event void BlinkTimer.fired() {
    signalError();
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
