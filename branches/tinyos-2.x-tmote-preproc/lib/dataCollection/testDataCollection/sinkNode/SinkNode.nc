/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 836 $
 * * DATE
 * *    $LastChangedDate: 2009-05-08 00:50:31 -0500 (Fri, 08 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SinkNode.nc 836 2009-05-08 05:50:31Z mceriotti $
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

#include "Constants.h"
#include "TupleSpace.h"
#include "TupleSerialMsg.h"

/** 
 * Configuration for the bridge between the sink node and the pc.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration SinkNode {}

implementation {

  components MainC, TeenyLimeC;
  components LedsC;
  components NoLedsC as led;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

#ifdef WATCHDOG
  components WatchdogC;
#endif

  components DataCollection;
  components DataDissemination;
  components Tuner;
  components TupleGateway;
  components ActiveMessageC as AM;
  components TLObjectsParsed;
  components new TimerMilliC() as TimerWD;
  components new TimerMilliC() as TimerWS;
  components new TimerMilliC() as TimerTuning;
  components SerialActiveMessageC as SerialAM;
  components RoutingMonitorC as RoutingMonitor;

  // System Monitor wirings
  RoutingMonitor.Boot -> MainC.Boot;
  RoutingMonitor.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  RoutingMonitor.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  RoutingMonitor.PrintfControl -> PrintfC;
  RoutingMonitor.PrintfFlush -> PrintfC;
#endif

  // Data Dissemination wirings
  DataDissemination.Boot -> MainC.Boot;
  DataDissemination.TeenyLIMESystem -> TeenyLimeC;
  DataDissemination.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataDissemination.AMPacket -> AM;
  DataDissemination.Leds -> LedsC;
  DataDissemination.TLObjects -> TLObjectsParsed;
#ifdef PRINTF_SUPPORT
  DataDissemination.PrintfControl -> PrintfC;
  DataDissemination.PrintfFlush -> PrintfC;
#endif

  // Data Collection wirings
  DataCollection.Boot -> MainC.Boot;
  DataCollection.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataCollection.TeenyLIMEExceptions -> TeenyLimeC;
  DataCollection.AMPacket -> AM;
  DataCollection.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  DataCollection.PrintfControl -> PrintfC;
  DataCollection.PrintfFlush -> PrintfC;
#endif

  // Tuner wirings
  Tuner.Boot -> MainC.Boot;
  Tuner.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  Tuner.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  Tuner.CollectionTuning -> DataCollection.CollectionTuning;
  Tuner.TimerSearchTask -> TimerTuning;
  Tuner.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  Tuner.PrintfControl -> PrintfC;
  Tuner.PrintfFlush -> PrintfC;
#endif

  // Tuple Gateway wirings
  TupleGateway.Boot -> MainC.Boot;
  TupleGateway.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TupleGateway.AMPacket -> AM;
  TupleGateway.Leds -> LedsC;
  TupleGateway.TLObjects -> TLObjectsParsed;
  TupleGateway.SerialControl -> SerialAM;
  TupleGateway.SerialSend -> SerialAM.AMSend[AM_TUPLE_SERIAL_MSG];
  TupleGateway.SerialReceive -> SerialAM.Receive[AM_TUPLE_SERIAL_MSG];
#ifdef PRINTF_SUPPORT
  TupleGateway.PrintfControl -> PrintfC;
  TupleGateway.PrintfFlush -> PrintfC;
#endif
}

