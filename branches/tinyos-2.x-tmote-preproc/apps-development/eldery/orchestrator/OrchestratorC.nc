#include "Constants.h"

configuration OrchestratorC {
  provides interface Orchestrator;
  
  uses interface TreeConnection;

#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  uses {
    interface ProximityState;
  }
#endif
}

implementation {
  components MainC, LedsC;
  components NoLedsC as led;
  components TeenyLimeC;
  components OrchestratorP;
  components TLObjectsParsed;

  components new TimerMilliC() as TimerFW;
  
  OrchestratorP.Boot -> MainC;
  OrchestratorP.TLObjects -> TLObjectsParsed;

#if (MY_TYPE == SINK_NODE)
  OrchestratorP.Leds -> led;
#else 
  OrchestratorP.Leds -> LedsC;//led;
  
#endif

  OrchestratorP.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  OrchestratorP.TLTuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  OrchestratorP.TeenyLIMESystem -> TeenyLimeC;

#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  components RandomC;  
  components new TimerMilliC() as TimerSend;

  OrchestratorP.ProximityState = ProximityState;
  OrchestratorP.Random -> RandomC;
  OrchestratorP.TimerSend -> TimerSend;
#endif
  OrchestratorP.TimerFW -> TimerFW;

  Orchestrator = OrchestratorP;
  OrchestratorP.TreeConnection = TreeConnection;
}
