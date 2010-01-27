
/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 892 $
 * * DATE
 * *    $LastChangedDate: 2009-07-23 05:40:57 -0500 (Thu, 23 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Constants.h 892 2009-07-23 10:40:57Z mceriotti $
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

#ifndef TUNNEL_CONSTANTS_H
#define TUNNEL_CONSTANTS_H

enum {
  SAMPLE_TYPE_IDENTIFIER = 1,
  INFO_TYPE_IDENTIFIER = 2,
  TASK_TYPE = 3,
  TEMP_HUM_LIGHT_TYPE = 4,
  TEMP_LIGHT_TYPE = 5,
  DATA_COLLECT_CTRL_TYPE = 6,
  VIBRATION_TYPE = 7,
  CLASS_1_TYPE = 7,
  NODE_INFO_TYPE = 8,
  MSG_TYPE = 9,
  TEMP_HUM_LIGHT_END_SESSION = 10,
  TEMP_LIGHT_END_SESSION = 11,
  VIBRATION_END_SESSION = 12,
  CLASS_1_END_SESSION = 12,
  DISSEMINATION_TYPE = 13,
  DT_TYPE = 14,
  DT_END_SESSION = 15,
  CACHE_TYPE = 16,
  ROUTING_INFO_TYPE_I = 17,
  ROUTING_INFO_TYPE_II = 18,
  TUNING = 19
};

enum{
  SENSORS_STATUS = 1,
  NODE_STATUS = 2,
  BATTERY = 3,
  TEMPERATURE = 4,
  ROUTING_PARENT = 5,
  ROUTING_PARENT_LQI = 6,
  SECURITY = 7,
  AGGREGATED_PERIODIC_INFO = 21
};

enum{
  WORKING_SENSOR = 0,
  READING_FAILURE = 1,
  UNRELIABLE_SENSOR = 2,
  UNRELIABLE_BOARD = 4
};

enum{
  CRITICAL_BATTERY = 1,
  REBOOT = 2,
  SINK_NODE = 4
};

enum {
  VIBRATION_TASK = 1,
  TL_TASK = 2,
  THL_TASK = 3,
  DT_TASK = 4,
  LT_TASK = 5
};

enum {
  // Timer granularity (in ms) 
  MINUTE = 10000
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
