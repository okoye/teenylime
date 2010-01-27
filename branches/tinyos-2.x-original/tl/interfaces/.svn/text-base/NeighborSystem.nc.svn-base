/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 27 $
 * * DATE
 * *    $LastChangedDate: 2007-05-04 10:00:22 +0200 (Fri, 04 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: NeighborSystem.nc 27 2007-05-04 08:00:22Z bronwasser $
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
 
#include "TupleSpace.h"


interface NeighborSystem {
  
  // To obtain the current neighborTuple
  command tuple* getNeighborTuple();

  command result_t update(TLTarget_t recipient, tuple neighborTuple);

/*   command TLTarget_t* getNeighborsId(); */

}
