/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1025 $
 * * DATE
 * *    $LastChangedDate: 2010-01-15 09:31:19 -0600 (Fri, 15 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: VibrationSamplerFlash.nc 1025 2010-01-15 15:31:19Z mceriotti $
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

configuration VibrationSamplerFlash {

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
  components VibrSenseTaskFlash;
  components new DirectStorageC(VOLUME_ACCELLOG);
  components new AlarmMilli16C() as SensePeriod;
  components new Alarm32khz16C() as SenseSample;
  components new TimerMilliC() as Report;
  components new TimerMilliC() as BatteryMonitor;
  components new /* AlarmMilli16C */TimerMilliC() as FlashReadDelayTimer;

  components Stm25pVolumeSettingsP;

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

  Boot = VibrSenseTaskFlash.Boot;
  TS = VibrSenseTaskFlash.TS;
  GlobalTime = VibrSenseTaskFlash.GlobalTime;
  Tuning = VibrSenseTaskFlash.Tuning;

#ifdef PRINTF_SUPPORT
  PrintfControl = VibrSenseTaskFlash.PrintfControl;
  PrintfFlush = VibrSenseTaskFlash.PrintfFlush;
#endif

  VibrSenseTaskFlash.CollectionInfo -> DataForwarderC;
  VibrSenseTaskFlash.VReport -> Report;
  VibrSenseTaskFlash.FlashReadDelay -> FlashReadDelayTimer;
  VibrSenseTaskFlash.DirectStorage -> DirectStorageC;
  VibrSenseTaskFlash.VolumeSettings -> DirectStorageC.DirectStorageSettings;
  VibrSenseTaskFlash.Leds -> LedsC;
  VibrSenseTaskFlash.Compression -> CompressionEngine;

  // Forbattery monitoring
  VibrSenseTaskFlash.BatteryReadADC -> Adc;
  VibrSenseTaskFlash.BatteryMonitor -> BatteryMonitor;  

  // For acceleration sensing
  VibrSenseTaskFlash.VSensePeriod -> SensePeriod;
  VibrSenseTaskFlash.VSenseSample -> SenseSample;
  VibrSenseTaskFlash.ResourceAccelRead -> Adc;
  VibrSenseTaskFlash.AccelRead -> Adc;
  VibrSenseTaskFlash.AdcAccelConf <- Adc;

  CompressionEngine.Leds -> LedsC;
}

