/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 36 $
 * * DATE
 * *    $LastChangedDate: 2007-05-25 17:23:22 +0200 (Fri, 25 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: MutualExclusion.nc 36 2007-05-25 15:23:22Z bronwasser $
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
 * An interface to implement a mutual exclusion mechanisms on top of TeenyLIME.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

interface MutualExclusion {
  
  command error_t initRegion(uint8_t regionId);
  command error_t startRequestCriticalRegion(uint8_t regionId);
  command error_t stopRequestCriticalRegion(uint8_t regionId);
  event error_t criticalRegionAquired(uint8_t regionId);
  event error_t lostCriticalRegion(uint8_t regionId);
  command error_t releaseCriticalRegion(uint8_t regionId);
}
