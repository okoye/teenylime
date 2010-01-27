#include "Constants.h"
#include "TreeBuilder.h"
#include "Orchestrator.h"

/**
 * TODO: Make that a mobile node when generates a messages
 *       send it immediatly, even if the radio is off, and
 *       wait an ack for a short time after that the radio
 *       switch off (unless it is in the wake up period).
 *
 * TODO: Make that an anchors node when receives a messages
 *       if the parent is still wake up send it the message 
 *	     directly. But make sure that the remaining time is
 *	     sufficent to send the message with relailability.
 */

module OrchestratorP {

  uses interface Leds;  
  uses interface Boot;
  uses interface TLObjects;
  uses interface TupleSpace as TS;
  uses interface TeenyLIMESystem; 
  uses interface Tuning as TLTuning;

  uses interface TreeConnection;
  uses interface Timer<TMilli> as TimerFW;
  
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  uses interface Timer<TMilli> as TimerSend;
  uses interface ProximityState;    
  uses interface Random;
#endif    
  
  provides interface Orchestrator;
}

implementation {
  TLOpId_t fwReaction, deleteIng;
  TLOpId_t outId;
  
  TLOpId_t ackTupleId, ackTupleIdIng;
  TLOpId_t ackOutId;

  /* The fields in the neighborTuple must match the ones in Constants.h */
  NeighborTuple<uint16_t, lqi, rssi, uint32_t> neighborTuple;
    
  bool radioOn;
  bool radioStaysOn;
  
  /* Sequence number */
  uint32_t seqNumber;

  
// ========== MOBILE NODE VARIABLES ==========  
#if (MY_TYPE == MOBILE_NODE)
  TLOpId_t fwRdg,fwIngNoLocal;
#endif

// ========== NON MOBILE NODE VARIABLES ==========
#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == ANCHOR_NODE)
  TLOpId_t fwIng, changeTypeOfNodeIng;
  TLOpId_t outReliableId, outToLocalId;
  
  uint8_t nextElDuplBuffer;
  uint16_t duplBufferAddress[SIZE_DUPLICATES_BUFFER];
  uint32_t duplBufferSeq[SIZE_DUPLICATES_BUFFER];
#endif

// ========== MOBILE NODE AND ANCHOR VARIABLES ==========
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
  TLOpId_t timedFwRdg, checkTupleRd;
  
  //Used only by Mobile Nodes to remember if the radio is on to 
  //  waiting an ack
  bool ackRadioOn;
  uint8_t numberNoAckTx;
    
  /*Buffer variables used to send the fw tuple
     with a short delay between each others */
  
  uint16_t buffAdd[NUM_MAX_FW_TUPLE];
  uint32_t buffSeq[NUM_MAX_FW_TUPLE];
  int16_t buffNumElements;
  int16_t nextElementToSend;
#endif


  /* ---------------- Local functions --------------- */
  void localRequestRadioOn(){
    atomic{    
      if (radioStaysOn<255){
//      if (radioStaysOn<1){
        radioStaysOn++;
      }
      if (!radioOn){
        call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, LOCAL_LPL_INTERVAL);
        radioOn=TRUE;
        call Leds.led0On();
      }
    }
  }

  
  void localRequestRadioOff(){
    atomic{    
      if (radioStaysOn>0){
        radioStaysOn--;
      }
      if (radioStaysOn<=0){
        call TLTuning.setImmediate(KEY_LOCAL_LPL_SLEEP, PROXIMITY_HALF_EPOCH);
        radioOn=FALSE;
        call Leds.led0Off();
      }
    }
  }

  /* ---------------- BOOT interface ----------------- */
  event void Boot.booted(){
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwPattern;
    // Ack tuple
    tuple<uint8_t, uint16_t, uint32_t> ackPattern;
    
    // TODO insert nextawake
    neighborTuple = newTuple(actualField(TOS_NODE_ID), lqiRead(),
            rssiRead(), actualField(0));
       
    radioStaysOn = FALSE;
    radioOn = TRUE;
    call Leds.led0On();

    seqNumber = 0;
    
#if (MY_TYPE == MOBILE_NODE)
    ackRadioOn=FALSE;
    numberNoAckTx = 0;      
    call TimerFW.startOneShot(PROXIMITY_HALF_EPOCH);
#endif

#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == ANCHOR_NODE)
    for (nextElDuplBuffer=0; nextElDuplBuffer<SIZE_DUPLICATES_BUFFER; nextElDuplBuffer++){
      duplBufferAddress[nextElDuplBuffer]=TL_NEIGHBORHOOD;
    }
    nextElDuplBuffer = 0;
#endif 
    fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), dontCare(), dontCare());
    call TS.addReaction(&fwReaction, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
        
    ackPattern = newTuple(actualField(ACK_TUPLE), dontCare(), dontCare());
    call TS.addReaction(&ackTupleId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &ackPattern);
  }  

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator){
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]>  t;
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *temp;
    // Ack tuple
    tuple<uint8_t, uint16_t, uint32_t> tAck;
    tuple<uint8_t, uint16_t, uint32_t> *tempAck;

    uint8_t addrParent;
    
    bool boolVar;
    uint8_t uint8Var;

    // ========== fwReaction ==========
