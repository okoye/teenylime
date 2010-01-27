/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 320 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:38:54 -0500 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: VibrationSampler.nc 320 2008-03-13 11:38:54Z ben_christian $
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
#include "StorageVolumes.h"

/**
 * A configuration to perform sensing tasks for vibration measures.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration VibrationSampler {

  uses {

    interface Boot;

    interface TupleSpace as TS;

    interface AMPacket;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  components LedsC;
  components VibrSenseTask;
  components new BlockStorageC(VOLUME_LOGTEST);
  components new AlarmMilli16C() as SensePeriod;
  components new AlarmMilli16C() as SenseSample;
  components new TimerMilliC() as Report;

  Boot = VibrSenseTask.Boot;
  TS = VibrSenseTask.TS;
  AMPacket = VibrSenseTask.AMPacket;

#ifdef PRINTF_SUPPORT
  PrintfControl = VibrSenseTask.PrintfControl;
  PrintfFlush = VibrSenseTask.PrintfFlush;
#endif

  VibrSenseTask.VSensePeriod -> SensePeriod;
  VibrSenseTask.VSenseSample -> SenseSample;
  VibrSenseTask.VReport -> Report;
  VibrSenseTask.BlockWrite -> BlockStorageC;
  VibrSenseTask.BlockRead -> BlockStorageC;
  VibrSenseTask.Leds -> LedsC;
}

