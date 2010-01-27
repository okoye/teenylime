/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 249 $
 * * DATE
 * *    $LastChangedDate: 2007-12-28 16:33:42 +0100 (Fri, 28 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TLConf.h 249 2007-12-28 15:33:42Z mceriotti $
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

#define MAX_FIELDS 2
#define MAX_TUPLES 25
#define MAX_RETURN_TUPLES 2
#define MAX_REACTIONS 4

// Max number of distributed operations pending... this must be
// less than or equal to the number of outgoing messages in the queue
#define MAX_PENDING_OPS 6  

// The duration of a epoch, which also determines the reaction refresh,
// the node tuple refresh, and operation timeout
#define EPOCH 4000

// The number of EPOCHs before a remote reaction is removed
#define REACTION_LOST_REFRESH 3

// The number of EPOCHs before considering a neighbor lost
#define NEIGHBOR_LOST_REFRESH 3

// The number of tuples in a message
#define MAX_TUPLES_MSG 2

// Max number of neighbor in the TeenyLIME system
// (be careful: these are stored as tuples in the main tuple space)
#define MAX_NEIGHBORS 9

#endif
