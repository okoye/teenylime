/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 291 $
 * * DATE
 * *    $LastChangedDate: 2008-02-20 09:01:57 -0600 (Wed, 20 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TeenyLimeC.nc 291 2008-02-20 15:01:57Z lmottola $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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

#include "AM.h"
#include "TupleSpace.h"
#include "TupleMsg.h"

/**
 * The main configuration of TeenyLIME.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

configuration TeenyLimeC {

  provides {
    interface TupleSpace[uint8_t componentId];
    interface TeenyLIMESystem;
  }
}

implementation { 
  components MainC;
  components TeenyLimeM, LocalTeenyLime, DistributedTeenyLime;

#if defined(tmote) || defined(telosb)
  components TMoteTLStack as NetworkStack;
#endif
#ifdef MICAZ_TOSSIM 
  components MicazTossimTLStack as NetworkStack;
#endif

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components TLDebugM, LedsC;
       
  components ActiveMessageC as AM;

  components new TimerMilliC() as TLEpochTimer;
  components new TimerMilliC() as TLBlinkTimer;

  TupleSpace = TeenyLimeM.TupleSpace;
  TeenyLIMESystem = TeenyLimeM.TeenyLIMESystem;

  MainC.SoftwareInit -> TeenyLimeM;
  MainC.SoftwareInit -> LocalTeenyLime;
  MainC.SoftwareInit -> DistributedTeenyLime;

  TeenyLimeM.LocalTupleSpace -> LocalTeenyLime;
  TeenyLimeM.DistributedTupleSpace -> DistributedTeenyLime;
  TeenyLimeM.AMPacket -> AM;

#ifdef PRINTF_SUPPORT
  TeenyLimeM.PrintfControl -> PrintfC; 
  TeenyLimeM.PrintfFlush -> PrintfC; 
#endif

  LocalTeenyLime.Boot -> MainC.Boot;
  LocalTeenyLime.AMPacket -> AM;
  LocalTeenyLime.LogicalTime -> TLEpochTimer;
  LocalTeenyLime.TLDebug -> TLDebugM;

#ifdef PRINTF_SUPPORT
  LocalTeenyLime.PrintfControl -> PrintfC; 
  LocalTeenyLime.PrintfFlush -> PrintfC; 
#endif

  DistributedTeenyLime.BridgeTupleSpace -> LocalTeenyLime.BridgeTupleSpace;
  DistributedTeenyLime.SendTuple -> NetworkStack;
  DistributedTeenyLime.ReceiveTuple -> NetworkStack;
  DistributedTeenyLime.NeighborSystem -> NetworkStack;
  DistributedTeenyLime.TLDebug -> TLDebugM;

#ifdef PRINTF_SUPPORT
  DistributedTeenyLime.PrintfControl -> PrintfC; 
  DistributedTeenyLime.PrintfFlush -> PrintfC; 
#endif

  TLDebugM.BlinkTimer -> TLBlinkTimer;
  TLDebugM.Leds -> LedsC;

#ifdef PRINTF_SUPPORT
  TLDebugM.PrintfControl -> PrintfC; 
  TLDebugM.PrintfFlush -> PrintfC; 
#endif
}

