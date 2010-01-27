configuration TreeBuilderC {
  provides interface TreeConnection;
  uses interface Orchestrator;
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  uses interface ProximityState;
#endif
}

implementation {
  //Essential components  
  components MainC, LedsC;
  components NoLedsC as led;
  components TeenyLimeC;
  components TreeBuilderP as TB;
   
  //Tree components
  components new TimerMilliC() as TimerUR;
  components new TimerMilliC() as TimerFW;
  components new TimerMilliC() as TimerParentWakeUp;
  components ActiveMessageC as AM;
  components RandomC;



  //TreeBuilder wiring
  TB.TS -> TeenyLimeC.TupleSpace[unique("TL")];;
  TB.Boot -> MainC.Boot;
  TB.AMPacket -> AM;
  TB.Leds -> LedsC;//led;
  TB.TimerParentUpdate -> TimerUR;
  TB.TimerFW -> TimerFW;
  TB.TimerParentWakeUp -> TimerParentWakeUp;
  TB.Random -> RandomC;
  TB.Orchestrator = Orchestrator;
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  TB.Proximity = ProximityState;
#endif
  TB.TreeConnection = TreeConnection;
}
