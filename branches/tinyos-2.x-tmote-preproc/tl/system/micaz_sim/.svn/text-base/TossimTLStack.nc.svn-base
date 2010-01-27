/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 792 $
 * * DATE
 * *    $LastChangedDate: 2009-05-01 15:17:13 +0200 (Fri, 01 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TossimTLStack.nc 792 2009-05-01 13:17:13Z lmottola $
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


/**
 * Configuration of a Tossim-specific network stack for TeenyLIME.
 * 
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 * 
 */

#define QUEUE_REQUESTS 10

configuration TossimTLStack {

  provides {
    interface SendTuple;
    interface ReceiveTuple;
    interface NeighborSystem;
  }
}

implementation { 

  components MainC;
  components TossimTLSerializer, TossimMsgQueueM;
  components TLDebugM, LedsC;

  components new AMSenderC(TUPLE_AM);
  components new AMReceiverC(TUPLE_AM);
  components new AMSnooperC(TUPLE_AM);
  components ActiveMessageC;

  components TLObjectsParsed;

  SendTuple = TossimTLSerializer;
  ReceiveTuple = TossimTLSerializer;
  NeighborSystem = TossimTLSerializer;
  
  TossimTLSerializer.ReliableSend -> TossimMsgQueueM;
  TossimTLSerializer.Receive -> TossimMsgQueueM.Receive;
  TossimTLSerializer.AMPacket -> ActiveMessageC;
  TossimTLSerializer.TLDebug -> TLDebugM;
  TossimTLSerializer.TLObjects -> TLObjectsParsed;

  TossimMsgQueueM.Boot -> MainC.Boot;
  TossimMsgQueueM.AMPacket -> ActiveMessageC;
  TossimMsgQueueM.SubAMControl -> ActiveMessageC;
  TossimMsgQueueM.AMSend -> AMSenderC;
  TossimMsgQueueM.AMReceive -> AMReceiverC;
  TossimMsgQueueM.TLDebug -> TLDebugM;
}

