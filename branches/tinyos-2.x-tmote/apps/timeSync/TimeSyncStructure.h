/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 319 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:36:17 -0500 (Thu, 13 Mar 2008) $
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
  ITEM_NUM = 8,	// Number of motes in the state table
  NUM_SYNCED = 3,	// Number of values considered to calculate the state of synchronization
  EPOCH_RATE_SLEEP = 30000,	// Time to increase the LocalTime when synchronization is stopping 
  EPOCH_RATE_SYNC  = 2000, //Time  to increase the LocalTime when Synchronization is running
  EPOCHM	   = 1000, //Time used for the analysis of messages     			
  DELTA = 1,		// Maximal variation allowed between the average of past values and new ones
  TIMESYNC_RATE = 3,	// Number of EPOCH_RATE to send synchronization data
  TIME_TO_WAIT = 3,	// Number of TIMESYNC_RATE to clear root data
  TIME_TO_CLEAR = 9,	// Number of EPOCH to clear all data of Neighbors
  NUMBER_TO_SEND = 5,	// Number of readings to be considered for calculating the average delay 
  TRASMISSION_ERROR_MAX = 350, //If the transmission time is greater than NUMBER_TO_SEND  the node communicates to the child that must synchronize again
  SEQ_NUMBER = 5,	//Is the minimum sequence number to consider the root node synchronized
};
	
#endif 


