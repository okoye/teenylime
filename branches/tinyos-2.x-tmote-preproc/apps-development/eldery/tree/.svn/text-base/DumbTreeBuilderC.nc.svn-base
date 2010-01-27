configuration DumbTreeBuilderC {
  provides interface TreeConnection;
}

implementation {
  //Essential components  
  components MainC;
  components LedsC;
  components NoLedsC as led;
  components TeenyLimeC;
  components DumbTreeBuilderP;
   
  //TreeBuilder wiring
  DumbTreeBuilderP.TS -> TeenyLimeC.TupleSpace[unique("TL")];;
  DumbTreeBuilderP.Boot -> MainC.Boot;
  DumbTreeBuilderP.Leds -> LedsC;//led;
  DumbTreeBuilderP.TreeConnection = TreeConnection;
}
