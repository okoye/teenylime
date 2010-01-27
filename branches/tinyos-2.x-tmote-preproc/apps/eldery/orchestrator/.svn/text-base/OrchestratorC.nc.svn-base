#include "Constants.h"

configuration OrchestratorC {
  provides interface Orchestrator;
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  uses {
    interface ProximityState;
  }
#endif
}

implementation {
  components MainC, LedsC;
  components TeenyLimeC;
  components OrchestratorP;

  OrchestratorP.Boot -> MainC;
  OrchestratorP.Leds -> LedsC;
  OrchestratorP.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  OrchestratorP.TLTuning -> TeenyLimeC.Tuning[unique("TLTuning")];
  OrchestratorP.TeenyLIMESystem -> TeenyLimeC;
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  OrchestratorP.ProximityState = ProximityState;
#endif

  Orchestrator = OrchestratorP;
}
