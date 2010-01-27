/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 301 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 14:26:54 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataDissemination.nc 301 2008-02-26 20:26:54Z mceriotti $
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
 * A component that disseminates tuples in the network.
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
  TLOpId_t dataReactId, neighborReactId, rdgId, rdgRemId, unusedId; 
  TLOpId_t rdNotifiedDataId, rdNeighborId;
  uint16_t lastDataId;
  uint16_t data_owner;
  uint8_t classes[NUM_DISSEMINATION_CLASSES] = DISSEMINATION_CLASSES;
  uint16_t classLastId[NUM_DISSEMINATION_CLASSES];

  bool readingRem;
  tuple rem;

  bool isOld(uint8_t classId, uint16_t id);
  bool isIn(uint8_t classId, uint16_t id);
  bool isSecondNewer(uint16_t round1, uint16_t round2);
  void addReactions();
  void startRemRdg(uint16_t destination);
  void startLocRdg(uint8_t class, bool remove);
  void installTask(tuple* task_t);
  
  event void Boot.booted() {

    uint8_t i;

    lastDataId = 0;
    for (i = 0; i<NUM_DISSEMINATION_CLASSES; i++){
      classLastId[i] = 0;
    }
    data_owner = TL_LOCAL;
    readingRem = FALSE;
    addReactions();

#ifdef PRINTF_SUPPORT
    call PrintfControl.start();
#endif
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
    uint8_t i,j;
    tuple t;

    if (opIdCmp(&operationId, &neighborReactId) && number == 1){
      // reaction for a neighbor tuple

      if (isSecondNewer(lastDataId, tuples[0].fields[2].value.int16) &&
          (uint16_t) tuples[0].fields[0].value.int16 != TL_LOCAL){
        // the neighbor tuple is not local and contains a dissemination id
        // newer
        data_owner = tuples[0].fields[0].value.int16;
        if (isSecondNewer(lastDataId+1, tuples[0].fields[2].value.int16)){
          // the dissemination id is bigger than the one following the current
          // dissemination id owned by the local node
          if (!readingRem){
            startRemRdg(data_owner);
          }
        } else {
          // the dissemination id is the one following the current
          // dissemination id owned by the local node
          atomic{
            t = newTuple(6,
                         actualField_uint16(tuples[0].fields[2].value.int16),
                         formalField(TYPE_UINT8_T),
                         formalField(TYPE_UINT16_T),
                         formalField(TYPE_UINT16_T),
                         formalField(TYPE_UINT16_T),
                         formalField(TYPE_UINT16_T));
            // read if there is some data with the announced
            // dissemination id
            call TS.rd(&rdNotifiedDataId, FALSE, TL_LOCAL, &t);
          }
        }
      }
    } else if (opIdCmp(&operationId, &rdNotifiedDataId)) {
      // read for the data with the notified dissemination id

      if (number == 0){
        // there is no data locally available with the announced id
        if (!readingRem){
          startRemRdg(data_owner);
        }
      }
      // else the data with the announced id has been inserted in the
      // local tuple space and it is handled by the corresponding reaction

    } else if (opIdCmp(&operationId, &dataReactId) && number == 1){
      // reaction for disseminated data
	
      if (isOld(tuples[0].fields[1].value.int8, 
                tuples[0].fields[0].value.int16) ||
          isIn(tuples[0].fields[1].value.int8,
               tuples[0].fields[0].value.int16)){
        // if the disseminated data is old with respect to the id of the
        // currently installed tuple for the same class or it is a duplicate
        // of the current id
        call TS.in(&unusedId, FALSE, TL_LOCAL, &(tuples[0]));

      } else if (isSecondNewer(lastDataId+1,
                               tuples[0].fields[0].value.int16)) {
        // if the data has an id bigger than the one  following the current
        // dissemination id owned by the local node
        t = newTuple(3,
                     formalField(TYPE_UINT16_T),
                     formalField(TYPE_LQI),
                     actualField_uint16(tuples[0].fields[0].value.int16));
        // read the id of an owner of the announced data
        call TS.rd(&rdNeighborId, FALSE, TL_LOCAL, &t);
	
        // data_owner gets assigned in the tupleReady event following the
        // previous rd
        if (!readingRem){
          startRemRdg(data_owner);
        }
      } else if (!readingRem) {
        // if the data has an id which is the one following the current
        // dissemination id owned by the local node
        startLocRdg((uint8_t) tuples[0].fields[1].value.int8, TRUE);
      }

    } else if (opIdCmp(&operationId, &rdgId)){
      //local rdg for disseminated tuples

      atomic{
        for (i = 0; i < number; i++){
          if (isOld(tuples[i].fields[1].value.int8, 
                    tuples[i].fields[0].value.int16) ||
              isIn(tuples[i].fields[1].value.int8, 
                   tuples[i].fields[0].value.int16)){
            // if the tuple has an older id or it has the same id of the
            // current one
            copyTuple(&t, &(tuples[i]));
            call TS.in(&unusedId, FALSE, TL_LOCAL, &t);
          } else {
            // if the tuple has a newer id
            installTask(&(tuples[i]));
            if (isSecondNewer(lastDataId, tuples[i].fields[0].value.int16)){
              lastDataId = tuples[i].fields[0].value.int16;
/*               call Leds.set(lastDataId); */
            }       
            for (j = 0; j < NUM_DISSEMINATION_CLASSES; j++){
              if ((uint8_t)tuples[i].fields[1].value.int8 == classes[j]){
                classLastId[j] = tuples[i].fields[0].value.int16;
                break;
              }
            }
            copyTuple(&t, &(tuples[i]));
            call TS.out(&unusedId, FALSE, TL_NEIGHBORHOOD, &t);
          }  
        }
      }

    } else if (opIdCmp(&operationId, &rdgRemId)){      
      //remote rdg for disseminated tuples

      atomic{
        for (i = 0; i< number; i++){
          if (!isOld(tuples[i].fields[1].value.int8, 
                     tuples[i].fields[0].value.int16) &&
              !isIn(tuples[i].fields[1].value.int8,  
                    tuples[i].fields[0].value.int16)){
            // if the tuple has a newer id than the current local one
            copyTuple(&t, &(tuples[i]));
            call TS.out(&unusedId, FALSE, TL_LOCAL, &t);
            data_owner = TL_LOCAL;
            // start the local rdg for the class of the inserted tuple
            startLocRdg(tuples[0].fields[1].value.int8, TRUE);
          }
        }
        readingRem = FALSE;
        addReactions();		
      }

    } else if (opIdCmp(&operationId, &rdNeighborId)){
      //rd for the id of the neihbor that has a given dissemination id

      atomic{
        if (number == 1){
          data_owner = tuples[0].fields[0].value.int16;
        } else {
          data_owner = TL_LOCAL;
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

  void addReactions(){

    tuple disseminationT = newTuple(6,
                                    formalField(TYPE_UINT16_T),
                                    formalField(TYPE_UINT8_T),
                                    formalField(TYPE_UINT16_T),
                                    formalField(TYPE_UINT16_T),
                                    formalField(TYPE_UINT16_T),
                                    formalField(TYPE_UINT16_T));
    tuple neighborT = newTuple(3,
                               formalField(TYPE_UINT16_T),
                               formalField(TYPE_LQI),
                               formalField(TYPE_UINT16_T));
    // TODO: REACTION FOR ID > current_task
    call TS.addReaction(&dataReactId, FALSE, TL_LOCAL, &disseminationT);
    call TS.addReaction(&neighborReactId, FALSE, TL_LOCAL, &neighborT);
  }

  void startRemRdg(uint16_t destination){

    readingRem = TRUE;
    call TS.removeReaction(&unusedId, neighborReactId);
    call TS.removeReaction(&unusedId, dataReactId);
    rem = newTuple(6,
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT8_T),                           
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T));
    call TS.rdg(&rdgRemId, TRUE, destination, &rem);
  }

  void startLocRdg(uint8_t class, bool remove){

    tuple t;
    atomic{
      t = newTuple(6,
                   formalField(TYPE_UINT16_T),
                   actualField_uint8(class),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T),
                   formalField(TYPE_UINT16_T));
      call TS.rdg(&rdgId, FALSE, TL_LOCAL, &t);
    }
  }

  void installTask(tuple* task_t){

    tuple t = newTuple(6,
                       actualField_uint8(TASK_TYPE),
                       actualField_uint8(task_t->fields[1].value.int8),
                       formalField(TYPE_UINT16_T),
                       formalField(TYPE_UINT16_T),
                       formalField(TYPE_UINT16_T),
                       formalField(TYPE_UINT16_T));
    call TS.in(&unusedId, FALSE, TL_LOCAL, &t);

    t = newTuple(6,
                 actualField_uint8(TASK_TYPE),
                 actualField_uint8(task_t->fields[1].value.int8),
                 actualField_uint16(task_t->fields[2].value.int16),
                 actualField_uint16(task_t->fields[3].value.int16),
                 actualField_uint16(task_t->fields[4].value.int16),
                 actualField_uint16(task_t->fields[5].value.int16));
    call TS.out(&unusedId, FALSE, TL_LOCAL, &t);
  }

}

