/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 746 $
 * * DATE
 * *    $LastChangedDate: 2009-02-28 18:46:44 +0100 (Sat, 28 Feb 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TupleMsgHeader.h 746 2009-02-28 17:46:44Z lmottola $
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
 * Definition of tossim specific packet header.
 * 
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
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
  CTRL_RESET = 9
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
