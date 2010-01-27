#ifndef TREEBUILDER_H
#define TREEBUILDER_H

// --- Tree definitions ---

#define PERIOD_TIME_ON PROXIMITY_HALF_EPOCH
#define PERIOD_TIME_OFF PROXIMITY_HALF_EPOCH
#define NODE_EVERY_UP 0xFFFFFFFF

#define PEROIOD_REFRESH 30000

// The cost of an unreliable path to the root of the collecting tree
#define CONGESTED_PATH 0xFFFF

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

#endif