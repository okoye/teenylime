/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SensorNode.nc 883 2009-07-14 12:51:17Z mceriotti $
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
 * Configuration for a sensor node.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration SensorNode {}

implementation {

  components MainC, TeenyLimeC;

  components LedsC;
/*   components NoLedsC as LedsC; */

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif
  components SystemMonitorC as SystemMonitor;
  components COSampler, CO2Sampler, DustSampler;
  components DataCollection;

  components TimeSyncC;

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

  // Sampler wirings
  COSampler.Boot -> MainC.Boot;
  COSampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  COSampler.CollectionInfo -> DataCollection;
  COSampler.GlobalTime -> TimeSyncC;
#ifdef PRINTF_SUPPORT
  COSampler.PrintfControl -> PrintfC;
  COSampler.PrintfFlush -> PrintfC;
#endif

  // Sampler wirings
  CO2Sampler.Boot -> MainC.Boot;
  CO2Sampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  CO2Sampler.CollectionInfo -> DataCollection;
  CO2Sampler.GlobalTime -> TimeSyncC;
#ifdef PRINTF_SUPPORT
  CO2Sampler.PrintfControl -> PrintfC;
  CO2Sampler.PrintfFlush -> PrintfC;
#endif

  // Sampler wirings
  DustSampler.Boot -> MainC.Boot;
  DustSampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DustSampler.CollectionInfo -> DataCollection;
  DustSampler.GlobalTime -> TimeSyncC;
#ifdef PRINTF_SUPPORT
  DustSampler.PrintfControl -> PrintfC;
  DustSampler.PrintfFlush -> PrintfC;
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
