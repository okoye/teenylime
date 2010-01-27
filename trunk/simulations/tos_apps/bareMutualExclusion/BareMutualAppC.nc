#define BARE_ME_AM 5

configuration BareMutualAppC {

}

implementation {

  components Main, TimerC,  GenericComm as Comm, BareMutualExclusion, 
    ReliableGenericComm, MessageQueue, SampleMExclusionM, LedsC;

  Main.StdControl -> SampleMExclusionM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> Comm;
  Main.StdControl -> ReliableGenericComm;
  Main.StdControl -> MessageQueue;

  BareMutualExclusion.Send -> ReliableGenericComm;
  BareMutualExclusion.Receive -> ReliableGenericComm;
  BareMutualExclusion.PeriodicRefresh -> TimerC.Timer[unique("Timer")];

  SampleMExclusionM.MutualExclusion -> BareMutualExclusion;
  SampleMExclusionM.Timer -> TimerC.Timer[unique("Timer")];
  SampleMExclusionM.Leds -> LedsC;
  
  ReliableGenericComm.Send ->  MessageQueue.Send;
  ReliableGenericComm.Receive -> MessageQueue.Receive;
  ReliableGenericComm.OneShotTimer -> TimerC.Timer[unique("Timer")];
  ReliableGenericComm.PeriodicTimer -> TimerC.Timer[unique("Timer")];
  ReliableGenericComm.Leds -> LedsC;

  MessageQueue.SendMsgTimer -> TimerC.Timer[unique("Timer")];
  MessageQueue.SendComm -> Comm.SendMsg[BARE_ME_AM];
  MessageQueue.ReceiveComm -> Comm.ReceiveMsg[BARE_ME_AM];
}

