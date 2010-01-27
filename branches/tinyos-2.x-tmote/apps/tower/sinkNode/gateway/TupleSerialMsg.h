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
 * *	$Id: TupleSerialMsg.h 320 2008-03-13 11:38:54Z ben_christian $
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
 * Definition of the messages sent through serial.
 * 
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 */

#ifndef TUPLE_SERIAL_H
#define TUPLE_SERIAL_H

#include "TupleSpace.h"

typedef nx_union serial_fieldValue {
  nx_uint8_t int8;
  nx_uint16_t int16;
#ifdef FLOAT_SUPPORT
  nx_int32_t flt;
#endif
  nx_uint8_t c;
} serial_fieldValue;

typedef nx_struct serial_field {
  nx_uint8_t type;
  serial_fieldValue value;
} serial_field;

typedef nx_struct serial_tuple {
  nx_uint16_t logicalTime;
  nx_uint16_t expireIn;
  nx_bool capabilityT;
  serial_field fields[MAX_FIELDS];
} serial_tuple;

typedef nx_struct tuple_serial_msg {
  serial_tuple nghTuple;
  serial_tuple tuple;
} tuple_serial_msg_t;

enum {
  AM_TUPLE_SERIAL_MSG = 9,
  WAIT_TIME = 5000, 		
};

#endif /* TUPLE_SERIAL_H */
