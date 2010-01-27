/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 865 $
 * * DATE
 * *    $LastChangedDate: 2009-06-18 09:31:56 -0500 (Thu, 18 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TMoteStackConf.h 865 2009-06-18 14:31:56Z lmottola $
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
#define TMOTE_QUEUE_SIZE 10

// The min link quality to regard another node as a neighbor 
// (a value of 0 implies no filtering)
#define MIN_LQI 85

// The maximum number of retries to guarantee message delivery
#define MAX_MSG_RETRIES 1

// The duty cycle of the local radio
#define LOCAL_LPL_INTERVAL 0

// The duty cycle of radios the node needs to talk to
#define REMOTE_LPL_INTERVAL 250

#endif
