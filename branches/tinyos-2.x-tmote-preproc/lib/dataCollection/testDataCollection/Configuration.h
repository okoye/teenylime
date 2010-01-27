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
 * *	$Id: Configuration.h 838 2009-05-17 08:52:51Z mceriotti $
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
#include "TMoteStackConf.h"

/**
 * Definition of configuration parameters for data collection tests.
 * 
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 */

#ifndef TEST_CONF_H
#define TEST_CONF_H

// Period for sending node status info (in mins)
#define MONITOR_PERIOD 60

/* Data Dissemination configuration */

// The size (in bytes) of the payload of the tuples disseminated
#define TUPLE_DISS_PAYLOAD_SIZE 28

/* Data Collection configuration */

// The period at which the tree is built (in minutes), used only in the case
// of a sink node which actively builds the tree.
#define TREE_REBUILDING_PERIOD 180

// The size (in bytes) of the payload of the tuples collected along the tree
#define TUPLE_MSG_PAYLOAD_SIZE 28

// The maximum number of retries for message recovery
#define MAX_RECOVERY_RETRIES 4

// LPL local setting along reliable (delivering class 1 traffic)
// and unreliable paths 
#define LPL_RELIABLE_PATH REMOTE_LPL_INTERVAL
#define LPL_UNRELIABLE_PATH REMOTE_LPL_INTERVAL

// The cost of an unreliable path to the root of the collecting tree
#define CONGESTED_PATH 0xFFFF

// Average rate of message generation for class I 
#define MIN_CLASS_1_REPORT_INTERVAL 1000
#define MAX_CLASS_1_REPORT_INTERVAL 5000

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
#define CACHE_SIZE 20

// The number of children that sent data whose information are kept in
// history
#define CHILDREN_HISTORY_SIZE MAX_NEIGHBORS

#endif
