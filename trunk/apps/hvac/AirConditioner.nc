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
 * *	$Id: AirConditioner.nc 1 2007-04-27 14:33:25Z lmottola $
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

#include "Constants.h"

includes TupleSpace;
includes AirConditionerControlLaw;

/**
 * Air conditioner controller for the HVAC application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

// To collect readings at the air conditioner used as input to the control law
#define MAX_TEMP_READINGS 8
#define MAX_HUMIDITY_READINGS 8

// A command is executed by an air conditioner for a specific time period
#define CONDITIONER_COMMAND_TIMEOUT 20480

module AirConditioner {

  uses {
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface ConditionerIf;
    interface MutualExclusion;
  }

  provides interface StdControl;
}

implementation {

  TLOpId_t remoteActuationCommand, temperatureReact, 
    humidityReading, airConditioners;
  tuple neighborTuple, commandTuple;
  bool pendingActuation, masterConditioner;
  uint16_t adjustTemperatures[MAX_TEMP_READINGS];
  uint16_t adjustHumidity[MAX_HUMIDITY_READINGS];
  uint16_t airConditionerCommand;
  uint8_t adjustTemperaturesNum, adjustHumidityNum;

  command result_t StdControl.init() {

    // Local neighbor tuple
    neighborTuple = newTuple(3, 
			     actualField_uint16(TOS_LOCAL_ADDRESS), 
			     actualField_uint16(AIR_CONDITIONER), 
			     actualField_uint8(MY_LOCATION_ID));

    // Becomes true in case an actuation has been triggered
    pendingActuation = FALSE;

    // Becomes true in case this device acts as the master in a region 
    masterConditioner = FALSE;

    adjustTemperaturesNum = 0;
    adjustHumidityNum = 0;

    return SUCCESS;
  }

  command result_t StdControl.start() {

    tuple commandTempl;

    // Reaction for temperature values exceeding the user preference
    tuple tempTemplate = newTuple(2, 
				  actualField_uint16(TEMPERATURE_READING), 
				  rangeOutField(USER_PREFERENCE - MAX_DEVIATION_USER_PREF, USER_PREFERENCE + MAX_DEVIATION_USER_PREF ));
    temperatureReact = call TS.addReaction(FALSE, TL_NEIGHBORHOOD, &tempTemplate);

    // Reaction to receive commands coming from nearby air conditioners
    commandTempl = newTuple(1, formalField(TYPE_UINT16_T));
    remoteActuationCommand = call TS.addReaction(FALSE, TL_NEIGHBORHOOD, 
						 &commandTempl);

    // Start aquiring the permit to control actuation in the region
    call MutualExclusion.startRequestCriticalRegion(MY_LOCATION_ID);

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    call TS.removeReaction(temperatureReact);
    call TS.removeReaction(remoteActuationCommand);
    return SUCCESS;
  }

  event result_t MutualExclusion.criticalRegionAquired(uint8_t regionId) {
    masterConditioner = TRUE;
    return SUCCESS;
  }

  event result_t MutualExclusion.lostCriticalRegion(uint8_t regionId) {
    return SUCCESS;
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number) {

    uint8_t i;
    tuple humidityTempl, airConditionersTempl;    

    if (operationId.commandId == temperatureReact.commandId && masterConditioner) {

      // A temperature sensor has registered a reading outside the user preference
      // ...triggering actuation only if acting as the master
      // TODO: Add and remove reactions for non-master nodes
      if (!pendingActuation) {
      
        adjustTemperaturesNum = 0;
	adjustHumidityNum = 0;

        // Querying the humidity sensors 
        humidityTempl = newTuple(2, 
				 actualField_uint16(HUMIDITY_READING), 
				 formalField(TYPE_UINT16_T));
	humidityReading = call TS.rdg (FALSE, TL_NEIGHBORHOOD, &humidityTempl);
        pendingActuation = TRUE;
      }

      // Storing the reading
      adjustTemperatures[adjustTemperaturesNum] = tuples[0].fields[1].value.int16;
      adjustTemperaturesNum++;  

    } else if (operationId.commandId == humidityReading.commandId) {

      if (pendingActuation) {

        // Collect the humidity readings
	for (i=0; i<number && adjustHumidityNum< MAX_HUMIDITY_READINGS; i++) {
	  adjustHumidity[adjustHumidityNum] = tuples[i].fields[1].value.int16;  
	  adjustHumidityNum++;
	}

	// Perform actuation if needed
	if (evaluateAirState(adjustTemperatures, 
			     adjustTemperaturesNum, 
			     adjustHumidity, 
			     adjustHumidityNum, 
			     &airConditionerCommand)) {

	  call ConditionerIf.operate(airConditionerCommand, 
				     CONDITIONER_COMMAND_TIMEOUT);

	  // Prepare a command tuple for nearby air conditioner
	  commandTuple = newTuple(1, actualField_uint16(airConditionerCommand));

	  // Collects the ids of nearby water sprinklers
	  airConditionersTempl = newTuple(3, 
					  formalField(TYPE_UINT16_T), 
					  actualField_uint16(AIR_CONDITIONER), 
					  actualField_uint8(MY_LOCATION_ID));
	  airConditioners = call TS.rdg(FALSE, TL_LOCAL, 
					&airConditionersTempl);

	  // Releasing the master role
	  masterConditioner = FALSE;
	  call MutualExclusion.releaseCriticalRegion(MY_LOCATION_ID);
		  
	} 
	pendingActuation = FALSE;

      } 
    } else if (operationId.commandId == remoteActuationCommand.commandId) {

      if (!pendingActuation) {
        // Remote command received, activating the air conditioner
        call ConditionerIf.operate(tuples[0].fields[0].value.int16, 
				   CONDITIONER_COMMAND_TIMEOUT); 
      }   
    } else {
      dbg (DBG_ERROR, "Unknown tupleReady event\n");
    }
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple(){
    return &neighborTuple;
  }
}
