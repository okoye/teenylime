/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 319 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:36:17 -0500 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: TimeSyncP.nc 319 2008-03-13 11:36:17Z ben_christian $
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
 
/*
 * Author: Christian Benoni
 *
 * This component provides a modified GlobalTime interface 
 *
 */
#include "TimeSyncStructure.h"

#ifdef PRINTF_SUPPORTTS
#include "printf.h"
#endif

module TimeSyncP {
  provides interface GlobalTime;
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as TimerE;
    interface TupleSpace as TS;
    interface Leds;    
#ifdef PRINTF_SUPPORTTS
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}implementation {
  // Structure to describe the message of tuple
  typedef struct TimeSyncMsg{
    bool validData;
    uint16_t laddress;
    uint16_t rootID;
    uint16_t IrootID;
    uint16_t sendingTime;
    uint16_t seqNumber;
    uint8_t distance;
  }TimeSyncMsg;
  
  enum {
    SIZE_MSG = sizeof(TimeSyncMsg),
  };
  
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
  // It indicate the message to be analyzed
  TimeSyncMsg entryToUpgrade;
  // It indicate the first free position in the ItemSync.localEpochDiff structure
  uint8_t numEntries;
  
  // Array containing the information about the other motes
  TableItem   table[ITEM_NUM];
  
  tuple tupleRequestS;
  tuple tupleToSend;
  
  TLOpId_t outId, rdId, reactionIdS;
  
  // They represent the current state of the mote
  uint8_t distance;
  uint16_t rootID;
  uint16_t seqNumber = 0;
  uint16_t lastSeqNumber; 
  uint8_t waitRootInfo;
  
  // It indicate the local time of the mote
  uint16_t localEpoch = 0;
  
  // Difference between the LocalTime and the GlobalTIme
  int16_t EpochDiff;
  
  // It is used to calculate the frequence to send data
  int8_t countToSend;

  // Used to calculate the delay in transmission
  uint32_t timeToSend;
  uint32_t timeReception;
  uint32_t clockTime;
  // It indicates if the mote is synchronized or not
  bool isGlobalSynced;
  
  // its used for generate timeEvent 
  bool generateEvent;
  uint16_t syncNodeP;
  
  // FUNCTION USED
  void clearItem(int8_t i);
  void clearTable(char c);
  int8_t getIndex(uint16_t ID);
  int8_t getIndexN(uint16_t ID);
  uint16_t getGlobalTime();
  void newItem(TimeSyncMsg *msg);
  void sendDataRitardo(int8_t i,int16_t ritardo,int16_t type);
  void sendLocalTime(char code,uint16_t address);
  void sendStartSync();
  void stopNstartClock();
  void updateItem(TimeSyncMsg *msg);
  void updateTable(TimeSyncMsg *msg);
  void updateTableR(int16_t ritardo);
	
  //---------------------------------------------------------------------------------------------------
  /**
   *	start and configuration of the application
   **/
  //---------------------------------------------------------------------------------------------------
  event void Boot.booted() {
    atomic syncNodeP = 0;
    atomic countToSend =  TOS_NODE_ID % TIMESYNC_RATE;
    atomic entryToUpgrade.validData = FALSE;
    atomic generateEvent = FALSE;
    clearTable('B');
		
    // Tupla for sync data
    atomic tupleToSend = newTuple(7,actualField_char('T'), actualField_uint16(TOS_NODE_ID), actualField_uint16(0),actualField_uint16(0),actualField_uint16(0), actualField_uint16(0), actualField_uint8(0)); 
    tupleRequestS = newTuple(7,formalField(TYPE_CHAR),formalField(TYPE_UINT16_T),formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T), formalField(TYPE_UINT16_T),formalField(TYPE_UINT16_T),formalField(TYPE_UINT8_T));
		
    call TS.addReaction(&reactionIdS, FALSE, TOS_NODE_ID, &tupleRequestS);
    atomic{
      clockTime = EPOCH_RATE_SLEEP;
      call TimerE.start(clockTime);
    }
			
#ifdef PRINTF_SUPPORTTS
    call PrintfControl.start();
#endif
  }

  //---------------------------------------------------------------------------------------------------
  /**
   *	event generated when receiving the tuples
   */
  //---------------------------------------------------------------------------------------------------
  event void TS.tupleReady(TLOpId_t operationId, tuple *tuples, uint8_t number) {
    int8_t i;
    TimeSyncMsg msgR;
    if (number==0) return;
    
    if (opIdCmp(&operationId, &reactionIdS)){
      timeReception = call TimerE.getNow();
      switch (tuples[0].fields[0].value.c){
      case 'S':
      case 'A': 
	msgR.seqNumber = tuples[0].fields[5].value.int16;
	msgR.validData = (msgR.seqNumber != lastSeqNumber);
	if (msgR.validData){
	  if (tuples[0].fields[0].value.c=='S'){
	    msgR.rootID = tuples[0].fields[2].value.int16;
	  }else{
	    atomic{
	      syncNodeP = tuples[0].fields[2].value.int16;
	      if (syncNodeP <= getGlobalTime()) {
		localEpoch = 0;
		EpochDiff = 0;
	      }
	      sendStartSync();
	      call Leds.led0Toggle();
	    }
#ifdef PRINTF_SUPPORTTS
	    printf("START %d\n",syncNodeP);
	    call PrintfFlush.flush();
#endif
	    msgR.rootID = msgR.laddress;
	  }
	  msgR.laddress = tuples[0].fields[1].value.int16;	
	  msgR.IrootID = tuples[0].fields[3].value.int16;
	  msgR.sendingTime = tuples[0].fields[4].value.int16;						
	  msgR.distance = tuples[0].fields[6].value.int8;
	  newItem(&msgR);
#ifdef PRINTF_SUPPORTTS
	//  printf("%d_%dI%d r%d M%d s%d d%d G%d\n",rootID,item.myRootID,msgR.laddress,msgR.rootID,msgR.IrootID ,msgR.seqNumber,msgR.distance,getGlobalTime());
	//  call PrintfFlush.flush();	
#endif 
	}
	break;
      case 'T':
	if (item.myRootID == tuples[0].fields[1].value.int16){
	  if (tuples[0].fields[3].value.int16 != -1){
	    clockTime = EPOCH_RATE_SYNC +((signed int)tuples[0].fields[2].value.int16);
	    if ((isGlobalSynced == FALSE) && (clockTime != EPOCH_RATE_SYNC)){
	      signal GlobalTime.synced();
	      atomic isGlobalSynced = TRUE;	
	    }
	    
	    // Send reply to calculate time trasmission
	    sendLocalTime('R',item.myRootID);
	    updateTableR(-((signed int)tuples[0].fields[2].value.int16));
	  }else{
	    clearTable('E');
	  }
	}
#ifdef PRINTF_SUPPORTTS
	//printf("T R%d I%d r%d _ %d\n",item.myRootID,tuples[0].fields[1].value.int16,tuples[0].fields[2].value.int16,(uint16_t)clockTime);
	//call PrintfFlush.flush();	
#endif
	break;
      case 'R':
	i = getIndex(tuples[0].fields[1].value.int16);
	if (i != -1){
	  table[i].transmissionTime = (timeReception - table[i].transmissionTime) / 2; 
	  table[i].trmTimeValid = TRUE;
	}
#ifdef PRINTF_SUPPORTTS
	//printf("R %d - %d %d_%d_%d\n",tuples[0].fields[1].value.int16,(uint16_t)table[i].transmissionTime,i,table[i].laddress,tuples[0].fields[1].value.int16);
	//call PrintfFlush.flush();	
#endif 	
	break;
      }
      call TS.in(&rdId, FALSE, TOS_NODE_ID, &tuples[0]);
    }
  }
  
  //---------------------------------------------------------------------------------------------------
  //---------------------------------------------------------------------------------------------------
  event void TS.tupleSpaceError(uint8_t errCode, TLOpId_t operationId, TLTarget_t target,  tuple* failedTuple){}
  
  //---------------------------------------------------------------------------------------------------
  //---------------------------------------------------------------------------------------------------
  event void TS.reifyCapabilityTuple(tuple* ct){}
  
  //---------------------------------------------------------------------------------------------------
  /**
   *	increase of the LocalTime and sending of the data (only if necessary)
   **/
  //---------------------------------------------------------------------------------------------------
  async event void TimerE.fired() {
    atomic{
      timeToSend = call TimerE.getNow(); 	
      call TimerE.start(clockTime);
      localEpoch++;		
      if (syncNodeP > getGlobalTime())	{
	if (entryToUpgrade.validData){
	  updateItem(&entryToUpgrade); 
	}
	if (countToSend-- <= 0){
	  sendLocalTime('S',TL_NEIGHBORHOOD);
	  countToSend = TIMESYNC_RATE;
	  if (TOS_NODE_ID == rootID)
	    seqNumber++;
	  else if ((++waitRootInfo) >= TIME_TO_WAIT){
	    clearTable('W');
	    waitRootInfo = 0;
	  }
	}
	if (clockTime != EPOCH_RATE_SYNC) clockTime = EPOCH_RATE_SYNC;
      }else if (clockTime != EPOCH_RATE_SLEEP) clockTime = EPOCH_RATE_SLEEP;
      if (generateEvent == TRUE){
	signal GlobalTime.timeEvent();
      }
    }
    call Leds.led2Toggle();
    #ifdef PRINTF_SUPPORTTS
	printf("E %d D %d - G %d \n",localEpoch,EpochDiff,getGlobalTime());
	call PrintfFlush.flush();	
	#endif 	
 }
 
  /****************************************
   *				UTILITY
   *****************************************/
  //---------------------------------------------------------------------------------------------------
  /**
   * 	it initializes an item of data structure
   * 	@param i indicates the posizion to initialize
   **/
  //---------------------------------------------------------------------------------------------------
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
    atomic isGlobalSynced = FALSE;
    atomic EpochDiff = 0;	
    if (c != 'N'){
      atomic rootID = TOS_NODE_ID;
      atomic item.myRootID = -1;
      atomic lastSeqNumber = seqNumber;
      atomic seqNumber = 1;
      atomic distance = 0;
    }
    for(i = 0; i < ITEM_NUM; ++i)
      clearItem(i);
    atomic numEntries = 0;
    for(i = 0; i < NUM_SYNCED; ++i)
      atomic item.localEpochDiff[i] = 32767;
    atomic waitRootInfo = 0;
