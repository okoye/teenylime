/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 189 $
 * * DATE
 * *    $LastChangedDate: 2007-11-05 14:07:50 -0600 (Mon, 05 Nov 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TLConf.h 189 2007-11-05 20:07:50Z bronwasser $
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
#define MAX_FIELDS 5 // FIXME era 2

// Size of the memory pool
#define TINYMALLOC_SIZE 2000

// The max number of tuples returned for any query
#define MAX_RETURN_TUPLES 15

// The duration of a epoch, which also determines the reaction refresh,
// the node tuple refresh, and operation timeout
#define EPOCH 8192

// The number of EPOCHs before a remote reaction is removed
#define REACTION_LOST_REFRESH 4

// The number of EPOCHs before considering a neighbor lost
#define NEIGHBOR_LOST_REFRESH 4

// Time out for pending operations (in milliseconds)
#define PENDING_OP_TIME_OUT_MS 800 // max = PENDING_OP_TIMER_PERIOD * 128

// Granularity of the periodic timer for pending operations (milliseconds)
#define PENDING_OP_TIMER_PERIOD 200


// 2 Query method options:

#define GENERIC_QUERIES 0
// Option 1: Do not use generated code. Program binary will be smaller.
// Instead of turning all code generation off at once, code generation can
// be configured on a per tuple format basis in TupleDefs.h
// Generic queries do allow multiple conditions per field, and have no
// special requirements on the order of fields in a query. Queries can be like
// newQuery(q, MY_FMT, 2, eqCond(0,80), eqCond(1,80)) as well as
// newQuery(q, MY_FMT, 2, eqCond(1,80), eqCond(0,80)) as well as
// newQuery(q, MY_FMT, 2, gtCond(0,20), ltCond(0,80))

#define GENERATED_QUERIES 1
// Use generated code. Optimized query code is generated only for those tuples for which
// code generation has not been turned off in TupleDefs.h.
// Optimized queries require all conditions to respect the order of tuple fields:
// newQuery(q, MY_FMT, 2, eqCond(0,80), eqCond(1,80)) is allowed,
// newQuery(q, MY_FMT, 2, eqCond(1,80), eqCond(0,80)) is NOT allowed.
// In addition, only on condition per field is allowed:
// newQuery(q, MY_FMT, 2, gtCond(0,20), ltCond(0,80)) is NOT allowed.

// Select query method:
//#define QUERY_METHOD GENERIC_QUERIES
#define QUERY_METHOD GENERATED_QUERIES

// Most of current MAC protocols do not support varying message buffer lengths.
// They can handle message buffers of size message_t only. For these MAC
// layers, define NO_DYNAMIC_MSG_LEN, and TeenyLimeSerializer will only
// allocate fixed size buffers.
#define NO_DYNAMIC_MSG_LEN

#define PENDING_OP_TIME_OUT ((uint32_t) PENDING_OP_TIME_OUT_MS/PENDING_OP_TIMER_PERIOD)


#endif
