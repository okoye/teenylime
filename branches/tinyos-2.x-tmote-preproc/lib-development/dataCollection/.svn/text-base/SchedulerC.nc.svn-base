#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif
#include "Configuration.h"

#define MIN_REPORT_INTERVAL 1000
#define SLOW_START_INTERVAL 2000
#define SLOW_START_QUANTUMS  50

module SchedulerC {

  uses {
    interface Boot;
    interface TupleSpace as TS;
    interface Leds;
    interface TLObjects;
    interface TokenInfo;
#ifdef CLASS_1
    interface Timer<TMilli> as Rate;
#endif

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {


  tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> TokenMsg;
  TLOpId_t outTkn;
  TLOpId_t inTkn,rdTkn;
  bool fw_active, insert_Token;
  uint16_t contaTuple;
  uint16_t cmsgt;
  uint16_t cmsgl;
  uint16_t ctokenl;
/*  High_rate variable */
  uint8_t slowStartState;  

  
  event void Boot.booted() {


    slowStartState = 0;
    fw_active = FALSE;
    insert_Token = TRUE;
    TokenMsg = newTuple (
    			actualField(MSG_TYPE),
    			actualField(TL_LOCAL),
    			actualField(TOKEN),
    			dontCare() );    
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

#ifdef CLASS_1
  // The timings are tuned to so that 
  uint16_t evaluateReportRate() {

    static uint16_t previousReportRate;
    uint32_t reportRate;

    // Just (re)started
    if (slowStartState == 0) {
      //Restart Rate
      reportRate = SLOW_START_INTERVAL;
    } else {
      // Trying to speed up
      reportRate = previousReportRate;
    }
 
    
    if (reportRate > MIN_REPORT_INTERVAL) {
      slowStartState++;
      reportRate = reportRate - slowStartState*SLOW_START_QUANTUMS;    
      if((reportRate < MIN_REPORT_INTERVAL)||(reportRate > SLOW_START_INTERVAL))
        reportRate = MIN_REPORT_INTERVAL;
      previousReportRate = reportRate;
      return reportRate;
      
    } else {
      // Reached max speed
      previousReportRate = MIN_REPORT_INTERVAL;
      return MIN_REPORT_INTERVAL;
    }
  }  
#endif
 
  event void TokenInfo.forwardingActive(){
    if (!fw_active){
      fw_active = TRUE;
      slowStartState = 0;
        if (insert_Token){
          call TS.out(&outTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
        }
    }
  }

#ifdef CLASS_1
  event void Rate.fired() {
    if (fw_active){
        call TS.out(&rdTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
    } 
    else {
      insert_Token = TRUE;
    }  
  }
#endif

  event void TokenInfo.forwardingInactive(){
    if(fw_active){
      insert_Token = FALSE;
      fw_active = FALSE;
      call TS.in(&inTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
    }
  }


  event void TokenInfo.LocalMsgSent(uint8_t traffic_type){
    if (fw_active){
      if (traffic_type == 0){ //Class 0 is a unreliable MSG
        call TS.out(&outTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
      }
#ifdef CLASS_1
        //call TS.out(&outTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
      if (traffic_type == 1){ //Class 1 is a reliable high-rate  MSG
        call Rate.startOneShot(evaluateReportRate());    
      }
#endif
      if (traffic_type == 2){ //Class 1 is a reliable low-rate   MSG
        call TS.out(&outTkn, FALSE, TL_LOCAL, RAM_TS, (tuple *) &TokenMsg);
      }
    }
    else{
      insert_Token=TRUE;
    }
  }


  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint16_t, uint16_t, uint8_t[TUPLE_MSG_PAYLOAD_SIZE]> *rec;


    PROCESS_OP(inTkn,
               rec = (tuple<uint8_t, uint16_t, uint16_t,
                      uint8_t[TUPLE_MSG_PAYLOAD_SIZE]>
                      *) call TS.nextTuple(operationId, iterator);
	       if (rec != NULL){
      	         call TS.nextTuple(operationId,iterator);
	         insert_Token = TRUE;
	       });
         
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }


  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, 
				   TLTarget_t target,  
                      		   TLTupleSpace_t ts,
				   tuple* returningTuple){
				
  }
  
 
#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
