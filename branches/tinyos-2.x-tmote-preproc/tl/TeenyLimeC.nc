/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 944 $
 * * DATE
 * *    $LastChangedDate: 2009-11-25 02:23:31 -0600 (Wed, 25 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TeenyLimeC.nc 944 2009-11-25 08:23:31Z sguna $
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


#include "TupleSpace.h"
#include "TupleMsg.h"

#include "TLConf.h"
#define RECEIVE_HISTORY_SIZE MAX_NEIGHBORS + 1

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
    interface TeenyLIMEExceptions;

#ifdef PLATFORM_TELOSB
    interface Tuning[uint8_t componentId];
#endif
  }
}

implementation { 
  components MainC;
  components TeenyLimeM, LocalTeenyLime, DistributedTeenyLime;
  components TeenySlabAllocator;
#ifdef FLASH_SYNC_TIME
  components FlashSlabAllocator;
  components FlashOpQueue;
#endif
  components TLObjectsParsed;

#ifdef PLATFORM_TELOSB
  components TMoteTLStack as NetworkStack;
#endif
#ifdef TOSSIM
  components TossimTLStack as NetworkStack;
#endif

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components TLDebugM, LedsC;
       
  components ActiveMessageC as AM;

  components new TimerMilliC() as TLEpochTimer;
  components new TimerMilliC() as TLBlinkTimer;
  components new TimerMilliC() as TLRemoteOpsTimer;
#ifdef FLASH_SYNC_TIME
  components new TimerMilliC() as PersistenceSyncTimer;
#endif

  TupleSpace = TeenyLimeM.TupleSpace;
  TeenyLIMESystem = TeenyLimeM.TeenyLIMESystem;
#ifdef PLATFORM_TELOSB
  Tuning = NetworkStack;
#endif
  TeenyLIMEExceptions = TeenyLimeM.TeenyLIMEExceptions;
  
  MainC.SoftwareInit -> TeenyLimeM;
  MainC.SoftwareInit -> LocalTeenyLime;
  MainC.SoftwareInit -> DistributedTeenyLime;

  TeenyLimeM.TLObjects -> TLObjectsParsed;
  TeenyLimeM.LocalTupleSpace -> LocalTeenyLime;
  TeenyLimeM.SubTeenyLIMEExceptions -> LocalTeenyLime;
  TeenyLimeM.DistributedTupleSpace -> DistributedTeenyLime;

#ifdef PRINTF_SUPPORT
  TeenyLimeM.PrintfControl -> PrintfC; 
  TeenyLimeM.PrintfFlush -> PrintfC; 
#endif

  LocalTeenyLime.Boot -> MainC.Boot;
  LocalTeenyLime.AMPacket -> AM;
  LocalTeenyLime.LogicalTime -> TLEpochTimer;
  LocalTeenyLime.TLDebug -> TLDebugM;
  LocalTeenyLime.SlabAllocator -> TeenySlabAllocator;
  LocalTeenyLime.TLObjects -> TLObjectsParsed;
  LocalTeenyLime.Leds-> LedsC;

#ifdef PRINTF_SUPPORT
  LocalTeenyLime.PrintfControl -> PrintfC; 
  LocalTeenyLime.PrintfFlush -> PrintfC; 
#endif

  TeenySlabAllocator.TLDebug -> TLDebugM;
  TeenySlabAllocator.TLObjects -> TLObjectsParsed;
 
#ifdef FLASH_SYNC_TIME
  TeenyLimeM.FlashOperations -> FlashOpQueue;
  
  LocalTeenyLime.FlashAllocator -> FlashSlabAllocator;
  LocalTeenyLime.FlashOperations -> FlashOpQueue;
  
  FlashSlabAllocator.FlashStorage -> NetworkStack;
  FlashSlabAllocator.TLDebug -> TLDebugM;
  FlashSlabAllocator.TLObjects -> TLObjectsParsed;
  FlashSlabAllocator.Leds -> LedsC;
  FlashSlabAllocator.FlashOperations -> FlashOpQueue;
  FlashSlabAllocator.PersistenceSyncTimer -> PersistenceSyncTimer;
  FlashSlabAllocator.Tuning -> NetworkStack.Tuning[unique("TLTuning")];

  FlashOpQueue.AMPacket -> AM;
  FlashOpQueue.TLObjects -> TLObjectsParsed;
  FlashOpQueue.RunOp -> LocalTeenyLime;
  FlashOpQueue.TLDebug -> TLDebugM;
  FlashOpQueue.Leds -> LedsC;
  
  NetworkStack.SlabSerializer -> FlashSlabAllocator;
#ifdef PRINTF_SUPPORT
  FlashOpQueue.PrintfControl -> PrintfC; 
  FlashOpQueue.PrintfFlush -> PrintfC; 
  FlashSlabAllocator.PrintfControl -> PrintfC;
  FlashSlabAllocator.PrintfFlush-> PrintfC;
#endif
#endif

#ifdef PRINTF_SUPPORT
  TeenySlabAllocator.PrintfControl -> PrintfC;
  TeenySlabAllocator.PrintfFlush-> PrintfC;
#endif

  DistributedTeenyLime.BridgeTupleSpace -> LocalTeenyLime.BridgeTupleSpace;
  DistributedTeenyLime.RemoteOpsTimer -> TLRemoteOpsTimer;
  DistributedTeenyLime.SendTuple -> NetworkStack;
  DistributedTeenyLime.ReceiveTuple -> NetworkStack;
#ifdef PLATFORM_TELOSB
  DistributedTeenyLime.Tuning -> NetworkStack.Tuning[unique("TLTuning")];
#endif
  DistributedTeenyLime.NeighborSystem -> NetworkStack;
  DistributedTeenyLime.SlabAllocator -> TeenySlabAllocator;
  DistributedTeenyLime.TLDebug -> TLDebugM;
  DistributedTeenyLime.TLObjects -> TLObjectsParsed;
  DistributedTeenyLime.Leds-> LedsC;


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

