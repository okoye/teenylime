/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 4 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 10:22:42 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: paolinux78 $
 * *
 * *	$Id: TeenyLimeC.nc 4 2007-04-27 15:22:42Z paolinux78 $
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

includes AM;
includes TupleSpace;
includes TupleMsg;

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
    interface StdControl;
  }
}

implementation {
  components TeenyLimeM, LocalTeenyLime, DistributedTeenyLime, 
    TimerC,  GenericComm as Comm, 
    ReliableGenericComm, TeenyLimeSerializer, MessageQueue,
    LedsC;

  StdControl = TeenyLimeM.StdControl;
  StdControl = Comm;
  StdControl = ReliableGenericComm;
  StdControl = MessageQueue;

  TupleSpace = TeenyLimeM.TupleSpace;
  TeenyLIMESystem = TeenyLimeM.TeenyLIMESystem;

  TeenyLimeM.LocalTupleSpaceControl -> LocalTeenyLime;
  TeenyLimeM.LocalTupleSpace -> LocalTeenyLime;
  TeenyLimeM.DistributedTupleSpaceControl -> DistributedTeenyLime;
  TeenyLimeM.DistributedTupleSpace -> DistributedTeenyLime;

  DistributedTeenyLime.BridgeTupleSpace -> LocalTeenyLime.BridgeTupleSpace;
  DistributedTeenyLime.OperationTimer -> TimerC.Timer[unique("Timer")];
  DistributedTeenyLime.PeriodicTimer -> TimerC.Timer[unique("Timer")];
  DistributedTeenyLime.SendTuple -> TeenyLimeSerializer;
  DistributedTeenyLime.ReceiveTuple -> TeenyLimeSerializer;
  DistributedTeenyLime.Leds -> LedsC;

  TeenyLimeSerializer.NeighborSystem -> DistributedTeenyLime;
  TeenyLimeSerializer.ReliableSend -> ReliableGenericComm.ReliableSend;
  TeenyLimeSerializer.Receive -> ReliableGenericComm.ReliableReceive;
  
  ReliableGenericComm.Send ->  MessageQueue.Send;
  ReliableGenericComm.Receive -> MessageQueue.Receive;
  ReliableGenericComm.OneShotTimer -> TimerC.Timer[unique("Timer")];
  ReliableGenericComm.PeriodicTimer -> TimerC.Timer[unique("Timer")];
  ReliableGenericComm.Leds -> LedsC;
  MessageQueue.SendMsgTimer -> TimerC.Timer[unique("Timer")];
  MessageQueue.SendComm -> Comm.SendMsg[TUPLE_AM];
  MessageQueue.ReceiveComm -> Comm.ReceiveMsg[TUPLE_AM];

  LocalTeenyLime.LogicalTime -> TimerC.Timer[unique("Timer")];
}
