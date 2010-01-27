#include "Constants.h"

configuration ElderyC {
}

implementation {
  components OrchestratorC;

#if (MY_TYPE == SINK_NODE)
#warning You are building the sink.
  components SerialForwarderC;
#endif

#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  components ProximityC;
  ProximityC.Orchestrator -> OrchestratorC;
  OrchestratorC.ProximityState -> ProximityC;
#else
  components DummyProximityC;
#endif

#if (MY_TYPE == MOBILE_NODE) && !defined(NO_POSTURE)
#warning Using posture detection.
  components PostureDetectionC;
#endif
}
