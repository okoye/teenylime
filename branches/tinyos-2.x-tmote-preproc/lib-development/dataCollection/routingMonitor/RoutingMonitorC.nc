/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 823 $
 * * DATE
 * *    $LastChangedDate: 2009-05-07 05:01:29 -0500 (Thu, 07 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: RoutingMonitorC.nc 823 2009-05-07 10:01:29Z mceriotti $
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
 * A configuration to monitor routing.
 * 
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration RoutingMonitorC {

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

  components NoLedsC as LedsC;
  components RoutingMonitorM;
  components DataCollection;

#ifndef MICAZ_TOSSIM
  components new VoltageC() as Sensor;
#endif
#ifdef MICAZ_TOSSIM
  components new DemoSensorC() as Sensor;
#endif

  components new TimerMilliC() as MonitorTimer;

  Boot = RoutingMonitorM.Boot;
  TS = RoutingMonitorM.TS;
  AMPacket = RoutingMonitorM.AMPacket;

#ifdef PRINTF_SUPPORT
  PrintfControl = RoutingMonitorM.PrintfControl;
  PrintfFlush = RoutingMonitorM.PrintfFlush;
#endif

#ifndef MICAZ_TOSSIM
  RoutingMonitorM.ReadVoltage -> Sensor;  
#endif
#ifdef MICAZ_TOSSIM
  RoutingMonitorM.ReadVoltage -> Sensor;  
#endif
  RoutingMonitorM.CollectionInfo -> DataCollection;
  RoutingMonitorM.CollectionDebug -> DataCollection;
  RoutingMonitorM.MonitorPeriod -> MonitorTimer;
  RoutingMonitorM.Leds -> LedsC;
}

