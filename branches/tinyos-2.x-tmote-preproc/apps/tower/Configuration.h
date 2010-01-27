/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 1025 $
 * * DATE
 * *    $LastChangedDate: 2010-01-15 09:31:19 -0600 (Fri, 15 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Configuration.h 1025 2010-01-15 15:31:19Z mceriotti $
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
#include "TLConf.h"

/**
 * Definition of configuration parameters for Torre Aquila.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#ifndef TOWER_CONF_H
#define TOWER_CONF_H

// Period for sending node status info (in mins)
#define MONITOR_PERIOD 4

/* Vibration node configuration */

// The size of RAM buffers to store acceleration data,
// for 12 bits readings, it must be an even multiple of 3, 
// best performance if this is a multiple of the bytes in the msg
// payload
#define VIBR_BLOCK_SIZE 150 

// Average rate of message generation 
#define MIN_VIBR_REPORT_INTERVAL 1000

/* Data Dissemination configuration */

// The length of the queue of the dissemination requests at the sink
#define DISS_SINK_QUEUE_LEN 3

// The time before the dissemination of a tuple at the sink (in ms)
#define TUPLE_DISSEMINATION_WAIT_TIME 1000

// The size (in bytes) of the payload of the tuples disseminated
#define TUPLE_DISS_PAYLOAD_SIZE 26


/* Data Collection configuration */

// The period at which the tree is built (in minutes), used only in the case
// of a sink node which actively builds the tree.
#define TREE_REBUILDING_PERIOD 18

// The size (in bytes) of the payload of the tuples collected along the tree
#define TUPLE_MSG_PAYLOAD_SIZE 26

// The maximum number of retries for message recovery
#define MAX_RECOVERY_RETRIES 5

// LPL local setting along reliable (delivering class 1 traffic)
// and unreliable paths  
#define LPL_RELIABLE_PATH REMOTE_LPL_INTERVAL
#define LPL_UNRELIABLE_PATH REMOTE_LPL_INTERVAL

// The cost of an unreliable path to the root of the collecting tree
#define CONGESTED_PATH 0xFFFF

// Average rate of message generation for class I 
#ifdef TEST_VIBR
#define MIN_CLASS_1_REPORT_INTERVAL 100
#define MAX_CLASS_1_REPORT_INTERVAL 1000
#else
#define MIN_CLASS_1_REPORT_INTERVAL 1000
#define MAX_CLASS_1_REPORT_INTERVAL 5000
#endif


// Window size for reliable paths (in units of MAX_CLASS_1_REPORT_INTERVAL)
#define RELIABLE_WINDOW 2

// The delay before reconsidering the parent after a transmission
// failure (in ms). The actual delay is in the range [UNRELREC_DELAY/2,
// UNRELREC_DELAY] on the node where the transmission failure happened; 
// [UNRELREC_DELAY + UNRELREC_DELAY/2, 2*UNRELREC_DELAY] on the other 
// nodes in the subtree.
#define UNRELREC_DELAY 1000

// Evaluation of the cost of a single hop in the routing tree.
// The cost is 1 when the LQI value is greater than MAX_ROUTING_LQI; 
// every ROUTING_COST_UNIT, an increment of 1 is added to the cost of the link; 
// when the LQI value is smaller than MIN_RELIABLE_LINK_LQI, the cost 
// equals UNRELIABLE_LINK.
#define MAX_ROUTING_LQI 110
#define ROUTING_COST_UNIT 5
#define MIN_RELIABLE_LINK_LQI 0
#define UNRELIABLE_LINK 40

// The delay (in ms) before forwarding messages to both build the tree and
// notify unreliable paths. The actual value is in the interval 
// [MIN_FW_BACKOFF, MAX_FW_BACKOFF]
#define MIN_FW_BACKOFF 100
#define MAX_FW_BACKOFF 300

// The size of the cache (in number of tuples) at each node used to
// recover tuples lost
#define CACHE_SIZE 10

// The number of children that sent data whose information are kept in
// history
#define CHILDREN_HISTORY_SIZE MAX_NEIGHBORS

#endif
