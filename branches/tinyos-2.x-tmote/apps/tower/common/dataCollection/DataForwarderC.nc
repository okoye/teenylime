/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 307 $
 * * DATE
 * *    $LastChangedDate: 2008-03-04 04:37:23 -0600 (Tue, 04 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: DataForwarderC.nc 307 2008-03-04 10:37:23Z lmottola $
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

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/** 
 * Module for data forwarding on the collecting tree.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */
module DataForwarderC {

  uses {
    interface Boot;

    interface TupleSpace as TS;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif

    interface AMPacket;
    interface TreeConnection;
  }

  provides {
    interface CollectionInfo;
  }

}

implementation {

  TLOpId_t reactionId, reactionSysId;
  TLOpId_t outId, ingTId, ingNId;
  bool fw_active;
  uint16_t forwarded;

  void installReaction(){
    tuple p1,p2;
    p1 = newTuple(5, 
                 actualField_uint8(TEMP_DEFORM_TYPE),
                 formalField(TYPE_UINT16_T), 
                 formalField(TYPE_UINT16_T),
                 formalField(TYPE_UINT16_T),
                 formalField(TYPE_UINT16_T));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p1);
    p2 = newTuple(6,
                 actualField_uint8(NODE_INFO_TYPE),
                 formalField(TYPE_UINT16_T), 
                 formalField(TYPE_UINT16_T),
                 formalField(TYPE_UINT16_T),
                 formalField(TYPE_UINT16_T),
                 formalField(TYPE_UINT16_T));
    call TS.addReaction(&reactionSysId, FALSE, TL_LOCAL, &p2);
 }

  event void Boot.booted() {
    fw_active = FALSE;
    forwarded = 0;
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {
    tuple temp;
    uint16_t parent;
    uint8_t i;
    TLOpId_t remReact;
    if (opIdCmp(&operationId, &reactionId)
        && number == 1) {
      temp = newTuple(5, 
                      actualField_uint8(TEMP_DEFORM_TYPE),
                      formalField(TYPE_UINT16_T), 
                      formalField(TYPE_UINT16_T),
                      formalField(TYPE_UINT16_T),
                      formalField(TYPE_UINT16_T));
      call TS.ing(&ingTId, FALSE, TL_LOCAL, &temp);
    } else if (opIdCmp(&operationId, &reactionSysId)
        && number == 1) {
      temp = newTuple(6, 
                      actualField_uint8(NODE_INFO_TYPE),
                      formalField(TYPE_UINT16_T), 
                      formalField(TYPE_UINT16_T),
                      formalField(TYPE_UINT16_T),
                      formalField(TYPE_UINT16_T),
                      formalField(TYPE_UINT16_T));
      call TS.ing(&ingNId, FALSE, TL_LOCAL, &temp);
    } else if (opIdCmp(&operationId, &ingTId) || 
               opIdCmp(&operationId, &ingNId)){
      atomic{
        parent = call TreeConnection.getParent();
        for (i=0; i<number; i++){
          copyTuple(&temp,&(tuples[i]));
          if (TEMP_DEFORM_TYPE != (uint8_t)temp.fields[0].value.int8 && 
              NODE_INFO_TYPE != (uint8_t)temp.fields[0].value.int8){
            continue;
          }
          if (parent != TL_LOCAL && fw_active){
            call TS.out(&outId, TRUE, parent, &temp);
            forwarded++;
          } else {
            if (fw_active){
              atomic{
                fw_active = FALSE;
                call TS.removeReaction(&remReact, reactionId); 
                call TS.removeReaction(&remReact, reactionSysId); 
             }
            }
            call TS.out(&outId, FALSE, TL_LOCAL, &temp);
          }
        }
      }
    }
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
    tuple temp;
    TLOpId_t remReact;
    if(errCode == RELIABLE_MSG_FAIL){
      copyTuple(&temp, failedTuple);
      if (fw_active){
        atomic{
          fw_active = FALSE;
          call TS.removeReaction(&remReact, reactionId);
          call TS.removeReaction(&remReact, reactionSysId);
        }
      }
      call TS.out(&outId, FALSE, TL_LOCAL, &temp);
      forwarded--;
      call TreeConnection.unreliableParent();
    }
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TreeConnection.parentUpdate(uint16_t parent){
    tuple p1,p2;
    if (!fw_active){
      atomic{
        fw_active = TRUE;
        installReaction();
      }
      p1 = newTuple(5, 
                   actualField_uint8(TEMP_DEFORM_TYPE),
                   formalField(TYPE_UINT16_T), 
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T));
      call TS.ing(&ingTId, FALSE, TL_LOCAL, &p1);
      p2 = newTuple(6, 
                    actualField_uint8(NODE_INFO_TYPE),
                    formalField(TYPE_UINT16_T), 
                    formalField(TYPE_UINT16_T),
                    formalField(TYPE_UINT16_T),
		    formalField(TYPE_UINT16_T),
		    formalField(TYPE_UINT16_T));
      call TS.ing(&ingNId, FALSE, TL_LOCAL, &p2);
    }
  }
  
  event void TreeConnection.parentLost(){
    TLOpId_t remReact;
    if (fw_active){
      atomic{
        fw_active = FALSE;
        call TS.removeReaction(&remReact, reactionId);
        call TS.removeReaction(&remReact, reactionSysId);
      }
    }
  }

  event void TreeConnection.unreliablePath(){
    TLOpId_t remReact;
    if (fw_active){
      atomic{
        fw_active = FALSE;
        call TS.removeReaction(&remReact, reactionId);
        call TS.removeReaction(&remReact, reactionSysId);
      }
    }
  }
 
  command uint16_t CollectionInfo.currentParent(){
    return call TreeConnection.getParent();
  }

  command uint16_t CollectionInfo.forwardedTuples(){
    return forwarded;
  }

  command uint16_t CollectionInfo.parentCost(){
    return call TreeConnection.getPathCost();
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

