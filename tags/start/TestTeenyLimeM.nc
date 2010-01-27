includes AM;

module TestTeenyLimeM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface TupleSpace as TS;
    interface StdControl as TeenyLimeControl;
    interface TeenyLIMESystem;
  }
}

implementation {

  int ticks = 0;
  TLOpId_t reaction1Id, reaction2Id, remoteReaction1Id;
  tuple myTuple;

  task void testOut() {
    tuple t;
    t = newTuple(3, actualField_uint16(15), actualField_float(15.4), actualField_char('r'));
    call TS.out(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testExpireOut() {
    tuple t;
    t = newTuple(3, actualField_uint16(15), actualField_float(15.4), actualField_char('r'));
    setExpireIn(&t,100);
    call TS.out(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testCapabilityOut() {
    tuple t;
    t = newCapabilityTuple(2, actualField_uint16(0), formalField(TYPE_FLOAT));
    call TS.out(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testCapabilityRd() {
    tuple t;
    t = newTuple(2, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT));
    call TS.rd(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteOut1() {
    tuple t;
    t = newTuple(3, actualField_uint16(TOS_LOCAL_ADDRESS), actualField_float(0.1), actualField_char('r'));
    call TS.out(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteOut2() {
    tuple t;
    t = newTuple(3, actualField_uint16(TOS_LOCAL_ADDRESS), actualField_float(0.2), actualField_char('r'));
    call TS.out(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteRd() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    call TS.rd(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteRdFreshness() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    setFreshness(&t,10);
    call TS.rd(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteRdg() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    call TS.rdg(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoteIng() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    call TS.ing(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testMultipleOut() {
    tuple t;

    t = newTuple(3, actualField_uint16(15), actualField_float(15.4), actualField_char('c'));
    call TS.out(FALSE, TOS_LOCAL_ADDRESS, &t);

    t = newTuple(3, actualField_uint16(15), actualField_float(15.4), actualField_char('e'));
    call TS.out(FALSE, TOS_LOCAL_ADDRESS, &t);

    t = newTuple(3, actualField_uint16(15), actualField_float(15.4), actualField_char('g'));
    call TS.out(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testRd() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));     
    call TS.rd(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testRdRange() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), rangeField(10,15), formalField(TYPE_STR));   
    call TS.rd(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testRdRangeOut() {
    tuple t;
    char tupleString[100];
    t=newTuple(3, dontCareField(), rangeOutField(10,15), formalField(TYPE_CHAR));
#ifndef mica2
    printTuple(&t, tupleString);
    dbg (DBG_USR1, "%s\n",tupleString);
#endif
    call TS.rd(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testRdg() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    call TS.rdg(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testDontCareTuple() {
    tuple t;
    char tupleString[100];

    t=dontCareTuple();
#ifndef mica2
    printTuple(&t, tupleString);
    dbg (DBG_USR1, "%s\n",tupleString);
#endif

    call TS.rdg(FALSE, TOS_LOCAL_ADDRESS, &t);
  }


  task void testTLSystem() {
    tuple t;
    t=newTuple(1, formalField(TYPE_UINT16_T));
    call TS.rdg(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testIng() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    call TS.ing(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testAddReaction() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    reaction1Id = call TS.addReaction(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testAddRemoteReaction() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    remoteReaction1Id = call TS.addReaction(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testAddRemoteCapabilityReaction() {
    tuple t;
    t=newTuple(2, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT));
    remoteReaction1Id = call TS.addReaction(FALSE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoveRemoteReaction() {
    remoteReaction1Id = call TS.removeReaction(remoteReaction1Id);
  }

  task void testRemoveReaction1() {
    reaction1Id = call TS.removeReaction(reaction1Id);
  }

  task void testIn() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    call TS.in(FALSE, TOS_LOCAL_ADDRESS, &t);
  }

  task void testReliableRemoteOut() {
    tuple t;
    t = newTuple(3, actualField_uint16(TOS_LOCAL_ADDRESS), actualField_float(0.1), actualField_char('r'));
    call TS.out(TRUE, TOS_BCAST_ADDR, &t);
  }

  task void testReliableRemoteRd() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    call TS.rd(TRUE, TOS_BCAST_ADDR, &t);
  }

  task void testReliableRemoteRdg() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));    
    call TS.rdg(TRUE, TOS_BCAST_ADDR, &t);
  }

  task void testAddReliableRemoteReaction() {
    tuple t;
    t=newTuple(3, formalField(TYPE_UINT16_T), formalField(TYPE_FLOAT), formalField(TYPE_CHAR));
    remoteReaction1Id = call TS.addReaction(TRUE, TOS_BCAST_ADDR, &t);
  }

  task void testRemoveReliableRemoteReaction() {
    remoteReaction1Id = call TS.removeReaction(remoteReaction1Id);
  }

  task void beacon() {
    call TS.out(FALSE, TOS_BCAST_ADDR, &myTuple);
  }

  command result_t StdControl.init() {
    myTuple = newTuple(1,  actualField_uint16(TOS_LOCAL_ADDRESS));
    dbg(DBG_USR1, "Init\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "Start\n");
    call Timer.start(TIMER_REPEAT, 1024);    
    return SUCCESS;
  }


 command result_t StdControl.stop() {
   dbg(DBG_USR1, "Stop");
   return SUCCESS;
 }

  event result_t TS.tupleReady(TLOpId_t operationId, tuple *tuples, uint8_t number) {

#ifndef mica2
    char tupleString[100];
    uint8_t i;
#endif

    dbg(DBG_USR1, "Application: fired event TupleReady for % d tuples...\n", number);
    
#ifndef mica2
    for (i=0; i< number; i++){
      printTuple(&tuples[i], tupleString);
      dbg(DBG_USR1, "Application: %s\n", tupleString);
    }
#endif

    if (number == 0) 
      dbg(DBG_USR1, "No tuples returned.\n");

    return SUCCESS;
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    tuple t;
    dbg (DBG_USR1, "Request to reify capability tuple\n");
    t = newTuple(2, actualField_uint16(30), actualField_float(0.4));
    call TS.out (FALSE, TOS_LOCAL_ADDRESS, &t);  
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    //dbg (DBG_USR1, "Request for neighbor tuple\n");
    return &(myTuple);
  }

  event result_t Timer.fired() {
    
    ticks++;
    if(ticks == 1)
      post testOut();

    dbg (DBG_USR1, "Local time is %d\n", ticks);

    if(ticks == 20 && TOS_LOCAL_ADDRESS==0)
      post beacon();
    
    //      if(ticks == 20 && TOS_LOCAL_ADDRESS==0) {
    //       post testReliableRemoteRd();
    //      post testRemoteOut1();
    // }


    if(ticks == 6){ 
//       if (TOS_LOCAL_ADDRESS == 1) post testAddRemoteCapabilityReaction();
//	if (TOS_LOCAL_ADDRESS == 0) post testCapabilityOut();
    }

    return SUCCESS;
  }
}
