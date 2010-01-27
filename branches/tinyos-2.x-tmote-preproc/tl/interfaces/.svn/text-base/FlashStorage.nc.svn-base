/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 443 $
 * * DATE
 * *    $LastChangedDate: 2008-05-16 12:14:37 +0200 (Fri, 16 May 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: PersistentManager.nc 443 2008-05-16 10:14:37Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
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

#include "TupleSpace.h"

/**
 * The interface to manage the persistence storage such as the flash or the
 * FRAM.
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 */

interface FlashStorage {
  command void swap();
  event void swapDone(error_t error);
  
  command error_t write(uint32_t addr, void *buf, uint32_t len);
  event void writeDone(uint32_t addr, void *buf, uint32_t len, error_t error);

  command error_t read(uint32_t addr, void *buf, uint32_t len);
  event void readDone(uint32_t addr, void *buf, uint32_t len, error_t error);

  command error_t saveMeta(void *buf, uint32_t len);
  event void saveMetaDone(error_t error);

  command error_t loadMeta(void *buf, uint32_t len);
  event void loadMetaDone(void *buf, uint32_t len, error_t error);

  command error_t reset();
  event void resetDone(error_t error);
}