#if (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(fwReaction,
      ;  
      temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);   
      //if parent is every time up then call Forward all fwTuple in TS
      if ((temp->fwAddress_field)==TL_LOCAL){
        if (radioOn){
          t = newTuple(actualField(FORWARD_TUPLE), equal(TL_LOCAL), equal(temp->fwSeq_field), dontCare(), dontCare());
          call TS.rdg(&fwRdg, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
        }
      } else {
        t = newTuple(actualField(FORWARD_TUPLE), different(TL_LOCAL), dontCare(), dontCare(), dontCare());
        call TS.ing(&fwIngNoLocal, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
      }
    );
#endif

#if (MY_TYPE == SINK_NODE)    
    PROCESS_OP(fwReaction,
      ;
      temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
      if ((temp->fwAddress_field != TOS_NODE_ID) && (temp->fwPrevNodeType_field == MOBILE_NODE)){
        tAck = newTuple(actualField(ACK_TUPLE), actualField(temp->fwAddress_field), actualField(temp->fwSeq_field));
        call TS.out(&ackOutId, FALSE, temp->fwAddress_field, RAM_TS, (tuple *) &tAck);
      }
      
      call Leds.led2Toggle();
    );
#endif
    
#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == ANCHOR_NODE)
    PROCESS_OP(fwReaction,
      ;
      temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
      if ((temp->fwAddress_field != TOS_NODE_ID) && (temp->fwPrevNodeType_field == MOBILE_NODE)){
        tAck = newTuple(actualField(ACK_TUPLE), actualField(temp->fwAddress_field), actualField(temp->fwSeq_field));
        call TS.out(&ackOutId, FALSE, temp->fwAddress_field, RAM_TS, (tuple *) &tAck);
      }
      
      if (MY_TYPE == SINK_NODE){
        call Leds.led2Toggle();
        return;
      }
      
      if (temp->fwPrevNodeType_field==MOBILE_NODE){
        t = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), equal(MOBILE_NODE), dontCare());        
        call TS.ing(&changeTypeOfNodeIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);   
      } else {   
        // Delete if is a duplicate, if is not a duplicate add to history buffer     
        for (uint8Var=0; uint8Var<SIZE_DUPLICATES_BUFFER; uint8Var++){
          if ((duplBufferAddress[uint8Var]==temp->fwAddress_field) && 
              (duplBufferSeq[uint8Var]==temp->fwSeq_field)
             ){ 
            break; 
          }
        }
        //TODO: manage the reliability
        if (uint8Var>=SIZE_DUPLICATES_BUFFER){
          duplBufferAddress[nextElDuplBuffer]=temp->fwAddress_field;
          duplBufferSeq[nextElDuplBuffer]=temp->fwSeq_field;
          nextElDuplBuffer=(nextElDuplBuffer+1) % SIZE_DUPLICATES_BUFFER;   
        } else {
          t = newTuple(actualField(FORWARD_TUPLE), equal(temp->fwAddress_field), equal(temp->fwSeq_field), dontCare(), dontCare());        
          call TS.ing(&deleteIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
          return;        
        }

        //if parent is every time up then call Forward all fwTuple in TS
        if (call TreeConnection.getParentNextWakeUp()==NODE_EVERY_UP){
          t = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), different(MOBILE_NODE), dontCare());
          call TS.ing(&fwIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
        }
      }
    );
