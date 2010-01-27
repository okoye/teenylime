
/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Constants.h 883 2009-07-14 12:51:17Z mceriotti $
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

/**
 * Definition of constants for Torre Aquila.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#ifndef TOWER_CONSTANTS_H
#define TOWER_CONSTANTS_H

enum {
  NODE_INFO_TYPE = 1,
  TEMPERATURE = 2,
  HUMIDITY = 3,
  SOLAR_LIGHT = 4,
  SYNTH_LIGHT = 5,
  ACCELERATION = 6,
  TILT = 7,
  MICROPHONE = 8,
  BUZZER = 9,
  MAGNETIC = 10,
  PRESSURE = 11,
  PRESENCE = 12,
  CO = 13,
  CO2 = 14,
  DUST = 15,
  DATA_COLLECT_CTRL_TYPE = 16,
  MSG_TYPE = 17,
  CLASS_1_TYPE = 18,
  CLASS_1_END_SESSION = 19,
  DISSEMINATION_TYPE = 20,
  TASK_TYPE = 21,
  CACHE_TYPE = 22
};

enum {
  // Timer granularity (in ms) 
  MINUTE = 10000,
  SECOND = 500
};

enum {
  ADXL203 = 1,
  ADXL321 = 2
};

enum{
  // Constant to represent an infinite operating time for sampling tasks
  INFINITE_OP_TIME = 0xFFFF
};

enum {
  BUILD_A_NEW_TREE = 0,
  DISSEMINATE_A_NEW_TUPLE = 0
};

// Identifiers for acceleration axes
enum {
  X_AXIS = 1,
  Y_AXIS = 2,
  Z_AXIS = 3
}; 

// Constants to represent different data collection modes (reliable with
// caching and recovery or unreliable without any recovery mechanism)
enum {
  RELIABLE_DELIVERY = 0,
  UNRELIABLE_DELIVERY = 1,
  MIN_RELIABLE_MSG_ID = 2,
  MAX_RELIABLE_MSG_ID = 0xFFFF
};

#endif
