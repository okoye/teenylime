/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 955 $
 * * DATE
 * *    $LastChangedDate: 2009-11-28 16:07:05 -0600 (Sat, 28 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TrafficNode.nc 955 2009-11-28 22:07:05Z mceriotti $
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
 * Configuration for traffic generator node.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration TrafficNode {}

implementation {

  components MainC, TeenyLimeC;
  components LedsC;
  components NoLedsC;
#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

#ifdef WATCHDOG
  components WatchdogC;
#endif

  components RoutingMonitorC as RoutingMonitor;
  components Tuner, Killer;
  components TrafficGenerator, DataCollection;
/*   components FakeDataDissemination as DataDissemination; */
  components DataDissemination;
  components ActiveMessageC as AM;
  components TLObjectsParsed;

  components new TimerMilliC() as TimerTuning;
  components new TimerMilliC() as TimerKillerTask;
  components new TimerMilliC() as TimerKillerReb;

  // Routing Monitor wirings
  RoutingMonitor.Boot -> MainC.Boot;
  RoutingMonitor.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  RoutingMonitor.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  RoutingMonitor.PrintfControl -> PrintfC;
  RoutingMonitor.PrintfFlush -> PrintfC;
#endif

  // Traffic Generator wirings
  TrafficGenerator.Boot -> MainC.Boot;
  TrafficGenerator.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TrafficGenerator.CollectionInfo -> DataCollection;
  TrafficGenerator.Leds -> NoLedsC;
#ifdef PRINTF_SUPPORT
  TrafficGenerator.PrintfControl -> PrintfC;
  TrafficGenerator.PrintfFlush -> PrintfC;
#endif

  // Tuner wirings
  Tuner.Boot -> MainC.Boot;
  Tuner.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  Tuner.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  Tuner.CollectionTuning -> DataCollection.CollectionTuning;
  Tuner.TimerSearchTask -> TimerTuning;
  Tuner.Leds -> NoLedsC;
#ifdef PRINTF_SUPPORT
  Tuner.PrintfControl -> PrintfC;
  Tuner.PrintfFlush -> PrintfC;
#endif

  // Killer wirings */
  Killer.Boot -> MainC.Boot;
  Killer.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  Killer.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  Killer.TimerSearchTask -> TimerKillerTask;
  Killer.TimerKR -> TimerKillerReb;  
  Killer.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  Killer.PrintfControl -> PrintfC;
  Killer.PrintfFlush -> PrintfC;
#endif


  // Data Dissemination wirings
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

  // Data Collection wirings
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
