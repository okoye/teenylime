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

#ifndef TLCONF_H
#define TLCONF_H

#define MAX_REACTIONS 10

// Max number of distributed operations pending... this must be
// less than or equal to the number of outgoing messages in the queue
#define MAX_PENDING_OPS 6  

// Max number of flash operation pending.
#define PERSIST_QUEUE_SIZE 5 

// The duration of a epoch, which also determines the reaction refresh,
// and node tuple refresh
#define EPOCH 5000

// The number of EPOCHs before removing remote information 
// (reactions and neighbor tuples) 
#define REMOTE_LOST_REFRESH 3

// Timeout for remote query operations
#define REMOTE_OP_TIMEOUT 500

// Max number of neighbor in the TeenyLIME system
// (be careful: these are stored as tuples in the main tuple space)
#define MAX_NEIGHBORS 20

// Number of slabs to be used by the memory allocator.
#define SLABS_NUM 10
#define PSLABS_NUM 12

// Size of a single slab. Must be an even number.
#define SLAB_SIZE 150
#define PSLAB_SIZE 4096

// Size for the usage bitmap of a single slab. Must be an even number.
// A maximum of 2^SLAB_BITMAP_SIZE tuples can be accomodated in the slab.
#define SLAB_BITMAP_SIZE 8
#define PSLAB_BITMAP_SIZE 16

//#define FLASH_SYNC_TIME 10000

#endif
