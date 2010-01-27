/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1016 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:29:08 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: LTSampler.nc 1016 2010-01-11 08:29:08Z mceriotti $
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
 * A configuration to perform sensing of light and temperature values.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration LTSampler {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface Tuning as TLTuning;
    
    interface SystemMonitorCtrl;

    interface GlobalTime;
    
    interface CollectionTuning;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides interface StdControl as SamplingControl;
}

implementation {

  components NoLedsC as LedsC;
  components LTSenseTask;

  components new TimerMilliC() as SenseTimer;
#ifndef FAKE_LIGHT
  components ISL29004;
#endif
  components RandomC;


  LTSenseTask.Random -> RandomC;
  Boot = LTSenseTask.Boot;
  SamplingControl = LTSenseTask.SamplingControl;
  TS = LTSenseTask.TS;
  GlobalTime = LTSenseTask.GlobalTime;
  CollectionTuning = LTSenseTask;
  TLTuning = LTSenseTask;
  SystemMonitorCtrl = LTSenseTask.SystemMonitorCtrl;

#ifdef PRINTF_SUPPORT
  PrintfControl = LTSenseTask.PrintfControl;
  PrintfFlush = LTSenseTask.PrintfFlush;
#endif

#ifndef FAKE_LIGHT
  LTSenseTask.ISL29004Read -> ISL29004;
  LTSenseTask.ISL29004Control -> ISL29004;
#endif

  LTSenseTask.TSensePeriod -> SenseTimer;
  LTSenseTask.Leds -> LedsC;
}

