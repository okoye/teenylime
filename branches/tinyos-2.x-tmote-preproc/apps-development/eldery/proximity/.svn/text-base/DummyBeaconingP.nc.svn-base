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

#include "Constants.h"

/**
 * Dummy beaconing module (used to remove tuples from the tuple space). 
 *  
 * @author Davide Molteni
 *         <a href="mailto:davide.molteni@studenti.unitn.it">davide.molteni@studenti.unitn.it</a>
 */
module DummyBeaconingP {
  uses {
    interface TupleSpace as TS;
    interface Boot;
  }
}


implementation {
  tuple<uint8_t, uint8_t, uint16_t> tlpBeacon;
  TLOpId_t beaconReaction, beaconIn;

  tuple<uint8_t, uint8_t, uint16_t> tlpReply;
  TLOpId_t replyReaction, replyIn;

  //components command and event
  event void Boot.booted()
  {
    tlpBeacon = newTuple(actualField(MSG_BEACON_MOBILE), dontCare(), 
            dontCare());
    tlpReply = newTuple(actualField(MSG_REPLY_MOBILE), dontCare(), 
            dontCare());

    call TS.addReaction(&beaconReaction, FALSE, TL_LOCAL, RAM_TS,
            (tuple *) &tlpBeacon);
    call TS.addReaction(&replyReaction, FALSE, TL_LOCAL, RAM_TS,
            (tuple *) &tlpReply);
  }


  event void TS.operationCompleted(uint8_t completionCode,
				   TLOpId_t operationId,
				   TLTarget_t target,
				   TLTupleSpace_t ts,
				   tuple* returningTuple)
  {
  }


  event void TS.reifyCapabilityTuple(tuple *ct)
  {
  }


  event void TS.tupleReady(TLOpId_t operationId,
          TupleIterator *iterator)
  {
    tuple *recv = call TS.nextTuple(operationId,iterator);
    
    PROCESS_OP(beaconReaction,/*received a beacon*/
      call TS.in(&beaconIn, FALSE, TL_LOCAL, RAM_TS, recv);
    );
    
    PROCESS_OP(replyReaction,/*received a reply*/
      call TS.in(&replyIn, FALSE, TL_LOCAL, RAM_TS,recv);
    );

    PROCESS_OP(beaconIn, 
      call TS.nextTuple(operationId, iterator);
	);

    PROCESS_OP(replyIn,/*remove a reply*/
      call TS.nextTuple(operationId, iterator);
	);
  }
}
