/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 300 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 13:50:56 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataDissemination.nc 300 2008-02-26 19:50:56Z mceriotti $
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

#include "Constants.h"
#include "TupleSpace.h"

/**
 * A component that activates the dissemination of tuples in the network.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

module DataDissemination {

  uses {
    interface Boot;
    interface TupleSpace as TS;

    interface TeenyLIMESystem;

    interface AMPacket;

    interface Leds;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  tuple neighborTuple;
  TLOpId_t dataReactId;
  uint16_t lastDataId = 0;
  uint8_t classes[NUM_DISSEMINATION_CLASSES] = DISSEMINATION_CLASSES;
  uint16_t classLastId[NUM_DISSEMINATION_CLASSES];
  uint16_t num;

  bool isOld(uint8_t classId, uint16_t id);
  bool isIn(uint8_t classId, uint16_t id);
  bool isSecondNewer(uint16_t round1, uint16_t round2);

  event void Boot.booted() {
    uint8_t i;
    tuple disseminationT = newTuple(6,
                                        formalField(TYPE_UINT16_T),
                                        formalField(TYPE_UINT8_T),
                                        formalField(TYPE_UINT16_T),
                                        formalField(TYPE_UINT16_T),
                                        formalField(TYPE_UINT16_T),
                                        formalField(TYPE_UINT16_T));
    for (i = 0; i<NUM_DISSEMINATION_CLASSES; i++){
      classLastId[i] = 0;
    }
    num = 0;
    call TS.addReaction(&dataReactId, FALSE, TL_LOCAL, &disseminationT);
  }

  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    neighborTuple = newTuple(3,
                             actualField_uint16(call AMPacket.address()),
                             formalField(TYPE_LQI),
                             actualField_uint16(lastDataId));
    return &neighborTuple;
  }

  event void TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, 
			       uint8_t number) {
    TLOpId_t outId, inId, ingId;
    tuple temp, temp2;
    uint8_t i;

    if (opIdCmp(&operationId, &dataReactId) && number == 1){

      if ((uint16_t) tuples[0].fields[0].value.int16 == 0){
        atomic{
          lastDataId++;
          if (lastDataId == 0){
            lastDataId++;
          }
          num++;
          temp = newTuple(6,
                          actualField_uint16(lastDataId),
                          actualField_uint8(tuples[0].fields[1].value.int8),
                          actualField_uint16(tuples[0].fields[2].value.int16),
                          actualField_uint16(tuples[0].fields[3].value.int16),
                          actualField_uint16(tuples[0].fields[4].value.int16),
                          actualField_uint16(tuples[0].fields[5].value.int16));
          temp2 = newTuple(6,
                           formalField(TYPE_UINT16_T),
                           actualField_uint8(tuples[0].fields[1].value.int8),
                           formalField(TYPE_UINT16_T),
                           formalField(TYPE_UINT16_T),
                           formalField(TYPE_UINT16_T),
                           formalField(TYPE_UINT16_T));
          call TS.ing(&ingId, FALSE, TL_LOCAL, &temp2);
          call TS.out(&outId, FALSE, TL_LOCAL, &temp);
        }
      } else if (!isOld(tuples[0].fields[1].value.int8, 
                        tuples[0].fields[0].value.int16) &&
                 !isIn(tuples[0].fields[1].value.int8, 
                       tuples[0].fields[0].value.int16)){
        atomic{
          for (i = 0; i < NUM_DISSEMINATION_CLASSES; i++){
            if ((uint8_t)tuples[0].fields[1].value.int8 == classes[i]){
              classLastId[i] = lastDataId;
              if (i == 0){
                call Leds.led0Toggle();
              } else if (i == 1) {
                call Leds.led1Toggle();
              }
              
              break;
            }
          }
        }
        call TS.out(&outId, FALSE, TL_NEIGHBORHOOD, &(tuples[0]));
      } else {
        atomic{
          copyTuple(&temp, &(tuples[0]));
          call TS.in(&inId, FALSE, TL_LOCAL, &temp);
        }
      }
    }
  }

  event void TS.reifyCapabilityTuple(tuple* ct) {
  }

  event void TS.tupleSpaceError(uint8_t errCode, 
				TLOpId_t operationId, 
				TLTarget_t target,  
				tuple* failedTuple) {
  }

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif 

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

  // Return TRUE if id is older than the last task id for the given class
  bool isOld(uint8_t classId, uint16_t id){
    uint8_t i;
    for (i = 0; i < NUM_DISSEMINATION_CLASSES; i++){
      if (classId == classes[i]){
        return isSecondNewer(id, classLastId[i]);
      }
    }
    return FALSE;
  }
  
  // Return TRUE if id for the given class is the current one
  bool isIn(uint8_t classId, uint16_t id){
    uint8_t i;
    for (i = 0; i < NUM_DISSEMINATION_CLASSES; i++){
      if (classId == classes[i]){
        return (id == classLastId[i]);
      }
    }
    return FALSE;
  }
  
}

