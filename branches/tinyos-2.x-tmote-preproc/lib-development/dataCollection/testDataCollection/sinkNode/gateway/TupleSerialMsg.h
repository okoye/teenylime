/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 785 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 05:50:15 -0500 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleSerialMsg.h 785 2009-04-29 10:50:15Z mceriotti $
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

#include "Constants.h"
#include "tl_objs.h"

typedef struct tuple_serial_msg {
  nx_uint8_t data[TUPLE_MSG_DATA_SIZE];
} tuple_serial_msg_t;

enum {
  AM_TUPLE_SERIAL_MSG = 9,
};

#endif /* TUPLE_SERIAL_H */
