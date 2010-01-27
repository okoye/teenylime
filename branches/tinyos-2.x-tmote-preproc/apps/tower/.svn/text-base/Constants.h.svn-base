
/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 301 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 22:26:54 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Constants.h 301 2008-02-26 20:26:54Z mceriotti $
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
  SAMPLE_TYPE_IDENTIFIER = 1,
  TASK_TYPE = 2,
  TEMP_HUM_LIGHT_TYPE = 3,
  TEMP_LIGHT_TYPE = 4,
  DATA_COLLECT_CTRL_TYPE = 5,
  VIBRATION_TYPE = 6,
  CLASS_1_TYPE = 6,
  NODE_INFO_TYPE = 7,
  MSG_TYPE = 8,
  TEMP_HUM_LIGHT_END_SESSION = 9,
  TEMP_LIGHT_END_SESSION = 10,
  VIBRATION_END_SESSION = 11,
  CLASS_1_END_SESSION = 11,
  DISSEMINATION_TYPE = 12,
  DT_TYPE = 13,
  DT_END_SESSION = 14,
  CACHE_TYPE = 15,
  SYNCHRONIZATION_TYPE = 16
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
