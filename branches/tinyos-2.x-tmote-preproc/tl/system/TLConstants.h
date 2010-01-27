/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision:19 $
 * * DATE
 * *    $LastChangedDate:2007-05-03 14:29:53 +0200 (Thu, 03 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy:bronwasser $
 * *
 * *  $Id:TupleSpace.h 19 2007-05-03 12:29:53Z bronwasser $
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
 * User-non-modifiable constants.
 *
 * @author Paolo Costa
 *         <a href="mailto:paolo.costa@polimi.it">paolo.costa@polimi.it</a>
 *
 */

#ifndef TL_CONSTANTS_H
#define TL_CONSTANTS_H

#define NULL_NEIGHBOR_ID TOS_BCAST_ADDR

// To tag tuples with no epoch requirement
#define TIME_UNDEFINED 0

// TeenyLIME internal constants
#define STR_SIZE 2
#define TEENYLIME_SYSTEM_OPERATION 0 // TeenyLimeM relies on this being 0 
#define TEENYLIME_SYSTEM_COMPONENT 0 // TeenyLimeM relies on this being 0
#define TEENYLIME_NULL_OP 0 // TeenyLimeM null operation to burn application-level op id
#define UINT16_MIN 0

// TeenyLIME system codes
enum {
  OP_COMPLETED_OK = 1,
  QUERY_SENT_OK = 2,
  RELIABLE_OP_FAIL = 3,
};

// TeenyLIME exception codes
enum {
  TS_FULL = 1,
};


#endif
