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
 * *	$Id: TemperatureSensor.nc 1 2007-04-27 14:33:25Z lmottola $
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

/**
 * Temperature sampler.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define SENSING_TIMER 4096
#define TEMPERATURE_SENSOR 1
#define TEMPERATURE_READING 1

module TemperatureSensor {

  uses {
    interface Timer as SensingTimer;
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface SensorIf;
    interface Leds;
  }

  provides interface StdControl;
}

implementation {
 
  tuple neighborTuple;
  TLOpId_t query_id;

  command result_t StdControl.init() {
    neighborTuple = newTuple(2, 
			     actualField_uint16(TOS_LOCAL_ADDRESS), 
			     actualField_uint16(TEMPERATURE_SENSOR));
    return SUCCESS;
  }

  command result_t StdControl.start() {
     call SensingTimer.start(TIMER_REPEAT, SENSING_TIMER);	
     return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call SensingTimer.stop ();
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
  }

  event result_t SensingTimer.fired() {
     return call SensorIf.getData();
  }

  event result_t SensorIf.dataReady(uint16_t reading) {

    tuple tempValue = newTuple(2, 
			       actualField_uint16(TEMPERATURE_READING), 
			       actualField_uint16(reading));
    call TS.out(FALSE, TL_LOCAL, &tempValue);            
    call Leds.greenToggle();
    return SUCCESS;
  }
}
