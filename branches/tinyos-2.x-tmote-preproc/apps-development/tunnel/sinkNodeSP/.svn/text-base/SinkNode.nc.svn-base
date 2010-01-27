/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 18:08:41 +0200 (mer, 15 lug 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SinkNode.nc 885 2009-07-15 16:08:41Z mceriotti $
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

  components DataCollection;
/*     components FakeDataDissemination as DataDissemination; */
  components DataDissemination;
  components TupleGateway;
  components ActiveMessageC as AM;
  components TLObjectsParsed;
  
  components new TimerMilliC() as TimerW;
#ifdef SERIAL_CONTROL
  components new TimerMilliC() as TimerControlSerial;
#endif
  components TimeSyncC;
  
  components SerialActiveMessageC as SerialAM;

  components SystemMonitorC as SystemMonitor;
  // System Monitor wirings
  SystemMonitor.Boot -> MainC.Boot;
  SystemMonitor.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  SystemMonitor.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  SystemMonitor.GlobalTime -> TimeSyncC;
  SystemMonitor.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  SystemMonitor.PrintfControl -> PrintfC;
  SystemMonitor.PrintfFlush -> PrintfC;
#endif

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

  DataCollection.Boot -> MainC.Boot;
  DataCollection.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataCollection.TeenyLIMEExceptions -> TeenyLimeC;
  DataCollection.AMPacket -> AM;
  DataCollection.Leds -> LedsC;

#ifdef PRINTF_SUPPORT
  DataCollection.PrintfControl -> PrintfC;
  DataCollection.PrintfFlush -> PrintfC;
#endif

  TupleGateway.Boot -> MainC.Boot;
  TupleGateway.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TupleGateway.AMPacket -> AM;
  TupleGateway.Leds -> LedsC;
  TupleGateway.TLObjects -> TLObjectsParsed;
  TupleGateway.GlobalTime -> TimeSyncC;

  TupleGateway.SerialControl -> SerialAM;
  TupleGateway.SerialSend -> SerialAM.AMSend[AM_TUPLE_SERIAL_MSG];
  TupleGateway.SerialReceive -> SerialAM.Receive[AM_TUPLE_SERIAL_MSG];
#ifdef SERIAL_CONTROL
  TupleGateway.TimerControlSerial -> TimerControlSerial;
#endif

#ifdef PRINTF_SUPPORT
  TupleGateway.PrintfControl -> PrintfC;
  TupleGateway.PrintfFlush -> PrintfC;
#endif
}

