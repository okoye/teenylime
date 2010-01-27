/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 302 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 22:28:05 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TemperatureNode.nc 302 2008-02-26 20:28:05Z mceriotti $
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


/** 
 * Configuration for a temperature, humidity, and light node in 
 * Torre Aquila project.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration THLNode {}

implementation {

  components MainC, TeenyLimeC;

  components LedsC;
/*   components NoLedsC as LedsC; */

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

#ifdef ROUTING_MONITOR
  components RoutingMonitorC as SystemMonitor;
#else
  components SystemMonitorC as SystemMonitor;
#endif
  components THLSampler, DataCollection;

  components TimeSyncC;

/*   components FakeDataDisseminationTemp as DataDissemination; */
  components DataDissemination;

  components ActiveMessageC as AM;
  components TLObjectsParsed;

  // System Monitor wirings
  SystemMonitor.Boot -> MainC.Boot;
  SystemMonitor.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  SystemMonitor.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  SystemMonitor.PrintfControl -> PrintfC;
  SystemMonitor.PrintfFlush -> PrintfC;
#endif

  // THLSampler wirings
  THLSampler.Boot -> MainC.Boot;
  THLSampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  THLSampler.CollectionInfo -> DataCollection;
  THLSampler.GlobalTime -> TimeSyncC;
#ifdef PRINTF_SUPPORT
  THLSampler.PrintfControl -> PrintfC;
  THLSampler.PrintfFlush -> PrintfC;
#endif

  // DataDisseimnation wirings
  DataDissemination.Boot -> MainC.Boot;
  DataDissemination.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataDissemination.TeenyLIMESystem -> TeenyLimeC;
  DataDissemination.AMPacket -> AM;
  DataDissemination.Leds -> LedsC;
  DataDissemination.TLObjects -> TLObjectsParsed;
#ifdef PRINTF_SUPPORT
  DataDissemination.PrintfControl -> PrintfC;
  DataDissemination.PrintfFlush -> PrintfC;
#endif

  // DataCollection wirings
  DataCollection.Boot -> MainC.Boot;
  DataCollection.AMPacket -> AM;
  DataCollection.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataCollection.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  DataCollection.TeenyLIMEExceptions -> TeenyLimeC;
  DataCollection.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  DataCollection.PrintfControl -> PrintfC;
  DataCollection.PrintfFlush -> PrintfC;
#endif
}
