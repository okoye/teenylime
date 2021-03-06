/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 13 $
 * * DATE
 * *    $LastChangedDate: 2007-05-02 17:02:26 -0500 (Wed, 02 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: paolinux78 $
 * *
 * *	$Id: TLConf.h 13 2007-05-02 22:02:26Z paolinux78 $
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

// Max number of fields in a tuple
#define MAX_FIELDS 4 // FIXME era 2

// Max number of tuples in the local tuple space
#define MAX_TUPLES 4

// The max number of tuples returned for any distributed operation
#define MAX_RETURN_TUPLES 2

// Max number of reactions (both local and distributed)
#define MAX_REACTIONS 2

// Max number of distributed pending operations (both local and distributed)
#define MAX_PENDING_OPS 2

// The duration of a epoch, which also determines the reaction refresh,
// the node tuple refresh, and operation timeout
#define EPOCH 4096 

// The number of EPOCHs before a remote reaction is removed
#define REACTION_LOST_REFRESH 4

// The number of EPOCHs before considering a neighbor lost
#define NEIGHBOR_LOST_REFRESH 4

// The number of tuples in a message
#define MAX_TUPLES_MSG 1

// DEBUG
#define check() dbg(DBG_USR1, "Gone through this\n")
#define mydbg(m, f, s...) dbg(m, "[%s] " f, currentTime(), ## s)

#endif
