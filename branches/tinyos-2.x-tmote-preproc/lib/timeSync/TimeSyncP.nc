/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 862 $
 * * DATE
 * *    $LastChangedDate: 2009-06-18 09:25:32 -0500 (Thu, 18 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TimeSyncP.nc 862 2009-06-18 14:25:32Z lmottola $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU Lesser General Public License
 * *   as published by the Free Software Foundation; either version 2
 * *   of the License, or (at your option) any later version.
 * *
 * *   This program is distributed in the hope that it will be useful,
 * *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 * *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * *   GNU General Public License for more details.
 * *
 * *   You should have received a copy of the GNU General Public License
 * *   along with this program; if not, you may find a copy at the FSF web
 * *   site at 'www.gnu.org' or 'www.fsf.org', or you may write to the
 * *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * *   Boston, MA  02111-1307, USA
 ***/

#include "TLConf.h"
#include "TMoteStackConf.h"
#include "TimeSynchConf.h"

#ifdef PRINTF_SUPPORT_TIME_SYNCH
#include "printf.h"
#endif

/*
 * Author: Christian Benoni
 *
 * This component provides a modified GlobalTime interface 
 *
 */

// The minimum sequence number to consider the root node synchronized,
// avoids startup effects
/* #define MINIMUM_SEQ_NUMBER 5 */

module TimeSyncP {

  provides interface GlobalTime;

  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as EpochTimer;
    interface TupleSpace as TS;
    interface Tuning;
    interface Leds;    

#ifdef PRINTF_SUPPORT_TIME_SYNCH
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  // Structure to describe the message of tuple
  typedef struct TimeSyncMsg{
    bool validData;
    uint16_t laddress;
    uint16_t rootID;
    uint16_t IrootID;
    uint16_t sendingTime;
    uint16_t seqNumber;
    uint8_t distance;
  } TimeSyncMsg;
  
  // Structure to describe the state of the motes in the neighbourhood
  typedef struct TableItem{
    uint16_t laddress;
    uint16_t localEpoch;
    int32_t diffTimeClock;
    uint8_t numberEntry;
    int16_t lastDiffTimeClock;
    uint32_t transmissionTime;
    bool trmTimeValid;
  }TableItem;
  
  // Structure used for synchronization
  typedef struct ItemSync{
    int16_t myRootID;
    int16_t localEpochDiff[NUM_SYNCED];
  }ItemSync;  
  ItemSync item;

  // It indicates the message to be analyzed
  TimeSyncMsg entryToUpgrade;

  // It indicates the first free position in the 
  // ItemSync.localEpochDiff structure
  uint8_t numEntries;
  
  // Array containing the information about the other motes
  TableItem table[MAX_NEIGHBORS];
  
  tuple<char, uint16_t, uint16_t, uint16_t, 
    uint16_t, uint16_t, uint8_t> tupleToSend;
  
  TLOpId_t inId, reactionIdS;
  
  // They represent the current state of the mote
  uint8_t distance;
  uint16_t seqNumber;
  uint16_t lastSeqNumber; 
  uint8_t waitRootInfo;
  
  // It indicate the local time of the mote
  uint16_t localEpoch;
  
  // Difference between the LocalTime and the GlobalTime
  int16_t epochDiff;

  // Information on the current root
  uint16_t rootID;
/*   uint16_t rootEpochRate; */
  uint16_t rootTargetPeriod;

  // It is used to calculate the frequence to send data
  int8_t countToSend;

  // Used to calculate the delay in transmission
  uint32_t timeToSend;
  uint32_t timeReception;
  uint32_t clockTime;

  bool syncInProgress = FALSE;
  uint16_t lplSleepInterval = LOCAL_LPL_INTERVAL;

/*   // It indicates if the mote is synchronized or not */
/*   bool isGlobalSynced; */
  
  // its used for generate timeEvent 
  bool generateEvent;
  
  // Forward declarations
  void clearItem(int8_t i);
  void clearTable(char c);
  int8_t getIndex(uint16_t ID);
  int8_t getIndexN(uint16_t ID);
  uint16_t getGlobalTime();
  void newItem(TimeSyncMsg *msg);
  void sendDataDelay(int8_t i,int16_t ritardo,int16_t type);
  void sendLocalTime(char code,uint16_t address);
  void sendStartSync();
  void stopNstartClock();
  void updateItem(TimeSyncMsg *msg);
  void updateTable(TimeSyncMsg *msg);
  void updateTableDelay(int16_t delay);
	
  void initData() {
    atomic { 
      localEpoch = 0;
      seqNumber = 0;
      rootTargetPeriod = 0;
      countToSend =  TL_LOCAL % TIMESYNC_RATE;
      entryToUpgrade.validData = FALSE;
      generateEvent = FALSE;
    }    

    clearTable('B');

    atomic{
      clockTime = EPOCH_RATE;
      stopNstartClock();
/*       call EpochTimer.start(clockTime); */
    }
  }

  event void Boot.booted() {

    tuple<char, uint16_t, uint16_t, uint16_t, 
      uint16_t, uint16_t, uint8_t> reactionPattern;

    reactionPattern = newTuple(dontCare(),
			     dontCare(),
			     dontCare(), 
			     dontCare(),
			     dontCare(), 
			     dontCare(),
			     dontCare());
		
    call TS.addReaction(&reactionIdS, FALSE, 
			TL_LOCAL, RAM_TS, (tuple *) &reactionPattern);
		
    // Synch data tuple
    atomic {
      tupleToSend = newTuple(
			     actualField('T'), 
			     actualField(TL_LOCAL), 
			     actualField(0),
			     actualField(0),
			     actualField(0), 
			     actualField(0), 
			     actualField(0));
    }

    initData();
  }

  // To avoid asynch calls
  task void removeLPL() {
    // Make sure LPL does not interfere with synchronization
    lplSleepInterval = call Tuning.get(KEY_LOCAL_LPL_SLEEP);
    call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, 0);    
  }

  void prepareForSynch() {
    
    seqNumber = 1;
    lastSeqNumber = 1;
    post removeLPL();
  }

  void analyzeTuples(tuple<char, uint16_t, uint16_t, 
		     uint16_t, uint16_t, uint16_t, uint8_t> *rcv ){
    int8_t i;
    TimeSyncMsg msgR; 

    timeReception = call EpochTimer.getNow();

    switch (rcv->value0){
      // 'A' indicates a start synch command being received
      // 'S' indicates an update message, 
      // possibly used to identify the synchronization root
    case 'S':
    case 'A':
      msgR.seqNumber = rcv->value5;
      msgR.validData = (msgR.seqNumber != lastSeqNumber);
      if (msgR.validData){
	if (rcv->value0 == 'S'){
	  msgR.rootID = rcv->value2; 
	  msgR.IrootID = rcv->value3; 
	} else {

	  syncInProgress = TRUE;
	  atomic {
	    rootTargetPeriod = rcv->value2; 
/* 	    rootEpochRate = rcv->value3;  */
	    if (rootTargetPeriod <= getGlobalTime()) { 
	      localEpoch = 0;
	      epochDiff = 0;
	    }
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	    printf("ST:P%dG%dS%dL%d\n",rootTargetPeriod, getGlobalTime(),
		   msgR.seqNumber, lastSeqNumber);
#endif
	    prepareForSynch();
	    
#ifndef LEAF_NODE	    
	    sendStartSync();
#endif
	    call Leds.led2Toggle();
	  }
	  msgR.rootID = rcv->value1;
	  msgR.IrootID = -1;
	}
	msgR.laddress = rcv->value1;
	msgR.sendingTime = rcv->value4; 
	msgR.distance = rcv->value6; 
	newItem(&msgR);

#ifdef PRINTF_SUPPORT_TIME_SYNCH
/* 	printf("%d_%dI%d r%d M%d s%d d%d G%d\n",rootID,item.myRootID, */
/* 	       msgR.laddress,msgR.rootID,msgR.IrootID, */
/* 	       msgR.seqNumber,msgR.distance,getGlobalTime()); */
	call PrintfFlush.flush();
#endif
      }
      break;

    case 'T':
      if (item.myRootID == rcv->value1) { 
	if (rcv->value3 != -1){
/* 	  clockTime = rootEpochRate + ((signed int) rcv->value2); */
	  clockTime = EPOCH_RATE + ((signed int) rcv->value2);
/* 	  if (isGlobalSynced == FALSE  */
/* 	      && clockTime != EPOCH_RATE){ */
/* 	    signal GlobalTime.synced(); */
/* 	    atomic isGlobalSynced = TRUE;	 */
/* 	  } */
	  // Send reply to calculate trasmission time
	  sendLocalTime('R',item.myRootID);
	  updateTableDelay(-((signed int) rcv->value2));
	} else {
	  clearTable('E');
	}
      }

#ifdef PRINTF_SUPPORT_TIME_SYNCH
      printf("T R%d I%d r%d _ %d\n",item.myRootID,
	     rcv->value1,rcv->value2,(uint16_t)clockTime);
      call PrintfFlush.flush();	
#endif
      break;

    case 'R':
      i = getIndex(rcv->value1);
      if (i != -1){
	table[i].transmissionTime = (timeReception 
				     - table[i].transmissionTime) / 2; 
	table[i].trmTimeValid = TRUE;
      }
#ifdef PRINTF_SUPPORT_TIME_SYNCH
      printf("R %d - %d %d_%d\n",rcv->value1,(uint16_t)table[i].transmissionTime,
	     i,table[i].laddress);
      call PrintfFlush.flush();	
#endif 	
      break;
    }
    call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *) rcv); 
  }
  
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {

     tuple<char, uint16_t, uint16_t, uint16_t, 
       uint16_t, uint16_t, uint8_t> *rcv; 
     rcv = (tuple<char, uint16_t, uint16_t, uint16_t, 
	    uint16_t, uint16_t, uint8_t> *) call TS.nextTuple(operationId, iterator);

     if (rcv == NULL) {
#ifdef PRINTF_SUPPORT_TIME_SYNCH
       printf("ERROR analyzeTuples\n");
       call PrintfFlush.flush();
#endif
       return;
     }

     PROCESS_OP(reactionIdS,
		analyzeTuples(rcv);
		);  
     
     PROCESS_OP(inId,
		if (rcv != NULL)
		  call TS.nextTuple(operationId, iterator);
		);
  }
    
  // To avoid asynch calls
  task void resumeLPL() {
    call Tuning.setImmediate(KEY_LOCAL_LPL_SLEEP, lplSleepInterval);
  }

  // Increase of the LocalTime and sending of the data (only if necessary)
  async event void EpochTimer.fired() {

    atomic{

      timeToSend = call EpochTimer.getNow(); 	
      call EpochTimer.start(clockTime);
      localEpoch++;
		
      if (rootTargetPeriod >= getGlobalTime())	{

	if (entryToUpgrade.validData){
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	  printf ("C\n");
#endif
	  updateItem(&entryToUpgrade); 
	}
	
	if (countToSend-- <= 0){
	  sendLocalTime('S',TL_NEIGHBORHOOD);
	  countToSend = TIMESYNC_RATE;
	  if (rootID == TL_LOCAL) {
	    seqNumber++;
	  } /* else if ((++waitRootInfo) >=  */
/* 		     (uint8_t)(TIME_TO_CLEAR / TIMESYNC_RATE)){ */
/* 	    clearTable('W'); */
/* 	    waitRootInfo = 0; -> Already in clearTable()*/
/* 	  } */
	}
	
	clockTime = EPOCH_RATE;
	/* 	if (clockTime != rootEpochRate) {  */
	/* 	  clockTime = rootEpochRate;  */
	/* 	} */
	/*       } else if (clockTime != EPOCH_RATE){ */
      } else {
	clockTime = EPOCH_RATE;
      }
      
      // Synchronization period ends
      if (rootTargetPeriod < getGlobalTime()) {
	waitRootInfo++;
	if (rootID != TL_LOCAL
	    && waitRootInfo >= (uint8_t)(TIME_TO_CLEAR)) {
	  rootTargetPeriod = 0;
	  clearTable('W');
	  syncInProgress = FALSE;
	  post resumeLPL();
	} else if (rootID == TL_LOCAL 
	    && waitRootInfo >= (uint8_t)(TIME_TO_CLEAR)) {
	  syncInProgress = FALSE;
	  post resumeLPL();
	}
      }

      if (generateEvent == TRUE 
	  && getGlobalTime() % TIME_EVENT_MULTIPLIER == 0){
	call Leds.led0Toggle();
	signal GlobalTime.timeEvent();
      }
    }

#ifdef PRINTF_SUPPORT_TIME_SYNCH
    printf("E%dD%dG%dS%dL%d\n",localEpoch, epochDiff, getGlobalTime(),
	   seqNumber,lastSeqNumber);
    call PrintfFlush.flush();	
#endif 	
  }

  void clearItem(int8_t i){

    atomic {
      table[i].trmTimeValid = FALSE;
      table[i].laddress = 0;
      table[i].diffTimeClock = 0;
      table[i].numberEntry = 0;
      table[i].lastDiffTimeClock = 0;
      table[i].transmissionTime = 0;
    }
  }

  //---------------------------------------------------------------------------------------------------
  /**
   *	it initializes the data structure
   * 	@param c indicates the calling state
   * 		  'B' boot, 'N' new root, 'W' wait, 'C' check of the neighbours				
   */
  //---------------------------------------------------------------------------------------------------
  void clearTable(char c){

    int8_t i;

    atomic {
/*       isGlobalSynced = FALSE; */
      if (c != 'W') {
	epochDiff = 0;	
      }
      if (c != 'N'){
	rootID = TL_LOCAL;
	item.myRootID = -1;
/* 	lastSeqNumber = seqNumber;  */
	lastSeqNumber = 0;
	seqNumber = 1;
	distance = 0;
      }
      for(i = 0; i < MAX_NEIGHBORS; ++i) {
	clearItem(i);
      }
      numEntries = 0;
      for(i = 0; i < NUM_SYNCED; ++i) {
	item.localEpochDiff[i] = 32767; // XXXXXX ?
      }
      waitRootInfo = 0;
#ifdef PRINTF_SUPPORT_TIME_SYNCH
      if (c != 'N'){
	printf("CLR %c\n",c);
	call PrintfFlush.flush();
      }
#endif 
    }
  }

  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param ID represent the sending mote		
   * 	@return int8_t the position of the data
   **/
  //---------------------------------------------------------------------------------------------------
  int8_t getIndex(uint16_t ID){
    int8_t i;
    for(i=0;i<MAX_NEIGHBORS;i++){
      if (table[i].laddress == ID)
	return i;
    }
    return -1;
  }
	
  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param ID represent the sending mote		
   * 	@return int8_t the position in which insert the data, or the position of the old data
   **/
  //---------------------------------------------------------------------------------------------------
  int8_t getIndexN(uint16_t ID){
    int8_t i;
    int8_t iEmptyp = -1;
    int8_t iKey = -1;
		
    for(i=0;i<MAX_NEIGHBORS;i++){
      if (table[i].laddress != 0){
	if (table[i].laddress == ID){
	  iKey = i;
	}if ((localEpoch-table[i].localEpoch) >= (TIME_TO_CLEAR)){
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	  printf("C%d\n",table[i].laddress);
	  call PrintfFlush.flush();
#endif 
	  clearItem(i);
	  if(iEmptyp == -1) iEmptyp = i;	
	}
      }else if (iEmptyp == -1){
	iEmptyp = i;
      } 
    }
    if (iKey != -1)
      return iKey;
    return iEmptyp;
  }

  //---------------------------------------------------------------------------------------------------
  /**
   * 	@return GlobalTime
   **/ 
  //---------------------------------------------------------------------------------------------------
  uint16_t getGlobalTime(){
    atomic {
      return localEpoch+epochDiff;
    }
  }
		
  void newItem(TimeSyncMsg *msg){

    atomic {
    //if (msg->laddress == (TL_LOCAL-1)){ XXXXXXXXXXXXX ???

      if(msg->rootID < rootID){				
	
	stopNstartClock();
	clearTable('N'); 	
	
	distance = msg->distance + 1;
	rootID = msg->rootID;
	seqNumber = msg->seqNumber;
	item.myRootID = msg->laddress;	
	
	memcpy(&entryToUpgrade, msg, sizeof(TimeSyncMsg));
	if ((uint32_t)(call EpochTimer.getNow() - timeToSend) 
/* 	    < (uint32_t)(rootEpochRate/2)){ */
	    < (uint32_t)(EPOCH_RATE/2)){
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	  printf("A\n");
#endif
	  updateItem(&entryToUpgrade);
	} 
      } else if (msg->rootID == rootID 
		 && msg->seqNumber >= seqNumber){
	if (msg->distance < distance-1){
	  stopNstartClock();
	  item.myRootID = msg->laddress;
	  distance = msg->distance + 1;  
	}
	if (item.myRootID == msg->laddress){
	  memcpy(&entryToUpgrade, msg, sizeof(TimeSyncMsg));
	  if ((uint32_t)(call EpochTimer.getNow() - timeToSend) 
/* 	      < (uint32_t)(rootEpochRate/2)){ */
	      < (uint32_t)(EPOCH_RATE/2)){
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	    printf("B\n");
#endif
	    updateItem(&entryToUpgrade);
	  } 
	}
      }
    }
      //}
    if ((msg->rootID == rootID) && (msg->IrootID == TL_LOCAL))
      updateTable(msg); 
  }

  // Stop and start the epoch timer 
  void stopNstartClock(){
    atomic {
    	call EpochTimer.stop();
    	call EpochTimer.start(clockTime);
    }
  }
	
  /**
   * 	Send the message to synchronize the clock
   * 
   *	@param i represents the index, in the table, of the node
   * 	@param delay represents the delay of the node
   * 	@param type represents the type of message 
   **/ 
  void sendDataDelay(int8_t i,int16_t delay, int16_t type){

    TLOpId_t outId;

    atomic{
      table[i].trmTimeValid = FALSE;
      table[i].diffTimeClock = 0;
      table[i].numberEntry = 0;
      // Update the tuple data
      tupleToSend.value0 = 'T';
      tupleToSend.value2 = delay;
      tupleToSend.value3 = type;
      table[i].transmissionTime = call EpochTimer.getNow(); 
      call Leds.led1Toggle();
      call TS.out(&outId, FALSE, table[i].laddress, RAM_TS, (tuple *) &tupleToSend);
    }
  }

  // Sends the LocalTime - task to avoid asynch calls
  norace uint16_t destinationAddress;
  task void sendLocalTupe() {
    TLOpId_t outId;
    call TS.out(&outId, FALSE, destinationAddress, RAM_TS, (tuple *) &tupleToSend);
  }

  void sendLocalTime(char code,uint16_t address){

    // Update the tuple data
    atomic{
      tupleToSend.value0 = code;
      tupleToSend.value2 = rootID;
      tupleToSend.value3 = item.myRootID;
      tupleToSend.value4 = getGlobalTime();
      tupleToSend.value5 = seqNumber;
      tupleToSend.value6 = distance;
      destinationAddress = address;   
      post sendLocalTupe();
      call Leds.led1Toggle();
    }
  }

  // Send the LocalTime and start synchronization
  void sendStartSync(){

/*     TLOpId_t outId; */

    atomic{

/*       seqNumber = 1; */
/*       lastSeqNumber = 1; */
      tupleToSend.value0 = 'A';
      tupleToSend.value2 = rootTargetPeriod;
/*       tupleToSend.value3 = rootEpochRate; //item.myRootID; */
      tupleToSend.value4 = getGlobalTime();
      tupleToSend.value5 = seqNumber++;
      tupleToSend.value6 = distance;
      clockTime = EPOCH_RATE;

      destinationAddress = TL_NEIGHBORHOOD;   
      post sendLocalTupe();

      call Leds.led2Toggle();

/*       call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, (tuple *) &tupleToSend); */
    }
    stopNstartClock();
  }
	
  //---------------------------------------------------------------------------------------------------
  /**
   *  it update the information of the time of the node
   *  @param msg represents the new data
   **/
  //---------------------------------------------------------------------------------------------------
  void updateItem(TimeSyncMsg *msg){

/*     int8_t i; */
/*     float diff = 0; */

    atomic {
      msg->validData = FALSE;
      if (msg->seqNumber > seqNumber){
	waitRootInfo = 0;
	seqNumber = msg->seqNumber;
      }
      epochDiff = msg->sendingTime - localEpoch;
      item.localEpochDiff[numEntries++] =  epochDiff;
      if (numEntries >= NUM_SYNCED) {
	numEntries = 0;
      }
      
/*       for (i=0;i<NUM_SYNCED;i++){ */
/* 	diff += item.localEpochDiff[i]; */
/*       } */
      
/*       diff = ((diff / (float)(NUM_SYNCED)) - (float)(epochDiff)); */
/*       if ((diff <= DELTA) && (diff >= -DELTA)){ */
/* 	//call Leds.led1On(); */
/*       } else { */
/* 	if (isGlobalSynced == TRUE){ */
/* 	  signal GlobalTime.lostSynced(); */
/* 	} */
/* 	atomic isGlobalSynced = FALSE; */
	//call Leds.led1Off();
/*       } */
    }
  }
	
  void updateTable(TimeSyncMsg *msg){

    int16_t currentDelay = 0;
    int8_t i = getIndexN(msg->laddress); 
    
    if (i != -1){
      table[i].localEpoch = localEpoch; 
      if (table[i].laddress == 0){
	table[i].laddress = msg->laddress;
	sendDataDelay(i,0,0);	
      }
      currentDelay = (timeReception - timeToSend) / 2;
      if (abs(currentDelay - table[i].lastDiffTimeClock) < TRASMISSION_ERROR_MAX){
	table[i].diffTimeClock += currentDelay; 
	table[i].lastDiffTimeClock = currentDelay;
	if ((table[i].numberEntry++) >= MIN_TIME_READINGS){
	  currentDelay = 0;
	  if (table[i].trmTimeValid){
	    currentDelay = table[i].transmissionTime - 
	      (table[i].diffTimeClock / table[i].numberEntry);
#ifdef PRINTF_SUPPORT_TIME_SYNCH
	    printf("%d,UT:%d N%d_%d r%d %d\n",i,table[i].laddress,
		   table[i].numberEntry,(int16_t)table[i].diffTimeClock,
		   currentDelay,getGlobalTime());
	    call PrintfFlush.flush();
#endif 
	  }
	  sendDataDelay(i,currentDelay,0);
	}
      } else {
	// Report to the node that it must synchronize again
	sendDataDelay(i,0,-1);
      }
    } else {
      // Report to the node that it must synchronize again
      sendDataDelay(i,0,-1);
    }

#ifdef PRINTF_SUPPORT_TIME_SYNCH
    printf("%d,UTA:%d r%d %d %d\n",i,msg->laddress,currentDelay,
	   (int16_t)table[i].transmissionTime,getGlobalTime());
    call PrintfFlush.flush();
#endif 
  }

  void updateTableDelay(int16_t delay){
    int8_t i;
    for (i=0;i<MAX_NEIGHBORS;i++){
      if (table[i].laddress != 0 && 
	  table[i].trmTimeValid){
      	table[i].diffTimeClock += (delay * table[i].numberEntry); 
      }
    }
  }
  
  async command uint16_t GlobalTime.getLocalTime(){
    atomic { return localEpoch; } 
  }
  
