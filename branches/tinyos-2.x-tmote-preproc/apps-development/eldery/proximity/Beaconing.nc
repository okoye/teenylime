/***
 * * PROJECT
 * *    WildLife Monitoring
 * * VERSION
 * *    $LastChangedRevision: 001 $
 * * DATE
 * *    $LastChangedDate: 2009-11-17 10:29:04 +0200 (mar, 17 nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy:  $
 * *
 * *	$Id: TeenyLimeC.nc 843 2009-05-18 08:46:04Z sguna $
 * *
 * *   WildLife Monitoring - project to monitor wild life with
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

/**
 * Beaconing interface
 *  
 * @author Davide Molteni
 *         <a href="mailto:davide.molteni@studenti.unitn.it">davide.molteni@studenti.unitn.it</a>
 */

interface Beaconing
{
  /**
   * send a beacon to all neighbour (BROADCAST) 
   * with the own TOS_NODE_ID
   */
  command void sendBeacon();

  /**
   * signal a contact with another mobile mote,
   * that happens when receive a beacon or a reply 
   * from another mobile mote
   *
   * @peer: is the mote ID for the other mote
   * @rssi: rssi value of the contact or 0 if its is a reply
   *
   */
  event void contact(uint16_t peer, uint16_t rssi);
}

