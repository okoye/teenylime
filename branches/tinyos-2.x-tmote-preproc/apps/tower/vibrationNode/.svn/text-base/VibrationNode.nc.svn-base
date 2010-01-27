/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 297 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 20:33:24 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: VibrationNode.nc 297 2008-02-26 18:33:24Z mceriotti $
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
 * Configuration for a vibration node in Torre Aquila project.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */
configuration VibrationNode {}

implementation {

  components MainC, TeenyLimeC;
  components LedsC;
/*   components NoLedsC as LedsC; */

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

#ifdef FRAM_CHIP
  components VibrationSamplerFRAM as VibrationSampler;
#endif
 
#ifdef FLASH
  components VibrationSamplerFlash as VibrationSampler;
#endif

  components TimeSyncC, DataDissemination, DataCollection;
/*   components FakeDataDisseminationVibr as DataDissemination; */

  components ActiveMessageC as AM;
  components TLObjectsParsed;

  // VibrationSampler wirings
  VibrationSampler.Boot -> MainC.Boot;
  VibrationSampler.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  VibrationSampler.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  VibrationSampler.GlobalTime -> TimeSyncC;
#ifdef PRINTF_SUPPORT
  VibrationSampler.PrintfControl -> PrintfC;
  VibrationSampler.PrintfFlush -> PrintfC;
#endif

// DataDissemination wirings
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
