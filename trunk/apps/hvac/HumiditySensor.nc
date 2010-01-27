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
 * *	$Id: HumiditySensor.nc 1 2007-04-27 14:33:25Z lmottola $
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
includes Constants;

/**
 * Humidity sampler for the HVAC application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define EXPIRATION_EPOCHS 5

module HumiditySensor {

  uses {
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface SensorIf;
  }

  provides interface StdControl;
}

implementation {

  tuple capHumidity, neighborTuple;

  command result_t StdControl.init() {
    neighborTuple = newTuple(3, 
			     actualField_uint16(TOS_LOCAL_ADDRESS), 
			     actualField_uint16(HUMIDITY_SENSOR), 
			     actualField_uint8(MY_LOCATION_ID));
    return SUCCESS;
  }

  command result_t StdControl.start() {

    capHumidity = newCapabilityTuple(2, 
				     actualField_uint16(HUMIDITY_READING), 
				     formalField(TYPE_UINT16_T));
    call TS.out(FALSE, TL_LOCAL, &capHumidity);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
  
    call TS.in(FALSE, TL_LOCAL, &capHumidity);
    return SUCCESS;
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {

    call SensorIf.getData();
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number) {
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }

  event result_t SensorIf.dataReady(uint16_t reading) {

    tuple humidityValue = newTuple(2, 
				   actualField_uint16(HUMIDITY_READING), 
				   actualField_uint16(reading));
    setExpireIn(&humidityValue, EXPIRATION_EPOCHS);
    call TS.out(FALSE, TL_LOCAL, &humidityValue);            

    return SUCCESS;
  }
}
