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
 * *	$Id: SystemMonitorC.nc 313 2008-03-04 16:40:43Z lmottola $
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
 * A configuration to monitor a node's state.
 * 
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration SystemMonitorC {

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
  components SystemMonitorM;
  components DataCollection;

#ifndef MICAZ_TOSSIM
  components new VoltageC() as Sensor;
#endif
#ifdef MICAZ_TOSSIM
  components new DemoSensorC() as Sensor;
#endif

  components new TimerMilliC() as MonitorTimer;

  Boot = SystemMonitorM.Boot;
  TS = SystemMonitorM.TS;
  AMPacket = SystemMonitorM.AMPacket;

#ifdef PRINTF_SUPPORT
  PrintfControl = SystemMonitorM.PrintfControl;
  PrintfFlush = SystemMonitorM.PrintfFlush;
#endif

#ifndef MICAZ_TOSSIM
  SystemMonitorM.ReadVoltage -> Sensor;  
#endif
#ifdef MICAZ_TOSSIM
  SystemMonitorM.ReadVoltage -> Sensor;  
#endif
  SystemMonitorM.CollectionInfo -> DataCollection;
  SystemMonitorM.MonitorPeriod -> MonitorTimer;
  SystemMonitorM.Leds -> LedsC;
}

