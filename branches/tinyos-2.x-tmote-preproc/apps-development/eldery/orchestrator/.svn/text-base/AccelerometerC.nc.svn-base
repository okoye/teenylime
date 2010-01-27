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

/** 
	* This is a general implementation of an Accelerometer
	* interface using TeenyLime. 
	* 
	* This wile wires the components used in AccelerometerP.nc
	*
	* This implementation allows througt TeenyLime to send commands
	* and receive data form Accelerometer.nc
	*
	* --WARNING--: this command are INCOMPLETE and does not cover all
	*		the general cases. 
	*	
	* The commands sended and the data received from TeenyLime's
	* TuppleSpace has a defined format:
	*
	* The ACCEL_ID, ID_CMDx and MAX_PERIODIC_TIMER are defined in 
	*	AccelerometerC.h 
	*
	*	No error message will be provided at the time.
	*
	* COMMANDS:
	*		01) <uint8_t,uint8_t,uint16_t[2]> = <ACCEL_ID, UNIQ_ID, SAMPLING_PERIOD>
					+ used to activate the periodic sampling signaled with event 
	*					sampleReady(AccelSample)[UNIQ_ID]. The SAMPLING_PERIOD parameter is
	*					expressed in milli seconds. The first part (LSB) of the uint32_t
	*					value of the SAMPLING_PERIOD is in SAMPLING_PERIOD[1], the
	*					second (MSB) is in SAMPLING_PERIOD[0].
	*
	*		02) <uint8_t,uint8_t> = <ACCEL_ID, UNIQ_ID>
	*				+ used to stop the periodic sampling signaled with event 
	*					sampleReady(AccelSample)[UNIQ_ID]
	*
	*/

configuration AccelerometerC{
  provides interface Accelerometer[uint8_t id];
}

implementation{
  components LedsC;
  components NoLedsC as led;
  components MainC;
  components AccelerometerP;
  components new VolatileTimerC(NUM_MAX_TIMER) as VTimerC; 
 		
  components AccelDriverC;
 		
  components TeenyLimeC;  
  components TLObjectsParsed;
 		
  AccelerometerP.Leds->led;
  AccelerometerP.Boot->MainC;

  AccelerometerP.Accelerometer = Accelerometer;
  AccelerometerP.VTimer -> VTimerC;
  AccelerometerP.XAxes -> AccelDriverC.AccelReadX;	
  AccelerometerP.YAxes -> AccelDriverC.AccelReadY;
  AccelerometerP.ZAxes -> AccelDriverC.AccelReadZ;		

  AccelerometerP.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  AccelerometerP.TLObjects -> TLObjectsParsed;
}
