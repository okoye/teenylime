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
 * *	$Id: SinkNode.nc 320 2008-03-13 11:38:54Z ben_christian $
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
#ifndef MICAZ_TOSSIM
#include "TupleSerialMsg.h"
#endif
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
  components LedsC as led;
  components NoLedsC as LedsC;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components new TimerMilliC() as TimerW;
  components DataCollection;
  components DataDissemination;
  components TupleGateway;
  components ActiveMessageC as AM;
  
  components TimeSyncC;
  
#ifndef MICAZ_TOSSIM
  components SerialActiveMessageC as SerialAM;
#endif

  DataDissemination.Boot -> MainC.Boot;
  DataDissemination.TeenyLIMESystem -> TeenyLimeC;
  DataDissemination.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataDissemination.AMPacket -> AM;
  DataDissemination.Leds -> LedsC;
 
#ifdef PRINTF_SUPPORT
  DataDissemination.PrintfControl -> PrintfC;
  DataDissemination.PrintfFlush -> PrintfC;
#endif

  DataCollection.Boot -> MainC.Boot;
  DataCollection.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  DataCollection.AMPacket -> AM;

#ifdef PRINTF_SUPPORT
  DataCollection.PrintfControl -> PrintfC;
  DataCollection.PrintfFlush -> PrintfC;
#endif

  TupleGateway.Boot -> MainC.Boot;
  TupleGateway.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  TupleGateway.AMPacket -> AM;
  TupleGateway.Leds -> led;
  TupleGateway.GlobalTime -> TimeSyncC;
  TupleGateway.TimerWait -> TimerW;
#ifndef MICAZ_TOSSIM
  TupleGateway.SerialControl -> SerialAM;
  TupleGateway.SerialSend -> SerialAM.AMSend[AM_TUPLE_SERIAL_MSG];
  TupleGateway.SerialReceive -> SerialAM.Receive[AM_TUPLE_SERIAL_MSG];
#endif
}

