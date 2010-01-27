/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 136 $
 * * DATE
 * *    $LastChangedDate: 2007-10-15 09:26:10 -0500 (Mon, 15 Oct 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MicazTossimStackConf.h 136 2007-10-15 14:26:10Z lmottola $
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

#ifndef MSGQUEUE_H
#define MSGQUEUE_H

// The max number of TOS messages waiting to be transmitted
#define QUEUE_SIZE 4

// The max delay used in scattering messages
#define DELAY_UPPER_BOUND 500

// The min link quality to regard another node as a neighbor 
// (a value of 0 implies no filtering)
#define MIN_LQI 0

#endif
