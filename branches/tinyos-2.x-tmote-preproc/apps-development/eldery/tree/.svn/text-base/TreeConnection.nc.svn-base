/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 282 $
 * * DATE
 * *    $LastChangedDate: 2008-02-16 19:27:02 +0200 (Sat, 16 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *  $Id: TreeConnection.nc 282 2008-02-16 17:27:02Z lmottola $
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
 * Interface to access the information about the collecting tree.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

interface TreeConnection {

  /* Gets the current parent in the tree */
  command uint16_t getParent();

  /* Gets the current cost of the path to the root of the tree */
  command uint16_t getPathCost();

  /* Gets the LQI of the current parent */
  command uint16_t getParentLQI();

  /* Set if the node is the Sink (TRUE) or a general node (FALSE)*/
  command void setSink(bool isSinkNode);

  /* Notifies the update of the parent or the availability of a new parent */
  event void parentUpdate(uint16_t parent);
  
  /* 
    Tell (approximatly) when the radio of the parent wakes up a next time
    If the parent is not available this value is not relaiable
  */
  command uint32_t getParentNextWakeUp();
  
}
