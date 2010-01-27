#include "Constants.h"

configuration ElderyC {
}

implementation {
// --- Serial Forwarder ---
#if (MY_TYPE == SINK_NODE)
#warning You are building the sink.
  components SerialForwarderC;
#endif

// --- Orchestrator ---
components OrchestratorC;


// --- Proximity ---
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  components ProximityC;
  ProximityC.Orchestrator -> OrchestratorC;
  OrchestratorC.ProximityState -> ProximityC;
#else
  components DummyProximityC;
#endif

// --- Tree --- 
#if (MY_TYPE == MOBILE_NODE)
  components DumbTreeBuilderC as Tree;
#endif

#if (MY_TYPE == ANCHOR_NODE)
  components TreeBuilderC as Tree;
  Tree.Orchestrator -> OrchestratorC;
  Tree.ProximityState -> ProximityC;
#endif

#if (MY_TYPE == SINK_NODE) || (MY_TYPE == FIXED_NODE)
  components TreeBuilderC as Tree;
  Tree.Orchestrator -> OrchestratorC;
#endif
  OrchestratorC.TreeConnection -> Tree;

// --- Periodic sensors reading ---
  components SensorsDataC;
  SensorsDataC.Orchestrator -> OrchestratorC;

// --- Other components ---
#if (MY_TYPE == MOBILE_NODE)
  components ButtonMessageC;
  ButtonMessageC.Orchestrator -> OrchestratorC;
#endif   

#if (MY_TYPE == MOBILE_NODE) && !defined(NO_POSTURE)
#warning Using posture detection.
  components PostureDetectionC;
  PostureDetectionC.Orchestrator -> OrchestratorC;
#endif
}
