/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1012 $
 * * DATE
 * *    $LastChangedDate: 2010-01-08 03:09:17 -0600 (Fri, 08 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TLSampler.nc 1012 2010-01-08 09:09:17Z mceriotti $
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
 * A configuration to perform sensing for temperature and
 * light.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration TLSampler {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface CollectionInfo;

    interface GlobalTime;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  components LedsC;
  components TLSenseTask;

  components new AdcReadClientC() as TemperatureADC;

#ifndef FAKE_LIGHT
  components new AdcReadClientC() as LightADC;
#endif
  components new TimerMilliC() as SenseTimer;

  Boot = TLSenseTask.Boot;
  TS = TLSenseTask.TS;
  GlobalTime = TLSenseTask.GlobalTime;
  CollectionInfo = TLSenseTask;

#ifdef PRINTF_SUPPORT
  PrintfControl = TLSenseTask.PrintfControl;
  PrintfFlush = TLSenseTask.PrintfFlush;
#endif

  TLSenseTask.ReadTemperature -> TemperatureADC;  
#ifndef FAKE_LIGHT
  TLSenseTask.ReadLight -> LightADC;
#endif
  TLSenseTask.TSensePeriod -> SenseTimer;
  TLSenseTask.Leds -> LedsC;

  TLSenseTask.AdcConfTemp <- TemperatureADC;
#ifndef FAKE_LIGHT
  TLSenseTask.AdcConfLight <- LightADC;
#endif
}