#endif

    // ========== fwRdg ==========
#if (MY_TYPE == MOBILE_NODE)
    //Forward all fwTuple that becomes from LOCAL in TS to Neighborhoods
    PROCESS_OP(fwRdg,
      boolVar = FALSE;
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        if ((temp->fwAddress_field)==TL_LOCAL){
          boolVar = TRUE;                
          if (!ackRadioOn){
            localRequestRadioOn();
            ackRadioOn=TRUE;            
          }
          call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) temp);
        }
      }
    );
#endif

    // ========== fwIng ==========
#if (MY_TYPE == ANCHOR_NODE)
    //Forward all fwTuple in TS to parent, if the parent does not exists 
    //  or not receive the tuple -> the tuple are deleted 
    PROCESS_OP(fwIng,      
      addrParent = call TreeConnection.getParent();
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        if (addrParent!=TL_LOCAL){            
          if (!ackRadioOn){
            localRequestRadioOn();
            ackRadioOn=TRUE;            
          }
          call TS.out(&outReliableId, TRUE, addrParent, RAM_TS, (tuple *) temp);
          call Leds.led2Toggle();
        }
      } 
    );
#endif

#if (MY_TYPE == FIXED_NODE)
    //Forward all fwTuple in TS to parent, if the parent does not exists 
    //  or not receive the tuple -> the tuple are deleted 
    PROCESS_OP(fwIng,      
      addrParent = call TreeConnection.getParent();
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        if (addrParent!=TL_LOCAL){            
          call TS.out(&outReliableId, TRUE, addrParent, RAM_TS, (tuple *) temp);
          call Leds.led2Toggle();
        }
      } 
    );
#endif

    // ========== changeTypeOfNodeIng ==========
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == FIXED_NODE)
    //Change the Previous Node Type to the actual type of node,
    //  re-put the tuple in local TS and if the parent is awake
    //  call the TS.ing(&fwIng,.....);
    PROCESS_OP(changeTypeOfNodeIng,      
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){

        // Delete if is a duplicate     
        for (uint8Var=0; uint8Var<SIZE_DUPLICATES_BUFFER; uint8Var++){
          if ((duplBufferAddress[uint8Var]==temp->fwAddress_field) && 
              (duplBufferSeq[uint8Var]==temp->fwSeq_field)
             ){ 
            break; 
          }
        }
        //TODO: manage the reliability
        if (uint8Var>=SIZE_DUPLICATES_BUFFER){
          t = newTuple(actualField(temp->fwMsgType_field), actualField(temp->fwAddress_field), actualField(temp->fwSeq_field), actualField(MY_TYPE), arrayField());
          call TLObjects.copy_tuple((tuple *) t.fwPayload_field, 
                                  (tuple *) &(temp->fwPayload_field));
          call TS.out(&outToLocalId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);       
        }    
      } 
    );
#endif  

    // ========== timedFwRdg ==========
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(timedFwRdg,   
      buffNumElements=0;  
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        buffAdd[buffNumElements]=temp->fwAddress_field;
        buffSeq[buffNumElements]=temp->fwSeq_field;
        buffNumElements++;
      }
      nextElementToSend=-1;
      call TimerSend.startOneShot(0);
    );
#endif

    // ========== fwIngNoLocal ==========
#if (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(fwIngNoLocal,
      /*delete all the fwtupple*/
      boolVar = FALSE;
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        boolVar = TRUE;
      }
    );
