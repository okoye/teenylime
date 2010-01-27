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
#include "tl_objs.h"
#include "TMoteTuning.h"

/**
 * Main module
 *  
 * @author Davide Molteni
 *         <a href="mailto:davide.molteni@studenti.unitn.it">davide.molteni@studenti.unitn.it</a>
 */


module ProximityP 
{
  uses
  {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as TimerBeacon;
    interface TupleSpace as TS;
    interface Beaconing as Beacon;
    interface Orchestrator;
    interface TLObjects;
  }
  provides interface ProximityState;
}

implementation
{
  bool up = TRUE, running = TRUE;
  TLOpId_t fwOut;  
 

  event void Boot.booted()
  {  	
    call TimerBeacon.startPeriodic(PROXIMITY_HALF_EPOCH);
  }


  event void TimerBeacon.fired()
  {
    up = !up;
    if (!up) {
      call Orchestrator.requestRadioOff();
      return;
    }
    call Orchestrator.requestRadioOn();
    call Beacon.sendBeacon();
  }


  event void Beacon.contact(uint16_t peer, uint16_t rssi)
  {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> contactTuple;

    // TODO check that this format remains like this
    tuple<uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwTuple;

    contactTuple = newTuple(actualField(CONTACT_TUPLE),
            actualField(TOS_NODE_ID),
            actualField(peer),
            actualField(rssi));

    fwTuple = newTuple(actualField(FORWARD_TUPLE), arrayField());
    call TLObjects.copy_tuple((tuple *) fwTuple.payload_field, 
            (tuple *) &contactTuple);

    call TS.out(&fwOut, TRUE, 0, RAM_TS, (tuple *) &fwTuple);

    call Leds.led2Toggle();
  }

  
  command uint32_t ProximityState.nextRadioOn()
  {
    uint32_t remaining = 
        (call TimerBeacon.gett0() + call TimerBeacon.getdt()) - 
        call TimerBeacon.getNow();
    if (!up)
      return remaining;
    return remaining + PROXIMITY_HALF_EPOCH; 
  }
  
  
  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator)
  {
  }


  event void TS.reifyCapabilityTuple(tuple *ct)
  {
  }


  event void TS.operationCompleted(uint8_t completionCode, TLOpId_t operationId,
          TLTarget_t target, TLTupleSpace_t ts, tuple* returningTuple)
  {
  }
}
