/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 173 $
 * * DATE
 * *    $LastChangedDate: 2007-10-31 20:40:56 +0100 (Wed, 31 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TLConf.h 173 2007-10-31 19:40:56Z bronwasser $
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

#ifndef TLCONF_H
#define TLCONF_H

#ifdef CONFIG_A
  #define MAX_FIELDS 3
  #define MAX_TUPLES 10
  #define MAX_RETURN_TUPLES 4
  #define MAX_REACTIONS 4
  #define MAX_PENDING_OPS 1
#endif

#ifdef CONFIG_B
  #define MAX_FIELDS 4
  #define MAX_TUPLES 50
  #define MAX_RETURN_TUPLES 1
  #define MAX_REACTIONS 8
  #define MAX_PENDING_OPS 1
#endif

#ifdef CONFIG_C
  #define MAX_FIELDS 3
  #define MAX_TUPLES 105
  #define MAX_RETURN_TUPLES 25
  #define MAX_REACTIONS 50
  #define MAX_PENDING_OPS 4
#endif

#define DBG_USR1 "paolo"
#define DBG_USR2 "luca"
#define DBG_USR3 "laurens"
#define DBG_ERROR "error"


// The duration of a epoch, which also determines the reaction refresh,
// the node tuple refresh, and operation timeout
//#define EPOCH 4096
#define EPOCH 10096

// The number of EPOCHs before a remote reaction is removed
#define REACTION_LOST_REFRESH 4

// The number of EPOCHs before considering a neighbor lost
#define NEIGHBOR_LOST_REFRESH 4

// The number of tuples in a message
#define MAX_TUPLES_MSG 2

//#define MESSAGE_SCATTERING rand() % 1024
// myrianed:
#define MESSAGE_SCATTERING 1024

// DEBUG
#define check() dbg(DBG_USR1, "Gone through this\n")
#ifndef mydbg
#define mydbg(d, s...) dbg(d, ## s)
#endif

#endif
