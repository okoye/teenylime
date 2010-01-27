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
 * Serial messages.
 * 
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 * 
 */
#ifndef __SERIAL_H
#define __SERIAL_H
#include "Constants.h"

enum {
  AM_SERIAL_MSG = 0x70
};

enum {
  CONTACT_EVENT = 0,
  POSTURE_EVENT,
  BUTTON_EVENT,
  SENSORS_EVENT
};


nx_struct contact_event {
  nx_uint16_t node1; // The originator
  nx_uint16_t node2; // Where the contact was detected
  nx_uint16_t rssi;
};
typedef nx_struct contact_event contact_event_t;


nx_struct posture_event {
  nx_uint8_t posture;
};
typedef nx_struct posture_event posture_event_t;

nx_struct button_event {

};
typedef nx_struct button_event button_event_t;

nx_struct sensors_event {
  nx_uint16_t temperature;
};
typedef nx_struct sensors_event sensors_event_t;

nx_struct serial_msg {
  nx_uint8_t type;
  nx_uint16_t node;
  nx_uint32_t seqNumber;
  nx_union {
    contact_event_t contact;
    posture_event_t posture;
    button_event_t button;
    sensors_event_t sensors;
  } data;
};
typedef nx_struct serial_msg serial_msg_t;

#endif