/*   /\** */
/*    * Reads the current global time.  */
/*    * @return SUCCESS if this mote is synchronized, FAIL otherwise. */
/*    *\/ */
/*   async command bool GlobalTime.getGlobalTime(uint16_t *time){  */
/*     *time = getGlobalTime(); */
/*     if (rootID == TL_LOCAL) */
/*       return (seqNumber > MINIMUM_SEQ_NUMBER); */
/*     else	 */
/*       return (isGlobalSynced); */
/*   } */

  /**
   * Reads the current global time. 
   * @return SUCCESS if this mote is synchronized, FAIL otherwise.
   */
  async command uint16_t GlobalTime.getGlobalTime(){ 
    return getGlobalTime();
  }
  
  async command void GlobalTime.startTimer(){
    atomic generateEvent = TRUE;
  }
  
  async command void  GlobalTime.stopTimer(){
    atomic generateEvent = FALSE;
  }
  
  async command void  GlobalTime.startSync(){
    atomic {
      if (!syncInProgress) {
	syncInProgress = TRUE;
	rootTargetPeriod = SYNCH_PERIOD + getGlobalTime();
	prepareForSynch();
	sendStartSync();
      }
    }
  }
  
  event void TS.operationCompleted(uint8_t completionCode, 
				   TLOpId_t operationId, TLTarget_t target, 
				   TLTupleSpace_t ts,
				   tuple* returningTuple){
  }  

  event void TS.reifyCapabilityTuple(tuple* ct){}

  event void Tuning.setDone(uint8_t key, uint16_t value) {}

#ifdef PRINTF_SUPPORT_TIME_SYNCH
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}
  
  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

