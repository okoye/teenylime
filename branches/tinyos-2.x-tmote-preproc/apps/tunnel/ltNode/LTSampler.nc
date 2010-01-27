/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:08:41 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: LTSampler.nc 885 2009-07-15 16:08:41Z mceriotti $
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

    interface GlobalTime;
    
    interface CollectionInfo;
    interface CollectionTuning;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides interface StdControl as SamplingControl;
}

implementation {

  components LedsC;
  components LTSenseTask;

  components new TimerMilliC() as SenseTimer;
  components ISL29004;

  Boot = LTSenseTask.Boot;
  SamplingControl = LTSenseTask.SamplingControl;
  TS = LTSenseTask.TS;
  GlobalTime = LTSenseTask.GlobalTime;
  CollectionInfo = LTSenseTask;
  CollectionTuning = LTSenseTask;
  TLTuning = LTSenseTask;

#ifdef PRINTF_SUPPORT
  PrintfControl = LTSenseTask.PrintfControl;
  PrintfFlush = LTSenseTask.PrintfFlush;
#endif

  LTSenseTask.ISL29004Read -> ISL29004;
  LTSenseTask.ISL29004Control -> ISL29004;

  LTSenseTask.TSensePeriod -> SenseTimer;
  LTSenseTask.Leds -> LedsC;
}