#endif

    // ========== deleteIng ==========
#if (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(deleteIng,
      /*delete all the fwtupple*/
      boolVar = FALSE;
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
        boolVar = TRUE;
      }
   
      t = newTuple(actualField(FORWARD_TUPLE), equal(TL_LOCAL), dontCare(), dontCare(), dontCare());
      call TS.rd(&checkTupleRd, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
    );
#endif

#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == SINK_NODE) || (MY_TYPE == ANCHOR_NODE)
    PROCESS_OP(deleteIng,
      /*delete all the fwtupple*/
      for (temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator);
           temp != NULL;
           temp = (tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) call TS.nextTuple(operationId, iterator)){
      }
    );
#endif

    // ========== ackTupleId ==========
#if (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(ackTupleId, 
      ;
      numberNoAckTx=0;
      /*call Remove all the ack tuple*/
      tAck = newTuple(actualField(ACK_TUPLE), dontCare(), dontCare());
      call TS.ing(&ackTupleIdIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &tAck);

      tempAck = (tuple<uint8_t, uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator);
      /*call Remove the forwarded*/
      t = newTuple(actualField(FORWARD_TUPLE), actualField(tempAck->ackAddress_field), actualField(tempAck->ackSeq_field), dontCare(), dontCare());
      call TS.ing(&deleteIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &t);
      call Leds.led1Toggle(); 
    );
#endif

#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == SINK_NODE) || (MY_TYPE == ANCHOR_NODE)
    PROCESS_OP(ackTupleId,
      ;
      /*call Remove all the ack tuple*/
      tAck = newTuple(actualField(ACK_TUPLE), dontCare(), dontCare());
      call TS.ing(&ackTupleIdIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &tAck);
    );
#endif 

    // ========== ackTupleIdIng ==========
    PROCESS_OP(ackTupleIdIng,
      /*Delete all the ack tupple*/
      for (tempAck = (tuple<uint8_t, uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator);
           tempAck != NULL;
           tempAck = (tuple<uint8_t, uint16_t, uint32_t> *) call TS.nextTuple(operationId, iterator)){
      }
    );

    // ========== checkTupleRd ==========
#if (MY_TYPE == ANCHOR_NODE) || (MY_TYPE == MOBILE_NODE)
    PROCESS_OP(checkTupleRd,
      if (call TS.nextTuple(operationId, iterator)==NULL){
        if (ackRadioOn){
          numberNoAckTx=0;
          localRequestRadioOff();
          ackRadioOn=FALSE;            
        }
      } else {
        if (!ackRadioOn){
          localRequestRadioOn();
          ackRadioOn=TRUE;            
        }      
      }
    );
#endif

  }
  
  event void TS.operationCompleted(uint8_t completionCode, 
                                   TLOpId_t operationId, 
                                   TLTarget_t target, 
                                   TLTupleSpace_t ts,  
				                           tuple* returningTuple){ 

#if (MY_TYPE == ANCHOR_NODE)  
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwPattern;

	  CHECK_OP(outReliableId, OP_COMPLETED_OK,
      ;
      fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), different(MOBILE_NODE), dontCare());
      call TS.rd(&checkTupleRd, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
	  );
	  
	  CHECK_OP(outReliableId, RELIABLE_OP_FAIL,
	    ;
      fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), different(MOBILE_NODE), dontCare());
      call TS.rd(&checkTupleRd, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
	  );
