/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 4 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 10:22:42 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: paolinux78 $
 * *
 * *	$Id: SendTuple.nc 4 2007-04-27 15:22:42Z paolinux78 $
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

includes TupleSpace;

interface SendTuple {

  command result_t send(TLTarget_t target, tuple* tuples, uint8_t tupleNumber, msg_t operation, TLOpId_t operationId);

  event result_t sendDone(TLOpId_t operationId, result_t success);
  
/* #ifndef mica2 */
/*   command result_t sendSimMsg(); */
/* #endif */

}
