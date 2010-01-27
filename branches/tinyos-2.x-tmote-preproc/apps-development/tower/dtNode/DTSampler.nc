/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 905 $
 * * DATE
 * *    $LastChangedDate: 2009-10-10 04:01:47 -0500 (Sat, 10 Oct 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: dfacchin $
 * *
 * *	$Id: DTSampler.nc 905 2009-10-10 09:01:47Z dfacchin $
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
#include "msp430usart.h"

/**
 * A configuration to perform sensing of deformation measures using a
 * fiber optic sensor attached via serial.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration DTSampler {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface GlobalTime;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  components LedsC;
  components DTSenseTask;

  components new TimerMilliC() as SenseTimer;
  components new AlarmMilli16C() as UartTimeout;
  components new Msp430Uart1C();
  components new AdcReadClientC() as TemperatureADC;

  Boot = DTSenseTask.Boot;
  TS = DTSenseTask.TS;
  GlobalTime = DTSenseTask.GlobalTime;


#ifdef PRINTF_SUPPORT
  PrintfControl = DTSenseTask.PrintfControl;
  PrintfFlush = DTSenseTask.PrintfFlush;
#endif

  DTSenseTask.UartResource -> Msp430Uart1C.Resource;
  DTSenseTask.UartStream -> Msp430Uart1C.UartStream;
  DTSenseTask.UartTimeout -> UartTimeout;

  DTSenseTask.ReadTemperature -> TemperatureADC;
  DTSenseTask.AdcConfTemp <- TemperatureADC;

  DTSenseTask.TSensePeriod -> SenseTimer;
  DTSenseTask.Leds -> LedsC;
}

