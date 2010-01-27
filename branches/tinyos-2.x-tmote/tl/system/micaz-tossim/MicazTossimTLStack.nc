/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 256 $
 * * DATE
 * *    $LastChangedDate: 2008-01-28 12:20:56 -0600 (Mon, 28 Jan 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MicazTossimTLStack.nc 256 2008-01-28 18:20:56Z lmottola $
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

#include "MicazTossimStackConf.h"

/**
 * Configuration of a TMote-specific network stack for TeenyLIME.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

configuration MicazTossimTLStack {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }
}

implementation { 

  components MainC;
  components MicazTossimTLSerializer, MicazTossimMsgQueueM, RandomC;
  components TLDebugM, LedsC;

  components new AMSenderC(TUPLE_AM);
  components new AMReceiverC(TUPLE_AM);
  components ActiveMessageC as AM;

  components new TimerMilliC() as StackTimer;

  SendTuple = MicazTossimTLSerializer;
  ReceiveTuple = MicazTossimTLSerializer;
  NeighborSystem = MicazTossimTLSerializer;
  
  MicazTossimTLSerializer.ReliableSend -> MicazTossimMsgQueueM;
  MicazTossimTLSerializer.Receive -> MicazTossimMsgQueueM;
  MicazTossimTLSerializer.AMSend -> AMSenderC;
  MicazTossimTLSerializer.AMPacket -> AM;
  MicazTossimTLSerializer.TLDebug -> TLDebugM;

  MicazTossimMsgQueueM.Boot -> MainC.Boot;
  MicazTossimMsgQueueM.SendMsgTimer -> StackTimer;
  MicazTossimMsgQueueM.AMPacket -> AM;
  MicazTossimMsgQueueM.AMControl -> AM;
  MicazTossimMsgQueueM.SendComm -> AMSenderC;
  MicazTossimMsgQueueM.ReceiveComm -> AMReceiverC;
  MicazTossimMsgQueueM.Random -> RandomC;
  MicazTossimMsgQueueM.TLDebug -> TLDebugM;
}

