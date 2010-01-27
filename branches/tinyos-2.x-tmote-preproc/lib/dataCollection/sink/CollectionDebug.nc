/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 780 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 04:17:12 -0500 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: CollectionDebug.nc 780 2009-04-29 09:17:12Z mceriotti $
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

/** 
 * Interface to access the debugging information about the data collection.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

interface CollectionDebug {

  /* Notifies a packet successfully received from a parent */
  event void packetReceived(uint8_t traffic_class, 
                            uint16_t child);

  /* Notifies the refresh of the tree */
  event void treeBuilt();

  /* Notifies the action of pausing the tree as a consequence of
     congestion. */
  event void treeCongested();

  /* Notifies the deletion of messages to evaluate due to the overflow of the
     tuple space */
  event void bufferOverflow(uint8_t deletedMessages);

  /* Notifies a message recovery operation towards a child, either failed or
     successful */
  event void messageRecovery(bool success, 
                             uint8_t retries,
                             uint16_t child);

  /* Notifies a dropped duplicate sent by a child */
  event void droppedDuplicate(uint16_t child);

  /* Returns the number of sent invoked so far */
  command uint16_t getTotalSend();

  /* Returns the number of retxmit done so far */
  command uint16_t getTotalRetxmit();
}
