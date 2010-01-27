/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 1 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 09:33:25 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: Localization.nc 1 2007-04-27 14:33:25Z lmottola $
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

#include <math.h>

includes TupleSpace;
includes TupleMsg;

/**
 * Localization module.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */
 
#define ANCHORX 0 
#define ANCHORY 0
#define POSITION_REFRESH 20480
#define DELTA_MOVE 10

module Localization {

  uses {
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
    interface GPS;
    interface Timer;
  }

  provides interface StdControl;
}

implementation {

  tuple myInfo;
  uint16_t myX, myY, anchorDistance;
  bool refreshNeed;
  
  command result_t StdControl.init() {
    refreshNeed = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.start() {

    return call Timer.start(TIMER_REPEAT, POSITION_REFRESH);
  }

  command result_t StdControl.stop() {

    return call Timer.stop();
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {

    // Preparing for a refresh if needed
    tuple templ = newTuple(4, 
			   formalField(TYPE_UINT16_T), 
			   formalField(TYPE_UINT16_T), 
			   formalField(TYPE_UINT16_T), 
			   formalField(TYPE_UINT16_T));
    anchorDistance = sqrt(pow((myX-ANCHORX),2)+pow((myY-ANCHORY),2));
    myInfo = newTuple(4, 
		      actualField_uint16(TOS_LOCAL_ADDRESS), 
		      actualField_uint16(myX), 
		      actualField_uint16(myY), 
		      actualField_uint16(anchorDistance));

    if (refreshNeed) {
      refreshNeed = FALSE;
      call TS.rd (FALSE, TL_NEIGHBORHOOD, &templ);
    }      
    return &myInfo;
  }

  event result_t TS.reifyCapabilityTuple(tuple* t) {
    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number){
    return SUCCESS;
  }

  event result_t Timer.fired() {
  
    call GPS.getPosition();
    return SUCCESS;
  }

  event result_t GPS.dataReady(uint16_t x, uint16_t y) {

    refreshNeed = FALSE;
    if (sqrt(pow((myX-x),2)+pow((myY-x),2)) > DELTA_MOVE) {
      refreshNeed = TRUE;
    } 
    myX = x;
    myY = y;
    return SUCCESS;
  }
}

