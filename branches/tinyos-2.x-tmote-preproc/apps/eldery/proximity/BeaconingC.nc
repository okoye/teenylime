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
 * Beaconing module. 
 *  
 * @author Davide Molteni
 *         <a href="mailto:davide.molteni@studenti.unitn.it">davide.molteni@studenti.unitn.it</a>
 */
module BeaconingC
{
  uses {
    interface TupleSpace as TS;
    interface Boot;
    interface Leds;
    interface Tuning as TLTuning;
  }
  provides {
    interface Beaconing;
  }
}


implementation
{
/* definitions for beacon tuples */
#define nodeType_field value1
#define addr_field value2
   
  //state and global variable
  tuple<uint8_t, uint8_t, uint16_t> myBeacon, tlpBeacon;
  TLOpId_t beaconOut, beaconReaction, beaconIn;

  tuple<uint8_t, uint8_t, uint16_t> myReply, tlpReply;
  TLOpId_t replyOut, replyReaction, replyIn;

  TLOpId_t peerRdId;


  //components command and event
  event void Boot.booted()
  {
    myBeacon=newTuple(actualField(MSG_BEACON_MOBILE), actualField(MY_TYPE),
            actualField(TOS_NODE_ID));
    myReply=newTuple(actualField(MSG_REPLY_MOBILE), actualField(MY_TYPE),
            actualField(TOS_NODE_ID));

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


  void processContact(tuple<uint8_t, uint8_t, uint16_t> *contact_tuple)
  {
    tuple<uint16_t, lqi, rssi, uint32_t> peerPattern; 
	uint16_t peer = contact_tuple->addr_field;

    if (MY_TYPE == contact_tuple->nodeType_field)
      return;
    peerPattern = newTuple(equal(peer), dontCare(), dontCare(),
            dontCare());
    call TS.rd(&peerRdId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &peerPattern);
  }


  void checkRssiThreshold(tuple<uint16_t, lqi, rssi, uint32_t> *peerTuple)
  {
    int16_t rssi;
    if (peerTuple == NULL)
      return;
    rssi = (int16_t) peerTuple->rssi_field - 45;
    
    if (rssi < RSSI_CONTACT_THRESHOLD)
      return;
    signal Beaconing.contact(peerTuple->address_field, peerTuple->rssi_field);

    call TLTuning.setImmediate(KEY_TX_POWER, PROXIMITY_POWER);
    call TS.out(&replyOut, FALSE, peerTuple->address_field, RAM_TS, (tuple *) &myReply);
    call TLTuning.setImmediate(KEY_TX_POWER, CC2420_DEF_RFPOWER);
  }


  event void TS.tupleReady(TLOpId_t operationId,
          TupleIterator *iterator)
  {
    tuple *recv = call TS.nextTuple(operationId,iterator);
    tuple<uint8_t, uint8_t, uint16_t> *contact_tuple = 
        (tuple<uint8_t, uint8_t, uint16_t> *) recv;
    
    PROCESS_OP(beaconReaction,/*received a beacon*/
      call TS.in(&beaconIn, FALSE, TL_LOCAL, RAM_TS, recv);
    );
    
    PROCESS_OP(beaconIn, 
      processContact(contact_tuple); 
      call TS.nextTuple(operationId, iterator);
	);

    PROCESS_OP(peerRdId,
      checkRssiThreshold((tuple<uint16_t, lqi, rssi, uint32_t> *) recv);
    );
    
    PROCESS_OP(replyReaction,/*received a reply*/
      call TS.in(&replyIn, FALSE, TL_LOCAL, RAM_TS,recv);
    );

    PROCESS_OP(replyIn,/*remove a reply*/
      if (MY_TYPE != contact_tuple->nodeType_field)
        signal Beaconing.contact(contact_tuple->addr_field, 0);
      call TS.nextTuple(operationId, iterator);
	);
  }


  command void Beaconing.sendBeacon()
  {
    call TLTuning.setImmediate(KEY_TX_POWER, PROXIMITY_POWER);
    call TS.out(&beaconOut, FALSE, TL_NEIGHBORHOOD, RAM_TS,
            (tuple *) &myBeacon);
    call TLTuning.setImmediate(KEY_TX_POWER, CC2420_DEF_RFPOWER);
  }
  
  
  event void TLTuning.setDone(uint8_t key, uint16_t value)
  {
  }
}
