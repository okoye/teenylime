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
 * *	$Id: GlobalTime.nc 319 2008-03-13 11:36:17Z ben_christian $
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
 
 
interface GlobalTime{ 
  /**
   * Returns the current local time of this mote. 
   */
  async command uint16_t getLocalTime();
  
  /**
   * Reads the current global time. 
   * @return TRUE if this mote is synchronized, FALSE otherwise.
   */
  async command bool getGlobalTime(uint16_t *time);
  
  /**
   * This event is triggered when the mote is synchronized
   *
   */
  event void synced();
	  	
  /**
   * This event is triggered when the mote lost synchronize state
   *
   */
  event void lostSynced();	
  
   /**
   * Start the timer used for generate timeEvent   
   */
  async command void startTimer();
   
   /**
   * Stop the timer used for generate timeEvent  
   * @param time indicate period of the timer 
   */
  async command void stopTimer();
  
   /**
   * This event is triggered on the Epoch change
   *
   */
  event void timeEvent();	
  
   /**
   * Start the Synchronization protocol   
   */
  async command void startSync(uint16_t period);
  
}
