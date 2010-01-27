/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 319 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 13:36:17 +0200 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: TimeSyncStructure.h 319 2008-03-13 11:36:17Z ben_christian $
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

#ifndef TIMESYNCSTRUCTURE_H
#define TIMESYNCSTRUCTURE_H

 
enum {
  SYNCH_PERIOD  = 30,
  // Period to increase the LocalTime
  EPOCH_RATE  = 1000,
  // The timeEvent() event in GlobalTime is signalled 
  // every TIME_EVENT_MULTIPLIER * EPOCH_RATE
  TIME_EVENT_MULTIPLIER  = 5,
  // Number of EPOCH_RATE to send synchronization data
  TIMESYNC_RATE = 3, 
  // Number of EPOCH_RATE to clear data: if a previous synchronization
  // was run, the delta between LocalTime and GlobalTime is kept
  TIME_TO_CLEAR = 10, 
  // Number of past evaluations of LocalTime vs GlobalTime to be
  // considered to calculate the state of synchronization
  NUM_SYNCED = 3, 
  // Minimum number of readings to be considered for calculating the
  // average transmission delay
  MIN_TIME_READINGS = 5,	 
  // If the transmission time is greater than TRASMISSION_ERROR_MAX 
  // the node tells the child to re-start synchronization
  TRASMISSION_ERROR_MAX = 350, 
};
	
#endif 