#ifdef PRINTF_SUPPORTTS
    if (c != 'N'){
      printf("CLR %c\n",c);
      call PrintfFlush.flush();
    }
#endif 
  }

  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param ID represent the sending mote		
   * 	@return int8_t the position of the data
   **/
  //---------------------------------------------------------------------------------------------------
  int8_t getIndex(uint16_t ID){
    int8_t i;
    for(i=0;i<ITEM_NUM;i++){
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
		
    for(i=0;i<ITEM_NUM;i++){
      if (table[i].laddress != 0){
	if (table[i].laddress == ID){
	  iKey = i;
	}if ((localEpoch-table[i].localEpoch) >= (TIME_TO_CLEAR)){
#ifdef PRINTF_SUPPORTTS
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
    return (localEpoch+EpochDiff);
  }
		
  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param msg represents the data to insert
   **/ 
  //---------------------------------------------------------------------------------------------------
  void newItem(TimeSyncMsg *msg){
    if (msg->laddress == (TOS_NODE_ID-1)){
      if( msg->rootID < rootID ){					
	stopNstartClock();
	clearTable('N'); 	
	
	distance = msg->distance + 1;
	atomic rootID = msg->rootID;
	atomic seqNumber = msg->seqNumber;
	item.myRootID = msg->laddress;	
	
	memcpy(&entryToUpgrade, msg, SIZE_MSG);
	if ((uint32_t)(call TimerE.getNow() - timeToSend )< (uint32_t)EPOCHM ){
	  updateItem(&entryToUpgrade);
	} 
      }else if ((msg->rootID == rootID) && (msg->seqNumber >= seqNumber)){
	if (msg->distance < (distance-1)){
	  stopNstartClock();
	  item.myRootID = msg->laddress;
	  distance = msg->distance + 1;  
	}
	if (item.myRootID == msg->laddress){
	  memcpy(&entryToUpgrade, msg, SIZE_MSG);
	  if ((uint32_t)(call TimerE.getNow() - timeToSend )< (uint32_t)EPOCHM ){
	    updateItem(&entryToUpgrade);
	  } 
	}
      }
    }
    if ((msg->rootID == rootID) && (msg->IrootID == TOS_NODE_ID))
      updateTable(msg); 
  }
	
  //---------------------------------------------------------------------------------------------------
  /**
   * 	it stop and start the clock epoch 
   **/ 
  //---------------------------------------------------------------------------------------------------
  void stopNstartClock(){
    atomic {
    	call TimerE.stop();
    	call TimerE.start(clockTime);
    }
  }
	
  //---------------------------------------------------------------------------------------------------
  /**
   * 	it send the message for synchronize the clock
   * 
   *	@param i represents the index, in the table, of the node
   * 	@param ritardo represents the delay of the node
   * 	@param type represents the type of message 
   **/ 
  //---------------------------------------------------------------------------------------------------
  void sendDataRitardo(int8_t i,int16_t ritardo,int16_t type){
    atomic{
    table[i].trmTimeValid = FALSE;
    table[i].diffTimeClock = 0;
    table[i].numberEntry = 0;
    // Update the tuple data
    tupleToSend.fields[0].value.c = 'T';
    tupleToSend.fields[2].value.int16 = ritardo;
    tupleToSend.fields[3].value.int16 = type;
    table[i].transmissionTime = call TimerE.getNow(); 
    call TS.out(&outId, FALSE, table[i].laddress, &tupleToSend);
  }
 }
  //---------------------------------------------------------------------------------------------------
  /**
   *	it sends the LocalTime
   */
  //---------------------------------------------------------------------------------------------------
  void sendLocalTime(char code,uint16_t address){
    // Update the tuple data
    atomic{
    tupleToSend.fields[0].value.c = code;
    tupleToSend.fields[2].value.int16 = rootID;
    tupleToSend.fields[3].value.int16 = item.myRootID;
    tupleToSend.fields[4].value.int16 = getGlobalTime();
    tupleToSend.fields[5].value.int16 = seqNumber;
    tupleToSend.fields[6].value.int8 = distance;
    call TS.out(&outId, FALSE, address, &tupleToSend);
    }
  }
  
   //---------------------------------------------------------------------------------------------------
  /**
   *	it sends the LocalTime and start synchronization
   */
  //---------------------------------------------------------------------------------------------------
  void sendStartSync(){
    atomic{
      seqNumber = 1;
      lastSeqNumber = 1;	
      tupleToSend.fields[0].value.c = 'A';
      tupleToSend.fields[2].value.int16 = syncNodeP;
      tupleToSend.fields[3].value.int16 = item.myRootID;
      tupleToSend.fields[4].value.int16 = getGlobalTime();
      tupleToSend.fields[5].value.int16 = seqNumber++;
      tupleToSend.fields[6].value.int8 = distance;
      clockTime = EPOCH_RATE_SYNC;
      call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, &tupleToSend);
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
    int8_t i;
    float diff = 0;
    //non analizzo 2 volte lo stesso dato
    msg->validData = FALSE;
    if (msg->seqNumber > seqNumber ){
      waitRootInfo = 0;
      atomic seqNumber = msg->seqNumber;
    }
    atomic EpochDiff = msg->sendingTime - localEpoch;
    item.localEpochDiff[numEntries++] =  EpochDiff;
    if (numEntries >= NUM_SYNCED) numEntries = 0;
    
    for (i=0;i<NUM_SYNCED;i++){
      diff += item.localEpochDiff[i];
    }
    diff = ((diff / (float)(NUM_SYNCED)) - (float)(EpochDiff));
    if ((diff <= DELTA) && (diff >= -DELTA)){
      call Leds.led1On();
    }else{
      if (isGlobalSynced == TRUE){
	 signal GlobalTime.lostSynced();
      }
      atomic isGlobalSynced = FALSE;
      call Leds.led1Off();
    }
   
  }
	
  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param msg represents the data to insert
   * 	the function updates the table containig the information about the motes
   **/ 
  //---------------------------------------------------------------------------------------------------
  void updateTable(TimeSyncMsg *msg){
    int16_t ritardo = 0;
    int8_t i = getIndexN(msg->laddress); 
    
    if (i != -1){
      table[i].localEpoch = localEpoch; 
      if (table[i].laddress == 0){
	table[i].laddress = msg->laddress;
	sendDataRitardo(i,0,0);	
      }
      ritardo = (timeReception - timeToSend) / 2;
      if (abs(ritardo - table[i].lastDiffTimeClock) < TRASMISSION_ERROR_MAX){
	table[i].diffTimeClock += ritardo; 
	table[i].lastDiffTimeClock = ritardo;
	if ((table[i].numberEntry++) >= NUMBER_TO_SEND){
	  ritardo = 0;
	  if (table[i].trmTimeValid){
	    ritardo = table[i].transmissionTime - (table[i].diffTimeClock / table[i].numberEntry);
#ifdef PRINTF_SUPPORTTS
	  //  printf("%d,UT:%d N%d_%d r%d %d\n",i,table[i].laddress,table[i].numberEntry,(int16_t)table[i].diffTimeClock,ritardo,getGlobalTime());
	  //  call PrintfFlush.flush();
#endif 
	  }
	  sendDataRitardo(i,ritardo,0);
	}
      }else{
	//I report to the node that must synchronize again
	sendDataRitardo(i,0,-1);
      }
    }else{
      //I report to the node that must synchronize again
      sendDataRitardo(i,0,-1);
    }
#ifdef PRINTF_SUPPORTTS
  //  printf("%d,UTA:%d r%d %d %d\n",i,msg->laddress,ritardo,(int16_t)table[i].transmissionTime,getGlobalTime());
  //  call PrintfFlush.flush();
#endif 
  }
  //---------------------------------------------------------------------------------------------------
  /**
   * 	@param ritardo represents the delay time
   * 	the function updates the table containig the information about the motes
   **/ 
  //---------------------------------------------------------------------------------------------------
  void updateTableR(int16_t ritardo){
    int8_t i;
    for (i=0;i<ITEM_NUM;i++){
      if ((table[i].laddress != 0) && (table[i].trmTimeValid)){
      	table[i].diffTimeClock += (ritardo * table[i].numberEntry); 
      }
    }
  }
  
  // Interface GlobalTime 
  ////////////////////////////////////////////////////////////////////////////
  /**
   *	@eturn uint16_t the LocalTime
   */
  async command uint16_t GlobalTime.getLocalTime(){
    uint16_t t;
    atomic{ t = localEpoch;}
    return t;
  }
  
  ////////////////////////////////////////////////////////////////////////////
  /**
   * Reads the current global time. 
   * @return SUCCESS if this mote is synchronized, FAIL otherwise.
   */
  async command bool GlobalTime.getGlobalTime(uint16_t *time){ 
    *time = getGlobalTime();
    if (rootID == TOS_NODE_ID)
      return (seqNumber > SEQ_NUMBER);
    else	
      return (isGlobalSynced);
  }
  
  async command void GlobalTime.startTimer(){
    atomic generateEvent = TRUE;
  }
  
  async command void  GlobalTime.stopTimer(){
    atomic generateEvent = FALSE;
  }
  
  async command void  GlobalTime.startSync(uint16_t period){
    atomic syncNodeP = (period + getGlobalTime());
    sendStartSync();
  }
  
#ifdef PRINTF_SUPPORTTS
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}
  
  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

