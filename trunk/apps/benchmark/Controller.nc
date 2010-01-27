/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 41 $
 * * DATE
 * *    $LastChangedDate: 2007-05-30 03:28:32 -0500 (Wed, 30 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: Controller.nc 41 2007-05-30 08:28:32Z lmottola $
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

#include "Constants.h"

includes TupleSpace;

/**
 * A controller for the benchmark application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

module Controller {

  uses {
    interface TupleSpace as TS;
    interface TeenyLIMESystem;
  }

  provides interface StdControl;
}

implementation {

  TLOpId_t reaction, reading;
  tuple neighborTuple;
  bool pendingRead;

  command result_t StdControl.init() {

    // Local neighbor tuple
    neighborTuple = newTuple(2, 
			     actualField_uint16(TOS_LOCAL_ADDRESS), 
			     actualField_uint16(CONTROLLER));
    pendingRead = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {

    tuple template = newTuple(2, 
			      actualField_uint16(REACTIVE_NODE), 
			      formalField(TYPE_UINT16_T));
    reaction = call TS.addReaction(FALSE, TL_NEIGHBORHOOD, &template);
    dbg (DBG_USR1, "Starting controller node!\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {

    call TS.removeReaction(reaction);

    return SUCCESS;
  }

  event result_t TS.reifyCapabilityTuple(tuple* ct) {

    return SUCCESS;
  }

  event result_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number) {

    tuple proactiveTempl;    

    if (operationId.commandId == reaction.commandId && !pendingRead) {

      // A reactive node triggered a reaction: querying the proactive nodes 
      dbg (DBG_USR1, "Remote reaction fired!\n");
      proactiveTempl = newTuple(2, 
			       actualField_uint16(PROACTIVE_NODE), 
			       formalField(TYPE_UINT8_T));
      reading = call TS.rdg (FALSE, TL_NEIGHBORHOOD, &proactiveTempl);
      pendingRead = TRUE;

    } else if (operationId.commandId == reading.commandId && pendingRead) {
      
      // Query result received
      dbg (DBG_USR1, "Query result received!\n");
      pendingRead = FALSE;

    }  else {
      dbg (DBG_ERROR, "Unknown tupleReady event\n");
    }
    return SUCCESS;
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple(){
    return &neighborTuple;
  }
}
