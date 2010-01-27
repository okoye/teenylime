
/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 838 $
 * * DATE
 * *    $LastChangedDate: 2009-05-17 03:52:51 -0500 (Sun, 17 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Constants.h 838 2009-05-17 08:52:51Z mceriotti $
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
 * Definition of constants for data collection tests.
 * 
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 */

#ifndef TEST_CONSTANTS_H
#define TEST_CONSTANTS_H

enum {
  MSG_TYPE = 1,
  DISSEMINATION_TYPE = 2,
  TASK_TYPE = 3,
  DATA_COLLECT_CTRL_TYPE = 4,
  CACHE_TYPE = 5,
  CLASS_1_TYPE = 6,
  CLASS_1_END_SESSION = 7,
  CLASS_2_TYPE = 8,
  CLASS_2_END_SESSION = 9,
  ROUTING_INFO_TYPE_I = 10,
  ROUTING_INFO_TYPE_II = 11
};

enum {
  CLASS_1_TASK = 1,
  CLASS_2_TASK = 2,
  TUNING_TASK = 3
};

enum {
  // Timer granularity (in ms) 
  MINUTE = 1000
};

enum{
  // Constant to represent an infinite operating time for sampling tasks
  INFINITE_OP_TIME = 0xFFFF
};

enum {
  BUILD_A_NEW_TREE = 0,
  DISSEMINATE_A_NEW_TUPLE = 0
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
