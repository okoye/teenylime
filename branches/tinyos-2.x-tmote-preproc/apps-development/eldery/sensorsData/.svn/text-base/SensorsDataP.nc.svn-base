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
#include "SensorsData.h"


module SensorsDataP {
  uses {
    interface Boot;
    interface Timer<TMilli> as SendMessageTimer;

    interface Leds as LedsDebug;
    interface Leds as LedsMessages;

    interface Read<uint16_t> as Voltage;
    
    interface TLObjects;
    interface TupleSpace as TS;
    
    interface Orchestrator;
  }
}

implementation {

  // TUPLE SPACE variables in IDs  ----------------------
  TLOpId_t startTimerTupleId;
  TLOpId_t fallTupleId;
  TLOpId_t immobilityTupleId;
  TLOpId_t fwOut;

  // VOLTAGE managing variables  ----------------------
  uint16_t actualVoltage;
  
  // BUFFER managing
  uint16_t buffer[2];
  uint8_t indexBuffer;

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

  //----------------- LOCAL FUNCIONS ----------------------		
  void notifyData(){
    tuple<uint8_t, uint16_t> sensorsTuple;
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwTuple;

    
    // Creates tuple to forwards after dara reading
    sensorsTuple = newTuple(actualField(SENSORS_TUPLE),
            actualField(actualVoltage));

    fwTuple = newTuple(actualField(FORWARD_TUPLE), actualField(TOS_NODE_ID), 
                       actualField(call Orchestrator.getNextSeqNumber()),
                       actualField(MY_TYPE), arrayField());
    call TLObjects.copy_tuple((tuple *) fwTuple.fwPayload_field, 
              (tuple *) &sensorsTuple);

    call TS.out(&fwOut, TRUE, TL_LOCAL, RAM_TS, (tuple *) &fwTuple);

  }

  //----------------- BOOT AND TL MANAGING ----------------------		

  event void Boot.booted(){

    // Starting timers
    call SendMessageTimer.startPeriodic(SENSORS_SEND_PERIOD);
  }	

  //------------------ VOLTAGE MANAGING ------------------
  event void Voltage.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS){
      return;
    }

    if (indexBuffer<2){
      buffer[indexBuffer]=data;
      indexBuffer++;
      call Voltage.read();
    } else {	
      actualVoltage=median(buffer[0],buffer[1],data);
      
      //Adds to the chain other reading funcion for other sensors 
      //  or if there are no more data end the chain with notifyData()
      notifyData();
    }
  }

  // -------------- TUPLE SPACE MANAGING ----------------
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


  // ------------- SendMessageTimer interface -------------
  event void SendMessageTimer.fired() {    
    // Reads data from sensors starting from the voltage
    indexBuffer=0;
    call Voltage.read();
  }

}
