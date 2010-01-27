#define BARE_BENCHMARK_AM 6
#define CONTROLLER

configuration Benchmark {
}

implementation {
  components Main, TimerC, GenericComm as Comm, MessageQueue, Controller, ProactiveNode, ReactiveNode;

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> Comm;
  Main.StdControl -> MessageQueue;  

  MessageQueue.SendMsgTimer -> TimerC.Timer[unique("Timer")];
  MessageQueue.SendComm -> Comm.SendMsg[BARE_BENCHMARK_AM];
  MessageQueue.ReceiveComm -> Comm.ReceiveMsg[BARE_BENCHMARK_AM];

#ifdef REACTIVE
  Main.StdControl -> ReactiveNode.StdControl; 
  ReactiveNode.Send -> MessageQueue.Send; 
  ReactiveNode.Receive -> MessageQueue.Receive;
  ReactiveNode.PeriodicTimer -> TimerC.Timer[unique("Timer")];
#endif

#ifdef PROACTIVE
  Main.StdControl -> ProactiveNode.StdControl; 
  ProactiveNode.Send -> MessageQueue.Send;
  ProactiveNode.Receive -> MessageQueue.Receive;
#endif

#ifdef CONTROLLER
  Main.StdControl -> Controller.StdControl; 
  Controller.Send -> MessageQueue.Send;
  Controller.Receive -> MessageQueue.Receive;
  Controller.RefreshTimer -> TimerC.Timer[unique("Timer")];
#endif
}

