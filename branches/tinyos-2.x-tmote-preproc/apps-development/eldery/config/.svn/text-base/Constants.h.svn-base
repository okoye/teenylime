/***
 * * PROJECT
 * *    WildLife Monitoring
 * * VERSION
 * *    $LastChangedRevision: 001 $
 * * DATE
 * *    $LastChangedDate: 2009-11-17 10:29:04 +0200 (mar, 17 nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy:  $
 * *
 * *	$Id: TeenyLimeC.nc 843 2009-05-18 08:46:04Z sguna $
 * *
 * *   WildLife Monitoring - project to monitor wild life with
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
 * Constants needed by appliaction
 *  
 * @author Davide Molteni
 *         <a href="mailto:davide.molteni@studenti.unitn.it">davide.molteni@studenti.unitn.it</a>
 */

#ifndef CONSTANTS_H
#define CONSTANTS_H

#define MAX_PAYLOAD_SIZE 20

#define PROXIMITY_POWER 3
#define RSSI_CONTACT_THRESHOLD -75

enum {
  PROXIMITY_EPOCH = 20000,
  PROXIMITY_HALF_EPOCH = (PROXIMITY_EPOCH / 2)
};

enum {
  MSG_BEACON_MOBILE = 1, //beacon sent by node
  MSG_REPLY_MOBILE  = 2, //reply sent by node
  FORWARD_TUPLE, // used by the tree collection
  CONTACT_TUPLE, // marks detection of a contact
  ACCEL_ID, // Used for local call to accelerometer component
  POSTURE_TUPLE, // Used to identify the state of the body
  TREE_BUILDING_MESSAGE, //Identifier of tuple used build the tree   
  ACK_TUPLE,
  BUTTON_TUPLE,
  SENSORS_TUPLE
};


/* posture events */
enum {
  FALL_OCCURED = 0,
  IMMOBILITY_OCCURED = 1,
  REGULAR_POSITION_AFTER_FALL = 2
};

/* A fixed node is used as a link to the sink. Does not run contact detection. */
#define FIXED_NODE 0
/* An anchor node marks a hazard aread. */
#define ANCHOR_NODE 1
/* A mobile node is carried by care-receivers. */
#define MOBILE_NODE 2
#define SINK_NODE 3

#ifdef NO_TYPE 
#error "Please use node-build to compile this program"
#endif

/* Definitions of neighbor tuple fields */
#define address_field value0
#define lqi_field value1
#define rssi_field value2
#define nextAwake_field value3

/* Definitions for the tuple that triggers the tree collection protocol */
#define fwMsgType_field value0
#define fwAddress_field value1
#define fwSeq_field value2
#define fwPrevNodeType_field value3
#define fwPayload_field value4

/* Definitions for the ack tuple*/
#define ackMsgType_field value0
#define ackAddress_field value1
#define ackSeq_field value2

#endif

