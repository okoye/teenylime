/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 1 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 09:33:25 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: Tracking.nc 1 2007-04-27 14:33:25Z lmottola $
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

includes TupleSpace;
includes TupleMsg;

/**
 * Tracking module.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define MAGNETO_REFRESH 5120
#define OBJECT_THRESHOLD 256
#define MAX_READINGS 8 

module Tracking {

  uses {
    interface TupleSpace as TS;
    interface MagnetoMeter;
    interface Timer as SensingTimer;
    interface Timer as TrackingTimer;
  }

  provides interface StdControl;
}

implementation {

  tuple neighborReadings[MAX_READINGS], neighborsTempl;
  uint8_t numberReadings;
  bool pendingMeasurement;
  TLOpId_t readingsOp;

  command result_t StdControl.init() {

    pendingMeasurement = FALSE;
    neighborsTempl = newTuple(4, 
			      formalField(TYPE_UINT16_T), 
			      formalField(TYPE_UINT16_T), 
			      formalField(TYPE_UINT16_T), 
			      formalField(TYPE_UINT16_T));
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call SensingTimer.start(TIMER_REPEAT, MAGNETO_REFRESH);
  }

  command result_t StdControl.stop() {
    return call SensingTimer.stop();
  }
  
  float calculateMediumCoordinate(uint16_t a, uint16_t b) {
    if (a>b) return ((a-b)/2)+b;
    else return ((b-a)/2)+a;
  }
  
  void execAlgorithm (float* objectX, float* objectY, 
		      uint16_t c, uint16_t d, 
		      float* objectR, uint16_t s) {

	  float e = c - *objectX; // Difference in x coordinates
	  float f = d - *objectY; // Difference in y coordinates
	  float p = sqrt(pow(e,2) + pow(f,2)); // Distance between centers
	  float k = (pow(p,2) + pow(*objectR,2) - pow(s,2))/(2*p); 

	  // Joining points of intersection
	  float x_1 = *objectX + e*k/p + (f/p)*sqrt(pow(*objectR,2) - pow(k,2));
	  float y_1 = *objectY + f*k/p - (e/p)*sqrt(pow(*objectR,2) - pow(k,2));
	  float x_2 = *objectX + e*k/p - (f/p)*sqrt(pow(*objectR,2) - pow(k,2));
	  float y_2 = *objectY + f*k/p + (e/p)*sqrt(pow(*objectR,2) - pow(k,2));

	  // Adjusting the object position
	  *objectX=calculateMediumCoordinate(x_1,x_2);
	  *objectY=calculateMediumCoordinate(y_1,y_2);
	  *objectR=sqrt(pow((x_1-x_2),2)+pow((y_1-y_2),2));
  }

  void initPosition (tuple* tuples, uint8_t number, 
		     float* objectX, float* objectY, float* objectR) {
    
    uint8_t i;

    for (i = 0; i < number; i++) {                  
      if (tuples[i].fields[0].value.int16 == TOS_LOCAL_ADDRESS) {
        *objectX = tuples[i].fields[1].value.int16;
        *objectY = tuples[i].fields[2].value.int16;
      }              	
    }  
    for (i = 0; i < numberReadings; i++) {                  
      if (tuples[i].fields[0].value.int16 == TOS_LOCAL_ADDRESS) {
        *objectR = tuples[i].fields[1].value.int16;
      }
    }  
  } 
  
  bool findReading(uint16_t addr, uint16_t* reading) {

    uint8_t i;
    for (i = 0; i < numberReadings; i++) {
      if (neighborReadings[i].fields[0].value.int16 == addr) {
        *reading = neighborReadings[i].fields[1].value.int16;
        return TRUE;
      }
    }
    return FALSE;
  }

  event result_t TS.reifyCapabilityTuple(tuple* t) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number){

    tuple neighbors, messageTuple;
    uint16_t myX = 0;
    uint16_t myY = 0;
    uint16_t reading, maxReading = 0;
    uint8_t i, maxReadingI = 0;
    float objectX, objectY, objectR;

    if (operationId.commandId == readingsOp.commandId) {

      // Saving the readings gathered so far, and check if I'm the leader
      numberReadings = number;
      for (i = 0; i < number; i++) {
        neighborReadings[i] = tuples[i];
        if (neighborReadings[i].fields[1].value.int16 > maxReading) {
          maxReading = neighborReadings[i].fields[1].value.int16;
          maxReadingI = i;
        }        
      }      
      if (maxReadingI != TOS_LOCAL_ADDRESS) {
        // I'm not the leader
        pendingMeasurement = FALSE;
      } else {
        // Reading the TeenyLIME system 
        call TS.rdg(FALSE, TL_LOCAL, &neighbors);
      }	
    } else {

      // I'm the leader, computing the object position
      initPosition (tuples, number, &objectX, &objectY, &objectR);
      // Find my coordinates
      for (i = 0; i < number; i++) {                      
        if (tuples[i].fields[0].value.int16 == TOS_LOCAL_ADDRESS) {
          myX = tuples[i].fields[1].value.int16;
          myY = tuples[i].fields[2].value.int16;
        }
      }

      // Evaluate position
      for (i = 0; i < number; i++) {                  
      	if (findReading(tuples[i].fields[0].value.int16, &reading)) {
          execAlgorithm (&objectX, &objectY, 
			 tuples[i].fields[1].value.int16, 
			 tuples[i].fields[2].value.int16, 
			 &objectR, reading); 
	    }
      }       

      // Sending message tuple
      messageTuple = newTuple(6, 
			      actualField_uint16(TOS_LOCAL_ADDRESS), 
			      actualField_uint16(myX), 
			      actualField_uint16(myY), 
			      actualField_float(objectX), 
			      actualField_float(objectY), 
			      actualField_float(objectR));
      call TS.out(FALSE, TL_LOCAL, &messageTuple); 
      pendingMeasurement = FALSE;
    } 
    return SUCCESS;
  }

  event result_t SensingTimer.fired() {  
    call MagnetoMeter.getReading();
    return SUCCESS;
  }  

  event result_t MagnetoMeter.dataReady(uint16_t value) {
  
    tuple trackingObj;    

    if (value > OBJECT_THRESHOLD) {
      pendingMeasurement = TRUE;
      trackingObj = newTuple (2, 
			      actualField_uint16(TOS_LOCAL_ADDRESS), 
			      actualField_uint16(value));
      call TS.out(FALSE, TL_NEIGHBORHOOD, &trackingObj);
      call TrackingTimer.start(TIMER_ONE_SHOT, MAGNETO_REFRESH);                 
    }
    return SUCCESS;    
  }

  event result_t TrackingTimer.fired() {

    // Gathering all the readings received so far
    tuple readings = newTuple(2, 
			      formalField(TYPE_UINT16_T), 
			      formalField(TYPE_UINT16_T));
    readingsOp = call TS.ing (FALSE, TL_LOCAL, &readings);    
    return SUCCESS;
  } 
}
