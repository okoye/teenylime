includes TupleSpace;
includes TupleMsg;

configuration TestTeenyLime {
}

implementation {
  components Main, TestTeenyLimeM, TimerC, TeenyLimeSerializer, LocalTeenyLime, DistributedTeenyLime, GenericComm as Comm, TeenyLimeM, LedsC, MessageQueue, ReliableGenericComm;

  Main.StdControl -> TestTeenyLimeM;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> Comm;
  Main.StdControl -> ReliableGenericComm;

  TestTeenyLimeM.TS -> TeenyLimeM.TupleSpace[unique("Component")];
  TestTeenyLimeM.TeenyLimeControl -> TeenyLimeM;
  TestTeenyLimeM.TeenyLIMESystem -> TeenyLimeM;
  TestTeenyLimeM.Timer -> TimerC.Timer[unique("Timer")];
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
