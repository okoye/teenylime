/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 882 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:05:06 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TreeBuilderC.nc 882 2009-07-14 12:05:06Z mceriotti $
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

#include "Configuration.h"

/** 
 * Module for building the tree from the root of the tree. The tree is built
 * when it is asked through a proper tuple placed in the tuple space or
 * actively built with a timer (in this case the ACTIVE_TREE_BUILDER macro
 * has to be used).
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module TreeBuilderC {

  uses {
    interface Boot;
    interface TupleSpace as TS;
#ifdef ACTIVE_TREE_BUILDER
    interface Timer<TMilli> as TimerTree;
#endif
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

  TLOpId_t reactionId, outId, inId;
  uint16_t tree_round;

#ifdef ACTIVE_TREE_BUILDER
  uint16_t current_tick;
  uint16_t rebuilding_period;
#endif

  void installReaction() {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> p = newTuple(
                       actualField(DATA_COLLECT_CTRL_TYPE),
                       dontCare(), 
                       dontCare(),
                       dontCare());
    call TS.addReaction(&reactionId, FALSE, TL_LOCAL, RAM_TS, (tuple *) &p);
  }

  event void Boot.booted() {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t;
#ifdef ACTIVE_TREE_BUILDER
    current_tick = 0;
    rebuilding_period = TREE_REBUILDING_PERIOD;
    call TimerTree.startPeriodic((uint32_t)MINUTE);
#endif
    t = newTuple(
                 actualField(DATA_COLLECT_CTRL_TYPE),
                 actualField(TL_LOCAL), 
                 actualField(0xFFFF),
                 actualField(CONGESTED_PATH));
    call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t);
    tree_round = 0;
    installReaction();
#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
  }

#ifdef ACTIVE_TREE_BUILDER
  void buildTree(){
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> t;
    tree_round ++;
    if (tree_round == BUILD_A_NEW_TREE){
      tree_round++;
    }
    t = newTuple(
                 actualField(DATA_COLLECT_CTRL_TYPE),
                 actualField(TL_LOCAL), 
                 actualField(tree_round),
                 actualField(0));
    call Leds.led1Toggle();
    signal TreeConnection.treeRefresh();
    call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t);
  }

  event void TimerTree.fired(){
    current_tick++;  
    if (current_tick % rebuilding_period == 0){
      buildTree();
    }
  }
#endif

  event void TS.tupleReady(TLOpId_t operationId, 
                           TupleIterator *iterator) {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> *temp;
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> t;

    PROCESS_OP(reactionId,
               temp = (tuple<uint8_t, uint16_t, uint16_t, 
                       uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (temp->value3 == 0){
                 /* THIS A TUPLE SENT BY THE APPLICATION TO ASK FOR A NEW
                    TREE BUILDING */
                 if (temp->value2 == BUILD_A_NEW_TREE || tree_round == 0xFFFF){
                   tree_round ++;
                   if (tree_round == BUILD_A_NEW_TREE || tree_round == 0xFFFF)
                     tree_round = BUILD_A_NEW_TREE + 1;
                 } else {
                   tree_round = temp->value2;
                 }
                 t = newTuple(
                              actualField(DATA_COLLECT_CTRL_TYPE),
                              actualField(TL_LOCAL), 
                              actualField(tree_round),
                              actualField(0));
                 call Leds.led1Toggle();
                 signal TreeConnection.treeRefresh();
                 call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t);
               }
               call TS.in(&inId, FALSE, TL_LOCAL, RAM_TS, (tuple *)
                          temp);
               );
    
    PROCESS_OP(inId,
               temp = (tuple<uint8_t, uint16_t, uint16_t, 
                       uint16_t> *) call TS.nextTuple(operationId, iterator);
               if (temp != NULL)
                 call TS.nextTuple(operationId, iterator);
               );
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }
  
  event void TS.operationCompleted(uint8_t completionCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				TLTupleSpace_t ts,
				tuple* returningTuple){
  }

  command void TreeConnection.congested(){
    tuple<uint8_t, uint16_t, uint16_t, uint16_t>  t;
    t = newTuple(
                 actualField(DATA_COLLECT_CTRL_TYPE),
                 actualField(TL_LOCAL), 
                 actualField(0),
                 actualField(CONGESTED_PATH));
    call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, RAM_TS, (tuple *) &t);
  }

  command void TreeConnection.setRebuildingFrequency(uint16_t value){
#ifdef ACTIVE_TREE_BUILDER
    current_tick = 0;
    rebuilding_period = value;    
#endif
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}
  
  event void PrintfControl.stopDone(error_t error) {}

  event void PrintfFlush.flushDone(error_t error) {}
#endif
}

