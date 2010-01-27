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
#include "Accelerometer.h"
#include "Constants.h"
#include "tl_objs.h"

/** 
	* This is a general implementation of an Accelerometer
	* interface using TeenyLime. 
	* 
	* See other dettails in the configuration file 
	* AccelerometerC.nc
	*
	* TODO: Remove the tuple from TS
	*/

module AccelerometerP{
  provides interface Accelerometer[uint8_t id];
  uses interface VolatileTimer as VTimer;
  uses {
    interface Read<uint16_t> as XAxes;
    interface Read<uint16_t> as YAxes;
    interface Read<uint16_t> as ZAxes;
  }
  uses interface Boot;
  uses interface Leds;
  uses interface TLObjects;
  uses interface TupleSpace as TS;
}

implementation{

  // General variables
  uint16_t sampleX;
  uint16_t sampleY;
  uint16_t sampleZ;

  // Associative buffer between Timer's id and Component's id
  bool assBufferValidity[NUM_MAX_TIMER];
  int assBufferidTimer[NUM_MAX_TIMER];		
  uint8_t assBufferid[NUM_MAX_TIMER];
  uint32_t assBufferWaitingTime[NUM_MAX_TIMER];
  uint16_t posMinWaitingTime; // >=NUM_MAX_TIMER if not exists min

  // Managing buffer variables
  uint16_t valueX;
  uint16_t valueY;
  uint16_t valueZ;

  // Tuple space variables in IDs
  TLOpId_t cmdTuple00id;
  TLOpId_t cmdTuple01id;
  TLOpId_t fakeIn;

  //-------------- Internal functions --------------	
  void collectSampledData(){
    valueX=sampleX;
    valueY=sampleY;
    valueZ=sampleZ;
  }

  //-------------- Boot interface --------------	
  event void Boot.booted(){
    int16_t i;

    tuple<uint8_t, uint8_t, uint16_t[2]> cmdTuple00;
    tuple<uint8_t, uint8_t> cmdTuple01;

    TOSH_ASSIGN_PIN(ADC5, 6, 5);
    // Configure acceleration sensor
    TOSH_MAKE_GIO2_OUTPUT();
    TOSH_MAKE_ADC5_OUTPUT();
    // Power up acceleration sensor
    TOSH_SET_GIO2_PIN();
    TOSH_SET_ADC5_PIN();

    posMinWaitingTime = NUM_MAX_TIMER;		

    for	(i=0;i<NUM_MAX_TIMER;i++){
      assBufferValidity[i]=FALSE;
    }

    call XAxes.read();		

    cmdTuple00=newTuple(actualField(ACCEL_ID),dontCare(),dontCare());
    cmdTuple01=newTuple(actualField(ACCEL_ID),dontCare());

    call TS.addReaction(&cmdTuple00id, FALSE, TL_LOCAL, RAM_TS, (tuple *) &cmdTuple00);
    call TS.addReaction(&cmdTuple01id, FALSE, TL_LOCAL, RAM_TS, (tuple *) &cmdTuple01);
  }	

  //-------------- TupleSpace interface --------------

  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator) {
    // Variable declaration		
//    uint32_t samplingPeriod;
//    uint16_t partPeriod[2];	
    int16_t i;	
    int16_t findPosition;
    int idTimer;
    uint32_t dt;
    uint16_t posMinWait; 		

    // Command's tuple declaration
    tuple<uint8_t, uint8_t, uint16_t[2]>* cmdTuple00;
    tuple<uint8_t, uint8_t>* cmdTuple01;


    PROCESS_OP(cmdTuple00id,
      cmdTuple00 = (tuple<uint8_t,uint8_t,uint16_t[2]> *) 
            call TS.nextTuple(operationId, iterator);
      findPosition = NUM_MAX_TIMER + 1;	
      dt = cmdTuple00->value2[0];
      dt = dt << 16;
      dt = dt + cmdTuple00->value2[1];	

      for (i = 0; i < NUM_MAX_TIMER; i++) 
        if (assBufferValidity[i] == FALSE) {
          findPosition=i;
          break;							
        }

      for (;i < NUM_MAX_TIMER; i++) 
        if (assBufferValidity[i] == TRUE && 
            assBufferid[i] == cmdTuple00->value1) {
          call VTimer.resetTask(assBufferidTimer[i], dt);				
          findPosition=NUM_MAX_TIMER;
          break;
        }

      if (findPosition < NUM_MAX_TIMER && 
              (idTimer = call VTimer.addTask(dt)) >= 0) {			
        assBufferValidity[findPosition]=TRUE;
        assBufferidTimer[findPosition]=idTimer;
        assBufferid[findPosition]=cmdTuple00->value1;
        assBufferWaitingTime[findPosition]=dt;
        if (dt < assBufferWaitingTime[posMinWaitingTime] ||
                posMinWaitingTime >= NUM_MAX_TIMER) 
            posMinWaitingTime=findPosition;
       }
       call TS.in(&fakeIn, FALSE, TL_LOCAL, RAM_TS, (tuple *) cmdTuple00);
    );

    PROCESS_OP(cmdTuple01id, 
       cmdTuple01 = (tuple<uint8_t, uint8_t> *) 
            call TS.nextTuple(operationId, iterator);
       for (i = 0; i < NUM_MAX_TIMER; i++) 
         if (assBufferValidity[i] == TRUE && 
             assBufferidTimer[i] == cmdTuple01->value1)
           break;

       if (i < NUM_MAX_TIMER) {
         call VTimer.stopTask(assBufferidTimer[i]);
         assBufferValidity[i] = FALSE;
         posMinWait = NUM_MAX_TIMER;
         for (i = 0; i < NUM_MAX_TIMER; i++)
           if (assBufferValidity[i] == TRUE) {
             posMinWait = i;
           break;			
           }
           
         for (; i < NUM_MAX_TIMER; i++)
           if (assBufferValidity[i] == TRUE &&
               assBufferWaitingTime[i] < assBufferWaitingTime[posMinWait]) 
             posMinWait = i;

         posMinWaitingTime=posMinWait;		
       }
       call TS.in(&fakeIn, FALSE, TL_LOCAL, RAM_TS, (tuple *) cmdTuple01);
    );

    PROCESS_OP(fakeIn,
        while(call TS.nextTuple(operationId, iterator) != NULL);
    );
  }

  event void TS.operationCompleted(uint8_t completionCode, 
      TLOpId_t operationId, 
      TLTarget_t target,  
      TLTupleSpace_t ts,
      tuple* returningTuple) {
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }


  //-------------- Sensor axes interfaces --------------
  event void XAxes.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS){
      return;
    }
    sampleX = data;
    call YAxes.read();
  }

  event void YAxes.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS){
      return;
    }
    sampleY = data;
    call ZAxes.read();
  }

  event void ZAxes.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS){
      return;
    }
    sampleZ = data;
    collectSampledData();
  }


  //-------------- VTimer interface --------------
  event void VTimer.fired(int id){
    int16_t i;
    for (i=0;i<NUM_MAX_TIMER;i++){
      if ((assBufferValidity[i]==TRUE) && (assBufferidTimer[i]==id)){
        break;			
      }
    }
    if (i<NUM_MAX_TIMER){
      if ((i==posMinWaitingTime)||(assBufferWaitingTime[posMinWaitingTime]>MIN_TIME_REFRESH)){
        call XAxes.read();		
      }
      signal Accelerometer.accelReady[assBufferid[i]](valueX,valueY,valueZ);
      assBufferidTimer[i] = call VTimer.addTask(assBufferWaitingTime[i]);
    }
  }

  //-------------- Accelerometer interface --------------
  command uint8_t Accelerometer.getId[uint8_t id](){
    return id;	
  }

  default event void Accelerometer.accelReady[uint8_t id](uint16_t X, uint16_t Y, uint16_t Z){
    ;  
  }
}
