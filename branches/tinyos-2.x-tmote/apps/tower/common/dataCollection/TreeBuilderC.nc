/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 296 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:31:13 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TreeBuilderC.nc 296 2008-02-26 18:31:13Z mceriotti $
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
 * Module for building the tree on any node different from the sink.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module TreeBuilderC {

  uses {
    interface Boot;

    interface Timer<TMilli> as TimerTree;
    interface Timer<TMilli> as TimerDelay;

    interface Random;
    
    interface TupleSpace as TS;

    interface AMPacket;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

  provides {
    interface TreeConnection;
  }
}

implementation {

  TLOpId_t reactionId, outId, ingId;
  TLOpId_t rdCandLQI;

  uint16_t current_parent;
  uint16_t current_path_nlqi;
  uint16_t parent, currentTick;
  uint16_t parent_round;
  uint16_t parent_path_nlqi;
  uint16_t cand_lqi, cand_nlqi;

  bool unreliable;
  bool notified;

  void installReaction() {
    tuple p = newTuple(4, 
                       actualField_uint8(DATA_COLLECT_CTRL_TYPE),
                       formalField(TYPE_UINT16_T), 
                       formalField(TYPE_UINT16_T),
                       formalField(TYPE_UINT16_T));
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, &p);
  }

  // Return TRUE if round2 follows round1
  bool isSecondNewer(uint16_t round1, uint16_t round2){
    if (round1 == round2){
      return FALSE;
    } else if (round1 < round2){
      if ((round2 - round1) < 0x8000) {
        return TRUE;
      } else {
        return FALSE;
      }
    } else {
      if ((round1 - round2) < 0x8000) {
        return FALSE;
      } else {
        return TRUE;
      }
    }
  }

  event void Boot.booted() {
    current_parent = TL_LOCAL;
    current_path_nlqi = UNRELIABLE_PATH;
    parent = TL_LOCAL;
    notified = FALSE;
    parent_round = 0;
    unreliable = TRUE;
    currentTick = 0;
    installReaction();
    call Leds.led0On();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

  command uint16_t TreeConnection.getParent(){
    return current_parent;
  }

  command uint16_t TreeConnection.getPathCost(){
    return current_path_nlqi;
  }

  event void TimerTree.fired() {
    currentTick++;
    if (currentTick % TREE_TIMEOUT == 0){
      atomic{
        current_parent = TL_LOCAL;
        current_path_nlqi = UNRELIABLE_PATH;
        parent = TL_LOCAL;
        parent_round = 0;
        unreliable = TRUE;
        notified = FALSE;
      }
      signal TreeConnection.parentLost();
      call Leds.led0On();
      call Leds.led1Off();
      call TimerTree.stop();
    }
  }

  event void TimerDelay.fired(){
    tuple t;
    uint16_t delay;
    if (parent!= TL_LOCAL && !notified){
      current_parent = parent;
      current_path_nlqi = parent_path_nlqi;
      signal TreeConnection.parentUpdate(current_parent);
      call Leds.led0Off();
      call Leds.led1Off();
      notified = TRUE;
      currentTick = 0;
      call TimerTree.startPeriodic((uint32_t)MINUTE);
      delay = call Random.rand16();
      delay %= PARENT_FORWARDING_RAND_INTERVAL;
      delay += PARENT_FORWARDING_OFFSET;
      call TimerDelay.startOneShot(delay);
    } else if (parent!= TL_LOCAL && notified){
      notified = FALSE;
      t = newTuple(4, 
                   actualField_uint8(DATA_COLLECT_CTRL_TYPE),
                   actualField_uint16(TL_LOCAL), 
                   actualField_uint16(parent_round),
                   actualField_uint16(parent_path_nlqi));
      call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, &t);
    }
  }

  static void startForwardDelay(){
    uint16_t delay = call Random.rand16();
    delay %= PARENT_NOTIFICATION_RAND_INTERVAL;
    delay += PARENT_NOTIFICATION_OFFSET;
    notified = FALSE;
    call TimerDelay.startOneShot(delay);
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			   tuple *tuples, 
			   uint8_t number) {
    tuple temp, t;
    uint16_t path_nlqi = UNRELIABLE_PATH;
    uint8_t i;
    if (opIdCmp(&operationId, &reactionId)
        && number == 1){
      t = newTuple(4, 
                   actualField_uint8(DATA_COLLECT_CTRL_TYPE),
                   formalField(TYPE_UINT16_T), 
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T));
      call TS.ing(&ingId, FALSE, TL_LOCAL, &t);
    } else if (opIdCmp(&operationId, &rdCandLQI)){
      /*       RD for the RSSI value of the parent */
      atomic{
        if (number == 0){
          cand_nlqi = UNRELIABLE_PATH;
        } else {
          cand_lqi = (uint16_t)tuples[0].fields[1].value.int16;
          if (cand_lqi <  MIN_ROUTING_LQI){
            cand_nlqi = UNRELIABLE_PATH;
          } else if (cand_lqi <  MIN_RELIABLE_LINK_LQI){
            cand_nlqi = UNRELIABLE_LINK;
          } else if (cand_lqi > MAX_ROUTING_LQI){
            cand_nlqi = 0;
          } else if (cand_nlqi == MAX_ROUTING_LQI){
            cand_nlqi = 1;
          } else {
            cand_nlqi = (MAX_ROUTING_LQI - cand_lqi - 1) / (uint16_t)((MAX_ROUTING_LQI-MIN_RELIABLE_LINK_LQI)/LEVELS_LQI);
          cand_nlqi++;
          }
        }
      }
    } else if (opIdCmp(&operationId, &ingId)) {
      /*     ING FOR THE TREEBUILD TUPLES */
      atomic{
        for (i = 0; i<number; i++){
          copyTuple(&temp,&(tuples[i]));
          if (DATA_COLLECT_CTRL_TYPE != (uint8_t)temp.fields[0].value.int8){
            /*  call Leds.led2On(); */
            continue;
          }
          if ((uint16_t)temp.fields[3].value.int16 == UNRELIABLE_PATH &&
              (uint16_t)temp.fields[1].value.int16 == parent){
            //THE PATH IS UNRELIABLE (FROM MY PARENT I RECEIVED AN
            //UNRELIABLE_PATH MESSAGE)
            t = newTuple(4, 
                         actualField_uint8(DATA_COLLECT_CTRL_TYPE),
                         actualField_uint16(TL_LOCAL), 
                         actualField_uint16(parent_round),
                         actualField_uint16(UNRELIABLE_PATH));
            call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, &t);
            unreliable = TRUE;
            signal TreeConnection.unreliablePath();
            call Leds.led1On();
          } else if (parent == TL_LOCAL && 
                     (uint16_t)temp.fields[3].value.int16 < UNRELIABLE_PATH){
            //I HAVE NO PARENT AND THE SEQUENCE NUM OF THE TREE IS
            //NEWER THAN THE LAST JOINED TREE
            
            t = newTuple(3,
                         actualField_uint16(temp.fields[1].value.int16),
                         formalField(TYPE_LQI),
                         formalField(TYPE_UINT16_T));
            call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, &t);
            if (cand_nlqi < UNRELIABLE_PATH){
              parent = temp.fields[1].value.int16;
              parent_round = temp.fields[2].value.int16;
              unreliable = FALSE;     
              parent_path_nlqi =  cand_nlqi + (uint16_t)temp.fields[3].value.int16;
            }
            
            if (cand_nlqi == UNRELIABLE_PATH){
              continue;
            }
            startForwardDelay();
          } else if (isSecondNewer(parent_round, temp.fields[2].value.int16) &&
                     (uint16_t)temp.fields[3].value.int16 < UNRELIABLE_PATH){
            //I HAVE A PARENT AND THE SEQUENCE NUM OF THE TREE IS NEWER THAN THE
            //PREVIOUSLY JOINED ONE
            
            t = newTuple(3,
                         actualField_uint16(temp.fields[1].value.int16),
                         formalField(TYPE_LQI),
                         formalField(TYPE_UINT16_T));
            call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, &t);
            if (cand_nlqi < UNRELIABLE_PATH){
              parent = temp.fields[1].value.int16;
              parent_round = temp.fields[2].value.int16;
              unreliable = FALSE;
              parent_path_nlqi =  cand_nlqi + (uint16_t)temp.fields[3].value.int16;
            }
            
            if (cand_nlqi == UNRELIABLE_PATH){
              continue;
            }
            startForwardDelay();
          } else if (parent_round == (uint16_t)temp.fields[2].value.int16 &&
                     (uint16_t)temp.fields[3].value.int16 < UNRELIABLE_PATH ){
            //THE SEQUENCE NUM IS CONCURRENT TO THE ONE OF THE ACTUAL PARENT
            
            t = newTuple(3,
                         actualField_uint16(temp.fields[1].value.int16),
                         formalField(TYPE_LQI),
                         formalField(TYPE_UINT16_T));
            call TS.rd(&rdCandLQI, FALSE, TL_LOCAL, &t);
            if (cand_nlqi < UNRELIABLE_PATH){
              path_nlqi = cand_nlqi + (uint16_t)temp.fields[3].value.int16;
            }
            
            if (cand_nlqi == UNRELIABLE_PATH){
              continue;
            }
            if (parent_path_nlqi >  path_nlqi){
              //THE COST OF THE PATH IS BETTER THAN THE CURRENT ONE
   
              parent = temp.fields[1].value.int16;
              parent_round = temp.fields[2].value.int16;
              parent_path_nlqi = path_nlqi;
              unreliable = FALSE;
              
              startForwardDelay();
            } 
          }
        }
      }
    }
  }
  
  command void TreeConnection.unreliableParent(){
    tuple t;
    t = newTuple(4, 
                 actualField_uint8(DATA_COLLECT_CTRL_TYPE),
                 actualField_uint16(TL_LOCAL), 
                 actualField_uint16(parent_round),
                 actualField_uint16(UNRELIABLE_PATH));
    call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, &t);
    unreliable = TRUE;
    signal TreeConnection.unreliablePath();
    call Leds.led1On();
  }
  
  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}

  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif

}
