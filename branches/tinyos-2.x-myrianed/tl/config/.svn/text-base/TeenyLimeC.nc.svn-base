/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 4 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 17:22:42 +0200 (Fri, 27 Apr 2007) $
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

#include "Tos2Defs.h"
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
    interface StdControl;
  }
}

implementation {
  components TeenyLimeM, LocalTeenyLime, DistributedTeenyLime;
//    ReliableGenericComm,
  components TeenyLimeSerializer, MessageQueue, LedsC;
  components MainC;

  components new AMSenderC(TUPLE_AM);
  components new AMReceiverC(TUPLE_AM);
  components ActiveMessageC as AM;
  components TinyMallocC;

  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
//  components new TimerMilliC() as Timer2;
//  components new TimerMilliC() as Timer3;
  components new TimerMilliC() as Timer4;
  components new TimerMilliC() as Timer5;

  MainC.SoftwareInit -> TeenyLimeM;
  StdControl = TeenyLimeM.StdControl;
//  StdControl = ReliableGenericComm;
  StdControl = MessageQueue;

  TupleSpace = TeenyLimeM.TupleSpace;
  TeenyLIMESystem = TeenyLimeM.TeenyLIMESystem;

  LocalTeenyLime.AMPacket -> AM;
  LocalTeenyLime.Mem -> TinyMallocC;

  TeenyLimeM.LTSControl -> LocalTeenyLime;
  TeenyLimeM.LTS -> LocalTeenyLime;
  TeenyLimeM.LTSInit -> LocalTeenyLime;
  TeenyLimeM.DTSControl -> DistributedTeenyLime;
  TeenyLimeM.DTS -> DistributedTeenyLime;
  TeenyLimeM.DTSInit -> DistributedTeenyLime;
  TeenyLimeM.AMPacket -> AM;

  DistributedTeenyLime.Bridge -> LocalTeenyLime.Bridge;
  DistributedTeenyLime.PendingOpTimer -> Timer0;
  DistributedTeenyLime.EpochTimer -> Timer1;
  DistributedTeenyLime.TLSend -> TeenyLimeSerializer;
  DistributedTeenyLime.TLReceive -> TeenyLimeSerializer;
  DistributedTeenyLime.Leds -> LedsC;
  DistributedTeenyLime.CommInit -> TeenyLimeSerializer;
  DistributedTeenyLime.Mem -> TinyMallocC;

  TeenyLimeSerializer.NeighborSystem -> DistributedTeenyLime;
  TeenyLimeSerializer.Send -> MessageQueue.Send;
  TeenyLimeSerializer.Receive -> MessageQueue.Receive;
  TeenyLimeSerializer.CommInit -> MessageQueue.Init;
  TeenyLimeSerializer.AMPacket -> AM;
  TeenyLimeSerializer.Mem -> TinyMallocC;

//  TeenyLimeSerializer.ReliableSend -> ReliableGenericComm.ReliableSend;
//  TeenyLimeSerializer.Receive -> ReliableGenericComm.ReliableReceive;
//  TeenyLimeSerializer.CommInit -> ReliableGenericComm.Init;

//  ReliableGenericComm.Send ->  MessageQueue.Send;
//  ReliableGenericComm.Receive -> MessageQueue.Receive;
//  ReliableGenericComm.OneShotTimer -> Timer2;
//  ReliableGenericComm.PeriodicTimer -> Timer3;
//  ReliableGenericComm.Leds -> LedsC;
//  ReliableGenericComm.CommInit -> MessageQueue;

  MessageQueue.SendMsgTimer -> Timer4;
  MessageQueue.SendComm -> AMSenderC;
  MessageQueue.ReceiveComm -> AMReceiverC;
  MessageQueue.AMControl -> AM;
  MessageQueue.Mem -> TinyMallocC;

  LocalTeenyLime.EpochTimer -> Timer5;
}
