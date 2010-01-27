/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 944 $
 * * DATE
 * *    $LastChangedDate: 2009-11-25 09:23:31 +0100 (Wed, 25 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TeenyLimeC.nc 944 2009-11-25 08:23:31Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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

/**
 * 
 * @author Gianalberto Chini
 * <a href="mailto:gianalberto.chini@gmail.com">gianalberto.chini@gmail.com</a>
 * 
 */

#include "Timer.h"
#include "TupleSpace.h"
#include "Constants.h"
#include "PostureDetection.h"


module PostureDetectionP {
  uses {
    interface Boot;
    interface Timer<TMilli> as HorizDetectTimer;		
    interface Timer<TMilli> as ImmobilityCheckTimer;
    interface Timer<TMilli> as VoltageCheckTimer;

    interface Leds as LedsDebug;
    interface Leds as LedsMessages;

    interface Accelerometer as AccSensor;
    interface Read<uint16_t> as Voltage;
    
    interface TLObjects;
    interface TupleSpace as TS;

    interface Orchestrator;
  }
}

implementation {

  // Used to send the tuple used get the data from the 
  //   accelerometer component. The data is getted at fist 
  //   call of the VoltageCheckTimer timer
  bool timeStarted;

  // TUPLE SPACE variables in IDs  ----------------------
  TLOpId_t startTimerTupleId;
  TLOpId_t fallTupleId;
  TLOpId_t immobilityTupleId;
  TLOpId_t fwOut;

  // VOLTAGE managing variables  ----------------------
  uint16_t actualVoltage;
  uint16_t buffVoltage[2];
  uint8_t indexBufferVoltage;

  // CIRCULAR BUFFER variables  ----------------------

  /* In this declaration is defined the structure
     (circular buffer) used to store the history
     of the sampling.

     USING AND MANAGING THE CIRCULAR BUFFER:
     The circular buffer is filled by a Sensing Timer tick
     when the sampling phase fills the buffer the variable
     "nextElement" is updated only after that all the sample
     are collected.
     Is possible use the circular buffer (in reading) without
     inconsistency in the data avoiding the reading of the
     successive position of the cell of the buffer poined
     by "nextElement" variable.
   */

  uint8_t nextElement;
  uint8_t actualElement;


  uint16_t historyBufferX[SIZE_HISTROY_BUFFER];
  uint16_t historyBufferY[SIZE_HISTROY_BUFFER];
  uint16_t historyBufferZ[SIZE_HISTROY_BUFFER];

  uint16_t sampleX;
  uint16_t sampleY;
  uint16_t sampleZ;

  // HORIZZONTAL DETECTION variables  ----------------------
  int16_t horizCounterTests;
  bool isHorizzontal;

  // FALL DETECTION variables  ----------------------
  bool fallDetected;
  uint32_t timeFall;


  // IMMOBILITY DETECTION variables  ----------------------
  uint16_t immMinStripX;
  uint16_t immMaxStripX;

  uint16_t immMinStripY;
  uint16_t immMaxStripY;

  uint16_t immMinStripZ;
  uint16_t immMaxStripZ;

  // COME BACK TO A REGULAR POSITION AFTER A FALL  ----------------------
  bool horizPosAfterFall;

  //----------------- LOCAL FUNCTIONS ----------------------		

  int32_t normSquared(uint16_t x, uint16_t y, uint16_t z){
    int32_t xs=x;
    int32_t ys=y;
    int32_t zs=z;
    xs=xs-VX_AT_0G;		
    ys=ys-VY_AT_0G;	
    zs=zs-VZ_AT_0G;
    return xs*xs+ys*ys+zs*zs;
  }		

  uint16_t median(uint16_t a, uint16_t b, uint16_t c){
    if (((b<=a)&&(c>=a)) || ((c<=a)&&(b>=a))) {
      return a;		
    }
    if (((a<=b)&&(c>=b)) || ((c<=b)&&(a>=b))) {
      return b;		
    }
    if (((b<=c)&&(a>=c)) || ((a<=c)&&(b>=c))) {
      return c;		
    }
    return a;
  }

  uint8_t indexPrevElement(uint8_t indexElement, uint8_t nPrec){
    nPrec = nPrec % SIZE_HISTROY_BUFFER;

    if (indexElement>=nPrec){
      return indexElement-nPrec;
    } else {
      nPrec=nPrec-indexElement;
      return SIZE_HISTROY_BUFFER-nPrec;
    }
  }


  void notify(uint8_t typeOfMessage){
    tuple<uint8_t, uint8_t> fallTuple;
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwTuple;

    fallTuple = newTuple(actualField(POSTURE_TUPLE),
                         actualField(typeOfMessage));

    fwTuple = newTuple(actualField(FORWARD_TUPLE), actualField(TOS_NODE_ID), 
                       actualField(call Orchestrator.getNextSeqNumber()),
                       actualField(MY_TYPE), arrayField());
    call TLObjects.copy_tuple((tuple *) fwTuple.fwPayload_field, 
              (tuple *) &fallTuple);

    call TS.out(&fwOut, TRUE, TL_LOCAL, RAM_TS, (tuple *) &fwTuple);  
  }

  //----------------- BOOT AND TL MANAGING ----------------------		

  event void Boot.booted(){
    uint8_t i;
    uint32_t app;
    
    // Fall detection initializzation
    timeStarted=FALSE;
    fallDetected=FALSE;

    // Normal position after fall initializzation    
    horizPosAfterFall=FALSE;

    // Set the actual voltage
    indexBufferVoltage=0;
    call Voltage.read();

    // Init buffer		
    nextElement=0;
    actualElement=SIZE_HISTROY_BUFFER-1;
    for (i=0;i<SIZE_HISTROY_BUFFER;i++){
      app=V_REF_MEASURE; app=(app*VX_AT_0G)/actualVoltage;		
      historyBufferX[i]=(uint16_t)app;
      app=V_REF_MEASURE; app=(app*VY_AT_0G)/actualVoltage;		
      historyBufferY[i]=(uint16_t)app;
      app=V_REF_MEASURE; app=(app*VZ_AT_0G)/actualVoltage;		
      historyBufferZ[i]=(uint16_t)app;
    }

    // Horizzontal detection initialization
    horizCounterTests=HORIZ_POSITIVE_LIMIT;
    isHorizzontal=FALSE;

    // Immobility detection initialization
    immMinStripX=30000;
    immMaxStripX=0;

    immMinStripY=30000;
    immMaxStripY=0;

    immMinStripZ=30000;
    immMaxStripZ=0;

    // Starting voltage timers
    call VoltageCheckTimer.startPeriodic(VOLT_PERIOD_CHECK);
  }	

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    ;
  }

  event void TS.operationCompleted(uint8_t completionCode, 
      TLOpId_t operationId, 
      TLTarget_t target,  
      TLTupleSpace_t ts,
      tuple* returningTuple) {
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }	

  //----------------- VOLTAGE MANAGING ----------------------		

  event void VoltageCheckTimer.fired() {
    tuple<uint8_t,uint8_t,uint16_t[2]> startTimerTuple;		
    indexBufferVoltage=0;
    call Voltage.read();

    //Here is started the reading of the data by the accelerometer 
    if (!timeStarted){
      timeStarted=TRUE;
      //Starting the others timer
      call HorizDetectTimer.startPeriodic(HORIZ_TEST_PERIOD);
      call ImmobilityCheckTimer.startPeriodic(IMM_PERIOD_CHECK); 

      //Read the data from accelerometer
      startTimerTuple = newTuple(actualField(ACCEL_ID),actualField(call AccSensor.getId()),arrayField());
      startTimerTuple.value2[0]=0;		
      startTimerTuple.value2[1]=SAMPLING_PERIOD;		
      call TS.out(&startTimerTupleId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &startTimerTuple	);	
    }	
  }

  event void Voltage.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS){
      return;
    }

    if (indexBufferVoltage<2){
      buffVoltage[indexBufferVoltage]=data;
      indexBufferVoltage++;
      call Voltage.read();
    } else {	
      actualVoltage=median(buffVoltage[0],buffVoltage[1],data);
    }
  }

  //----------------- SAMPLE FORM ACCELEROMETER READY ----------------------		

  event void AccSensor.accelReady(uint16_t X, uint16_t Y, uint16_t Z){
    uint32_t app;
    uint16_t medianX;
    uint16_t medianY;  	
    uint16_t medianZ;	

    //Fill circular buffer and scale the values returned
    //	by accelerometer in function of the actual voltage


    app=V_REF_MEASURE; app=(app*X)/actualVoltage;		
    historyBufferX[nextElement]=(uint16_t)app;

    app=V_REF_MEASURE; app=(app*Y)/actualVoltage;
    historyBufferY[nextElement]=(uint16_t)app;

    app=V_REF_MEASURE; app=(app*Z)/actualVoltage;	
    historyBufferZ[nextElement]=(uint16_t)app;

    medianX=median(historyBufferX[nextElement], historyBufferX[actualElement], historyBufferX[indexPrevElement(actualElement,1)]);
    medianY=median(historyBufferY[nextElement], historyBufferY[actualElement], historyBufferY[indexPrevElement(actualElement,1)]);
    medianZ=median(historyBufferZ[nextElement], historyBufferZ[actualElement], historyBufferZ[indexPrevElement(actualElement,1)]);

    actualElement=nextElement;
    if ((nextElement+1)<SIZE_HISTROY_BUFFER) {
      nextElement++;
    } else {
      nextElement=0;
    }	 	

    //Fall detection part
    if ((!fallDetected)&&(normSquared(medianX,medianY,medianZ)>FALL_2G_SQUARED)){
      call LedsDebug.led2On();      
      fallDetected=TRUE;
      timeFall=call ImmobilityCheckTimer.getNow();
    }
    if ((fallDetected)&&
        ((timeFall+FALL_TIME_CHECK_POS_AFTER_FALL)<call ImmobilityCheckTimer.getNow())
       ){
      fallDetected=FALSE;
      call LedsDebug.led2Off();
      if (isHorizzontal){
        notify(FALL_OCCURED);
        call LedsMessages.led0Toggle();
        horizPosAfterFall=TRUE;
        call LedsDebug.led0On();
      }      		
    }	
    
    // Come back to a regular position after fall
    if ((horizPosAfterFall)&&(!isHorizzontal)){
      horizPosAfterFall=FALSE;
      notify(REGULAR_POSITION_AFTER_FALL);
      call LedsMessages.led2Toggle();
    }

    //Immobility detection part, max min strip updating
    if (medianX>immMaxStripX){
      immMaxStripX=medianX;
    }
    if (medianX<immMinStripX){
      immMinStripX=medianX;
    }
    if (medianY>immMaxStripY){
      immMaxStripY=medianY;
    }
    if (medianY<immMinStripY){
      immMinStripY=medianY;
    }
    if (medianZ>immMaxStripZ){
      immMaxStripZ=medianZ;
    }
    if (medianZ<immMinStripZ){
      immMinStripZ=medianZ;
    }

  }

  //----------------- TIMER EVENTS FUNCTIONS ----------------------		


  event void HorizDetectTimer.fired() {
    if (
        (historyBufferX[actualElement]<HORIZ_UPPERTHR_X) &&
        (historyBufferX[actualElement]>HORIZ_LOWERTHR_X)
       ) {
      if (horizCounterTests > HORIZ_NEGATIVE_LIMIT) {
        horizCounterTests--;	
      } 
    } else {
      if (horizCounterTests < HORIZ_POSITIVE_LIMIT) {
        horizCounterTests++;	
      }	
    }			

    if (horizCounterTests<=HORIZ_LOWER_TH_ALARM){
      isHorizzontal=TRUE;
      call LedsDebug.led1On();
    } else {	
      isHorizzontal=FALSE;
      call LedsDebug.led1Off();	
    }	
  }


  event void ImmobilityCheckTimer.fired() {
    if (
        ((immMaxStripX-immMinStripX)>IMM_MAX_WIDTH_STRIP)|| 
        ((immMaxStripY-immMinStripY)>IMM_MAX_WIDTH_STRIP)||
        ((immMaxStripZ-immMinStripZ)>IMM_MAX_WIDTH_STRIP)
       ){
      call LedsDebug.led0Off();
      immMinStripX=30000;
      immMaxStripX=0;

      immMinStripY=30000;
      immMaxStripY=0;

      immMinStripZ=30000;
      immMaxStripZ=0;
    } else {
      call LedsDebug.led0On();
      notify(IMMOBILITY_OCCURED);
      call LedsMessages.led1Toggle(); 
    }			
  } 		
}
