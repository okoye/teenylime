/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 304 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 04:35:11 -0600 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TMoteTLStack.nc 304 2008-03-04 10:35:11Z lmottola $
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

#include "TMoteStackConf.h"

/**
 * Configuration of a TMote-specific network stack for TeenyLIME.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

configuration TMoteTLStack {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }
}

implementation { 

  components MainC;
  components TMoteTLSerializer, TMoteMsgQueueM;
  components TLDebugM, LedsC;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  components new AMSenderC(TUPLE_AM);
  components new AMReceiverC(TUPLE_AM);
  components new AMSnooperC(TUPLE_AM);
  components ActiveMessageC;

  components CC2420ActiveMessageC;
  components CC2420PacketC;

  SendTuple = TMoteTLSerializer;
  ReceiveTuple = TMoteTLSerializer;
  NeighborSystem = TMoteTLSerializer;
  
  TMoteTLSerializer.ReliableSend -> TMoteMsgQueueM;
  TMoteTLSerializer.Receive -> TMoteMsgQueueM.Receive;
  TMoteTLSerializer.Snoop -> TMoteMsgQueueM.Snoop;
  TMoteTLSerializer.AMPacket -> ActiveMessageC;
  TMoteTLSerializer.AMSend -> AMSenderC;
  TMoteTLSerializer.CC2420Packet -> CC2420PacketC;  
  TMoteTLSerializer.TLDebug -> TLDebugM;
#ifdef PRINTF_SUPPORT
  TMoteTLSerializer.PrintfControl -> PrintfC; 
  TMoteTLSerializer.PrintfFlush -> PrintfC; 
#endif

  TMoteMsgQueueM.Boot -> MainC.Boot;
  TMoteMsgQueueM.AMPacket -> ActiveMessageC;
  TMoteMsgQueueM.AMControl -> ActiveMessageC;
  TMoteMsgQueueM.AMSend -> AMSenderC;
  TMoteMsgQueueM.AMReceive -> AMReceiverC;
  TMoteMsgQueueM.AMSnoop -> AMSnooperC;
  TMoteMsgQueueM.PacketLink -> CC2420ActiveMessageC;
  TMoteMsgQueueM.LowPowerListening -> CC2420ActiveMessageC;
  TMoteMsgQueueM.TLDebug -> TLDebugM;
#ifdef PRINTF_SUPPORT
  TMoteMsgQueueM.PrintfControl -> PrintfC; 
  TMoteMsgQueueM.PrintfFlush -> PrintfC; 
#endif 
}

