/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 275 $
 * * DATE
 * *    $LastChangedDate: 2008-02-16 19:05:29 +0200 (Sat, 16 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: CollectionInfo.nc 275 2008-02-16 17:05:29Z lmottola $
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

#include "CollectionInfo.h"

/** 
 * Interface to access the information about the data collection.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

interface CollectionInfo {

  /* Gets the current gateway towards which data are delivered */
  command uint16_t gateway();

  /* Gets the current parent in the collecting tree */
  command uint16_t currentParent();

  /* Gets the cost of the path to the root of the tree */
  command uint16_t parentCost();

  /* Gets the LQI of the parent in the tree */
  command uint16_t parentLQI();
}
