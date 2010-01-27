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
 * *	$Id: TemperatureNode.nc 320 2008-03-13 11:38:54Z ben_christian $
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
 * Configuration for a temperature node in Torre Aquila project.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

configuration TemperatureNode {}

implementation {

  components MainC, TeenyLimeC;
  components LedsC as led;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif
  
  components SystemMonitorC;
  components TempSampler, DataCollection;
  components DataTimeSynch as TimeSynch;
  components TimeSyncC;
/*   components FakeDataDisseminationTemp as DataDissemination; */
  components DataDissemination;

  components ActiveMessageC as AM;

  // TimeSynch wirings
  TimeSynch.Boot -> MainC.Boot;
  TimeSynch.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TimeSynch.AMPacket -> AM;
  TimeSynch.GlobalTime -> TimeSyncC;
  TimeSynch.Leds -> led;
#ifdef PRINTF_SUPPORT
  TimeSynch.PrintfControl -> PrintfC;
  TimeSynch.PrintfFlush -> PrintfC;
#endif

  // System Monitor wirings
  SystemMonitorC.Boot -> MainC.Boot;
  SystemMonitorC.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  SystemMonitorC.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  SystemMonitorC.PrintfControl -> PrintfC;
  SystemMonitorC.PrintfFlush -> PrintfC;
#endif

  // TempSampler wirings
  TempSampler.Boot -> MainC.Boot;
  TempSampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TempSampler.AMPacket -> AM;
#ifdef PRINTF_SUPPORT
  TempSampler.PrintfControl -> PrintfC;
  TempSampler.PrintfFlush -> PrintfC;
#endif

  // DataDisseimnation wirings
  DataDissemination.Boot -> MainC.Boot;
  DataDissemination.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataDissemination.TeenyLIMESystem -> TeenyLimeC;
  DataDissemination.AMPacket -> AM;
  DataDissemination.Leds -> led;
#ifdef PRINTF_SUPPORT
  DataDissemination.PrintfControl -> PrintfC;
  DataDissemination.PrintfFlush -> PrintfC;
#endif

  // DataCollection wirings
  DataCollection.Boot -> MainC.Boot;
  DataCollection.AMPacket -> AM;
  DataCollection.TS -> TeenyLimeC.TupleSpace[unique("TL")];
#ifdef PRINTF_SUPPORT
  DataCollection.PrintfControl -> PrintfC;
  DataCollection.PrintfFlush -> PrintfC;
#endif
}