#endif

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

  /* ---------- TreeConnection ---------- */
   
  event void TreeConnection.parentUpdate(uint16_t parent){
#if (MY_TYPE != MOBILE_NODE)
    call TimerFW.stop();
    if (parent!=TL_LOCAL){
      if (call TreeConnection.getParentNextWakeUp()==NODE_EVERY_UP){
        call TimerFW.startOneShot(PROXIMITY_HALF_EPOCH);
      } else {
        call TimerFW.startOneShot(call TreeConnection.getParentNextWakeUp());      
      }
    }
#endif
  }
  
  /* ---------- TLTuning ------------- */
  event void TLTuning.setDone(uint8_t key, uint16_t value){
  }
  
  /* ---------- Orchestrator ------------- */
  command bool Orchestrator.isRadioOn(){
    return radioOn;  
  }
    
  command void Orchestrator.requestRadioOn(){
    localRequestRadioOn(); 
  }
  
  command void Orchestrator.requestRadioOff(){
    localRequestRadioOff();
  }
  
  command uint8_t Orchestrator.getNextSeqNumber(){
    return (seqNumber ++);  
  }


  /* ---------- TimerFW ------------*/ 
  event void TimerFW.fired(){
    // TODO   check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwPattern;

#if (MY_TYPE == MOBILE_NODE)
    fwPattern = newTuple(actualField(FORWARD_TUPLE), equal(TL_LOCAL), dontCare(), dontCare(), dontCare());
    call TS.rd(&checkTupleRd, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);        

    if (numberNoAckTx <= NUMBER_MAX_TX_WO_ACK){
      //Forward all the local tuple
      fwPattern = newTuple(actualField(FORWARD_TUPLE), equal(TL_LOCAL), dontCare(), dontCare(), dontCare());
      call TS.rdg(&timedFwRdg, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
      numberNoAckTx++;
    } else {
      //Delete all forward tuple in TS    
      fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), dontCare(), dontCare());
      call TS.ing(&deleteIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
      numberNoAckTx=0;
    }
    //Call the next timer      
    call TimerFW.startOneShot(PROXIMITY_HALF_EPOCH);
#endif

#if (MY_TYPE == FIXED_NODE) || (MY_TYPE == ANCHOR_NODE) 
    //Forward all the local tuple
    fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), different(MOBILE_NODE), dontCare());
#if (MY_TYPE == ANCHOR_NODE)
    call TS.rd(&checkTupleRd, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
    call TS.rdg(&timedFwRdg, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);  
#else
    call TS.ing(&fwIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
#endif
    //Call the next timer      
    if (call TreeConnection.getParentNextWakeUp()==NODE_EVERY_UP){
      call TimerFW.startOneShot(PROXIMITY_HALF_EPOCH);
    } else {
      call TimerFW.startOneShot(call TreeConnection.getParentNextWakeUp());      
    }
#endif
  }
  
  /* -------------- TimerSend --------------- */  
 
#if (MY_TYPE == MOBILE_NODE) || (MY_TYPE == ANCHOR_NODE) 
  event void TimerSend.fired(){
    // TODO   check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwPattern;
    uint32_t delay;
    
    if (buffNumElements==0){
      return;    
    }
    
//    delay=call Random.rand32();
//    delay=delay%(((uint32_t)PROXIMITY_HALF_EPOCH*4)/((uint32_t)buffNumElements*5));
//    delay=delay%(((uint32_t)PROXIMITY_HALF_EPOCH*1)/((uint32_t)buffNumElements*10));

      delay=0;
    
    atomic {
      if (nextElementToSend<0){
        nextElementToSend=0;
        call TimerSend.startOneShot(delay);
        return; 
      } else if (nextElementToSend>=buffNumElements){
        return;
      }
    
#if (MY_TYPE == MOBILE_NODE)
      fwPattern = newTuple(actualField(FORWARD_TUPLE), equal(buffAdd[nextElementToSend]), equal(buffSeq[nextElementToSend]), equal(MOBILE_NODE), dontCare());
      call TS.rdg(&fwRdg, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
#else
      fwPattern = newTuple(actualField(FORWARD_TUPLE), equal(buffAdd[nextElementToSend]), equal(buffSeq[nextElementToSend]), different(MOBILE_NODE), dontCare());
      call TS.ing(&fwIng, FALSE, TL_LOCAL, RAM_TS, (tuple *) &fwPattern);
#endif    
      nextElementToSend++;
    }
      call TimerSend.startOneShot(delay);
  }
#endif
}
