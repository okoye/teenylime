/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 230 $
 * * DATE
 * *    $LastChangedDate: 2007-12-06 08:11:10 +0100 (Thu, 06 Dec 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: SendTuple.nc 230 2007-12-06 07:11:10Z lmottola $
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
#include "TupleMsg.h"
#include "tl_objs.h"

interface TLObjects {
  command bool compare_tuple(tuple *t1, tuple *t2);
  command void replace_indicator(tuple *t, uint16_t lqi, uint16_t rssi);
//  command bool istemplate_tuple(tuple *t);
  command int tuple_sizeof(tuple *t);
  command int copy_tuple(tuple *dest, tuple *src);
  command int field_count(int type_id);
  command int get_field_type(int type_id, int field_no);
  command size_t get_field_size(int type_id, int field_no);
}
