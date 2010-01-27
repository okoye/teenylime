/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 856 $
 * * DATE
 * *    $LastChangedDate: 2009-06-03 08:23:36 -0500 (Wed, 03 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TupleMsgHeader.h 856 2009-06-03 13:23:36Z sguna $
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
 * Definition of TMote-specific packet header.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:luca.mottola@polimi.it">luca.mottola@polimi.it</a>
 * 
 */

#ifndef TUPLEMSG_HEADER_H
#define TUPLEMSG_HEADER_H

enum {
  AM_TL_HEADER = 0,
  TUPLE_AM = 1
};

enum TL_operations {
  OUT_OP = 1,
  RD_OP = 2,
  IN_OP = 3,
  RDG_OP = 4,
  ING_OP = 5,
  REACT = 6,
  QUERY_RESULT = 7,
  REACTION_FIRING = 8,
  // These are ctrl commands NOT available trough the TL API
  CTRL_RESET = 9,
  FLASH_INIT,
  FLASH_CLEAR
};

typedef nx_struct TL_header {
  nx_uint8_t tupleNumber;
  nx_uint8_t operation;
  nx_uint8_t commandId;
  nx_uint8_t reliable_componentId;  
  nx_uint8_t fletcher1;
  nx_uint8_t fletcher2;
} TL_header;

#endif //TUPLEMSG_H
