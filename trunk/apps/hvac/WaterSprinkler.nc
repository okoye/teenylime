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
 * *	$Id: WaterSprinkler.nc 1 2007-04-27 14:33:25Z lmottola $
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

includes SprinklerControlLaw;

/**
 * Water sprinkler controller for the HVAC application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

// To collect readings at the water sprinkler used as input to the control law
#define MAX_TEMP_READINGS 8
#define MAX_SMOKE_READINGS 8

// A command is executed by the water sprinkler for a specific time period
#define SPRINKLER_COMMAND_TIMEOUT 20480

module WaterSprinkler {

  uses {
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface SprinklerIf;
  }

  provides interface StdControl;
}

implementation {

  TLOpId_t temperatureReact, smokeReading, 
    waterSprinklers, remoteActuationCommand;
  tuple neighborTuple, commandTuple;
  uint16_t dangerTemperatures[MAX_TEMP_READINGS];
  uint16_t dangerSmoke[MAX_SMOKE_READINGS];
  uint8_t dangerTemperaturesNum, dangerSmokeNum;
  bool pendingActuation;
	         
  command result_t StdControl.init() {

    // Local neighbor tuple
    neighborTuple = newTuple(3, 
			     actualField_uint16(TOS_LOCAL_ADDRESS), 
			     actualField_uint16(SPRINKLER_ACTUATOR), 
			     actualField_uint8(MY_LOCATION_ID));
    
    // Becomes true in case an actuation has been triggered
    pendingActuation = FALSE;

    dangerTemperaturesNum = 0;
    dangerSmokeNum = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {

    tuple commandTempl;
 
    // Reaction for temperature values above the safety threshold
    tuple tempTemplate = newTuple(2, 
				  actualField_uint16(TEMPERATURE_READING), 
				  greaterField(TEMPERATURE_SAFETY));
    temperatureReact = call TS.addReaction(TRUE, TL_NEIGHBORHOOD, &tempTemplate);

    // Reaction to receive commands coming from nearby water sprinklers
    commandTempl = newTuple(1, formalField(TYPE_UINT16_T));
    remoteActuationCommand = call TS.addReaction(FALSE, TL_LOCAL, &commandTempl);
    return SUCCESS;
  }

  command result_t StdControl.stop() {

    call TS.removeReaction(temperatureReact);
    call TS.removeReaction(remoteActuationCommand);
    return SUCCESS;
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number) {
    
    tuple smokeTempl, waterSprinklersTempl;
    uint8_t i;
    uint16_t sprinklerCommand;

    if (operationId.commandId == temperatureReact.commandId) {

      // A temperature sensor has registered a reading above the safety value
      if (!pendingActuation) {
      
        // Querying the smoke sensors 
        dangerTemperaturesNum = 0;
	dangerSmokeNum = 0;
        smokeTempl = newTuple(2, 
			      actualField_uint16(SMOKE_READING), 
			      formalField(TYPE_UINT16_T));
	smokeReading = call TS.rdg (TRUE, TL_NEIGHBORHOOD, &smokeTempl);
        pendingActuation = TRUE;
      }

      // Storing the reading
      dangerTemperatures[dangerTemperaturesNum] = tuples[0].fields[1].value.int16;
      dangerTemperaturesNum++;
      
    } else if (operationId.commandId == smokeReading.commandId) {

      if (pendingActuation) {
	
        // Collect the smoke readings
	for (i=0; i<number && dangerSmokeNum< MAX_SMOKE_READINGS; i++) {
	  dangerSmoke[dangerSmokeNum]	= tuples[i].fields[1].value.int16;
	  dangerSmokeNum++;  
	}

	// Perform actuation if needed
	if (evaluateFireState(dangerTemperatures, dangerTemperaturesNum, 
			      dangerSmoke, dangerSmokeNum, &sprinklerCommand)) {
	  call SprinklerIf.operate(sprinklerCommand, SPRINKLER_COMMAND_TIMEOUT);

	  // Prepare a command tuple for nearby water sprinklers
	  commandTuple = newTuple(1, actualField_uint16(sprinklerCommand));

	  // Collects the ids of nearby water sprinklers
	  waterSprinklersTempl = newTuple(3, 
					  formalField(TYPE_UINT16_T), 
					  actualField_uint16(SPRINKLER_ACTUATOR), 
					  actualField_uint8(MY_LOCATION_ID));
	  waterSprinklers = call TS.rdg(FALSE, TL_LOCAL, &waterSprinklersTempl);
	} else {
	  pendingActuation = FALSE;
	}
      } 
    } else if (operationId.commandId == waterSprinklers.commandId) {

      if (pendingActuation) {

	// Operating nearby water sprinklers
	for (i=0; i < number; i++) {
	  call TS.out(TRUE, tuples[i].fields[1].value.int16, &commandTuple);
	}
	pendingActuation = FALSE;
      }
    } else if (operationId.commandId == remoteActuationCommand.commandId) {

      if (!pendingActuation) {
        // Remote command received, activating the sprinkler
        call SprinklerIf.operate(tuples[0].fields[0].value.int16, 
				 SPRINKLER_COMMAND_TIMEOUT); 
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
