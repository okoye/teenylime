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
 * *	$Id: HVAC.nc 1 2007-04-27 14:33:25Z lmottola $
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

includes Constants;

/**
 * Configuration file for a sample HVAC application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define TEMPERATURE_SENS

configuration HVAC {
}

implementation {
  components Main, TimerC, TeenyLimeC, HumiditySensor, TemperatureSensor, 
    SmokeSensor, ADCStub, AirConditioner, ConditionerStub, 
    TokenMutualExclusion, WaterSprinkler, SprinklerStub;

    Main.StdControl -> TimerC.StdControl;
    Main.StdControl -> TeenyLimeC.StdControl;

#ifdef TEMPERATURE_SENS
    Main.StdControl -> TemperatureSensor.StdControl; 
    TemperatureSensor.TS -> TeenyLimeC.TupleSpace[unique("Component")]; 
    TemperatureSensor.SensingTimer -> TimerC.Timer[unique("Timer")];
    TemperatureSensor.TeenyLIMESystem -> TeenyLimeC;
    TemperatureSensor.SensorIf -> ADCStub;
#endif

#ifdef HUMIDITY_SENS
    Main.StdControl -> HumiditySensor.StdControl; 
    HumiditySensor.TS -> TeenyLimeC.TupleSpace[unique("Component")];
    HumiditySensor.TeenyLIMESystem -> TeenyLimeC;
    HumiditySensor.SensorIf -> ADCStub;
#endif

#ifdef SMOKE_SENS
    Main.StdControl -> SmokeSensor.StdControl; 
    SmokeSensor.TS -> TeenyLimeC.TupleSpace[unique("Component")];
    SmokeSensor.TeenyLIMESystem -> TeenyLimeC;
    SmokeSensor.SensorIf -> ADCStub;
#endif

#ifdef AIR_CONDITIONER
    Main.StdControl -> AirConditioner.StdControl; 
    AirConditioner.TS -> TeenyLimeC.TupleSpace[unique("Component")];
    AirConditioner.TeenyLIMESystem -> TeenyLimeC;
    AirConditioner.ConditionerIf -> ConditionerStub;
    AirConditioner.MutualExclusion -> TokenMutualExclusion;
    TokenMutualExclusion.TS -> TeenyLimeC.TupleSpace[unique("Component")];
#endif

#ifdef WATER_SPRINKLER
    Main.StdControl -> WaterSprinkler.StdControl; 
    WaterSprinkler.TS -> TeenyLimeC.TupleSpace[unique("Component")];
    WaterSprinkler.TeenyLIMESystem -> TeenyLimeC;
    WaterSprinkler.SprinklerIf -> SprinklerStub; 
#endif 
}

