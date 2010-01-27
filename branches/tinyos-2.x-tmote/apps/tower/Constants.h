/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 320 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:38:54 -0500 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: Constants.h 320 2008-03-13 11:38:54Z ben_christian $
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

// Constant to represent a single reading in a period
#define INSTANT 0

// Timer granularity (in ms) 
#define MINUTE 30000

// Constant to represent an infinite operating time for sampling tasks
#define INFINITE_OP_TIME 0xFFFF

enum {
  ROUND_TYPE = 1,
  TASK_TYPE = 2,
  TEMP_DEFORM_TYPE = 3,
  DATA_COLLECT_CTRL_TYPE = 4,
  VIBRATION_TYPE = 5,
  NODE_INFO_TYPE = 6
};

// The duration of a round (in ms)
#define ROUND 10000

// Period for sending node status info (in mins)
#define MONITOR_PERIOD 4

/* Temperature Node configuration */ 

// The period (T) for temperature tasks (in mins)
#define TEMP_PERIOD 1

// The operating time (O) for temperature tasks (in mins)
#define TEMP_OP_TIME INFINITE_OP_TIME


/* Vibration Node configuration */

// The period (T) for accel tasks (in mins)
#define VIBRATION_PERIOD 10

// The operating time (O) for acceleration tasks (in mins)
#define VIBRATION_OP_TIME INFINITE_OP_TIME

// The sampling rate (R) for acceleration tasks (in Hz)
#define VIBRATION_RATE 200

// The sampling duration (S) for acceleration tasks (in secs)
#define VIBRATION_SAMPLING 30


/* Data Dissemination configuration */

#define NUM_DISSEMINATION_CLASSES 2

#define DISSEMINATION_CLASSES {TEMP_DEFORM_TYPE, VIBRATION_TYPE}


/* Data Collection configuration */

// The upper limit on the number of hops in the collecting tree
#define UNRELIABLE_PATH 0xFFFF

// The duration of the tree once built (in mins)
#define TREE_TIMEOUT 13

// The interval between tree building rounds (in mins)
#define TREE_REFRESH 4

// The min LQI value below which the cost of the link is UNRELIABLE_PATH
#define MIN_ROUTING_LQI 85

// The min LQI value below which the cost of the link is UNRELIABLE_LINK
#define MIN_RELIABLE_LINK_LQI 90

// The LQI value above which the cost of the link is 0
#define MAX_ROUTING_LQI 110

// The levels in which the interval between MIN_RELIABLE_LINK_LQI and
// MAX_ROUTING_LQI is divided
#define LEVELS_LQI 4

// The cost of a link with a lqi value worse than MIN_RELIABLE_LINK_LQI
#define UNRELIABLE_LINK 8

// The timeout for the local notification of a refreshed parent information
// The timeout evaluation: OFFSET + (rand16()%RAND_INTERVAL)
#define PARENT_NOTIFICATION_OFFSET 1000
#define PARENT_NOTIFICATION_RAND_INTERVAL 5000

// The timeout for the forwarding of a refreshed parent information
// The timeout evaluation: OFFSET + (rand16()%RAND_INTERVAL)
#define PARENT_FORWARDING_OFFSET 500
#define PARENT_FORWARDING_RAND_INTERVAL 500

// The length of the queue of collected data at the sink
#define SINK_QUEUE_LEN 30

// The length of the queue of collected task at the sink
#define TASK_SINK_QUEUE_LEN 3
#endif
