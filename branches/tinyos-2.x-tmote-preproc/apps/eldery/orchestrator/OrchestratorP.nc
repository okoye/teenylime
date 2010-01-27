#include "Constants.h"

module OrchestratorP {

  uses {    
    interface Leds;  
    interface Boot;
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
    interface ProximityState;
#endif
    interface TupleSpace as TS;
    interface TeenyLIMESystem; 
    interface Tuning as TLTuning;
  }
  provides interface Orchestrator;
}

implementation {
  TLOpId_t reactionId;
  /* The fields in the neighborTuple must match the ones in Constants.h */
  NeighborTuple<uint16_t, lqi, rssi, uint32_t> neighborTuple;


  event void Boot.booted()
  {
    neighborTuple = newTuple(actualField(TOS_NODE_ID), lqiRead(),
            rssiRead(), actualField(0));
  }


  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator)
  {
  }


  event void TS.operationCompleted(uint8_t completionCode, 
          TLOpId_t operationId, 
          TLTarget_t target, 
          TLTupleSpace_t ts,  
          tuple* returningTuple)
  {    
  }


  event void TS.reifyCapabilityTuple(tuple* ct) {
  }	


  event tuple * TeenyLIMESystem.reifyNeighborTuple() {
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
    neighborTuple.nextAwake_field = call ProximityState.nextRadioOn();
#else
    neighborTuple.nextAwake_field = 0;
#endif
    return (tuple *) &neighborTuple;
  }


  event void TLTuning.setDone(uint8_t key, uint16_t value)
  {
  }


  command void Orchestrator.requestRadioOn()
  {
    call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, LOCAL_LPL_INTERVAL);
  }


  command void Orchestrator.requestRadioOff()
  {
    call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, PROXIMITY_HALF_EPOCH);
  }


  command bool Orchestrator.isRadioOn()
  {
  }
}
