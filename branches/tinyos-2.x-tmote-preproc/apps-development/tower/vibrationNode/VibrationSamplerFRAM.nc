/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 313 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 18:40:43 +0200 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: VibrationSampler.nc 313 2008-03-04 16:40:43Z lmottola $
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
#include "Fm25lc.h"

/**
 * A configuration to perform sensing tasks for vibration measures.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration VibrationSamplerFRAM {

  uses {

    interface Boot;

    interface TupleSpace as TS;
    interface Tuning;

    interface GlobalTime;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  components LedsC;
  components VibrSenseTaskFRAM;
  components new AlarmMilli16C() as SensePeriod;
  components new Alarm32khz16C() as SenseSample;
  components new TimerMilliC() as Report;
  components new TimerMilliC() as BatteryMonitor;
/*   components new TimerMilliC() as FlashReadDelayTimer; */
  components new AlarmMilli16C() as FlashReadDelayTimer;

  components Fm25lcSpiC as FRAM;

  components DataForwarderC;

#ifdef FAKE_ACCEL
  components new FakeAccel() as Adc;
#else 
  components new Msp430Adc12ClientAutoRVGC() as Adc;
#endif

#ifdef HUFFMAN_COMPRESSION
  components HuffmanCompression as CompressionEngine;
#else
  components NoCompression as CompressionEngine;
#endif

  Boot = VibrSenseTaskFRAM.Boot;
  TS = VibrSenseTaskFRAM.TS;
  GlobalTime = VibrSenseTaskFRAM.GlobalTime;
  Tuning = VibrSenseTaskFRAM.Tuning;

#ifdef PRINTF_SUPPORT
  PrintfControl = VibrSenseTaskFRAM.PrintfControl;
  PrintfFlush = VibrSenseTaskFRAM.PrintfFlush;
#endif

  VibrSenseTaskFRAM.CollectionInfo -> DataForwarderC;
  VibrSenseTaskFRAM.VReport -> Report;
  VibrSenseTaskFRAM.FRAMResource -> FRAM;
  VibrSenseTaskFRAM.FRAM -> FRAM;
  VibrSenseTaskFRAM.FlashReadDelay -> FlashReadDelayTimer;
  VibrSenseTaskFRAM.Leds -> LedsC;
  VibrSenseTaskFRAM.Compression -> CompressionEngine;
#ifdef ROUTING_MONITOR
  VibrSenseTaskFRAM.CollectionDebug -> DataForwarderC;
#endif
  // Forbattery monitoring
  VibrSenseTaskFRAM.BatteryReadADC -> Adc;
  VibrSenseTaskFRAM.BatteryMonitor -> BatteryMonitor;  

  // For acceleration sensing
  VibrSenseTaskFRAM.VSensePeriod -> SensePeriod;
  VibrSenseTaskFRAM.VSenseSample -> SenseSample;
  VibrSenseTaskFRAM.ResourceAccelRead -> Adc;
  VibrSenseTaskFRAM.AccelRead -> Adc;
  VibrSenseTaskFRAM.AdcAccelConf <- Adc;

  CompressionEngine.Leds -> LedsC;
}

