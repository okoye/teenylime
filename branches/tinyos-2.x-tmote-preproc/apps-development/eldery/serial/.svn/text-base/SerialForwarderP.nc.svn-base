/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 944 $
 * * DATE
 * *    $LastChangedDate: 2009-11-25 09:23:31 +0100 (Wed, 25 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TeenyLimeC.nc 944 2009-11-25 08:23:31Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
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


/**
 * This module forward any tuples pushed in the tuple space to the serial
 * port.
 * 
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 * 
 */
#include "serial.h"
#include "Constants.h"
#include "tl_objs.h"

module SerialForwarderP {
  uses {
    interface Leds;
    interface Boot;
    interface TLObjects;
    interface TupleSpace as TS;

    interface AMSend as SerialSend;
    interface SplitControl as SerialControl;
  }
}

implementation {
  TLOpId_t fwReaction, fwIn;
  bool serialBusy = TRUE;
  message_t pkt; /* Buffer for outgoing serial packets. */

  void basic_send();

  event void Boot.booted()
  {
    // TODO check that this format remains like this
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwPattern;
    
    fwPattern = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), dontCare(), dontCare());
    call TS.addReaction(&fwReaction, TRUE, TL_LOCAL, RAM_TS,
        (tuple *) &fwPattern);

    call SerialControl.start();
  }

  
  /* Queries the tuple space for the existence of any tuples to be forwarded. */
  task void forwardAttempt()
  {
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> fwTuple;
    
    /* If the serial port is busy (sending something else), will rely on
     * sendDone() to schedule sending the current tuple. */
    if (serialBusy)
      return;

    fwTuple = newTuple(actualField(FORWARD_TUPLE), dontCare(), dontCare(), dontCare(), dontCare());
    call TS.in(&fwIn, TRUE, TL_LOCAL, RAM_TS, (tuple *) &fwTuple);
  }


  /* Task posted if sendDone returns failure. It attempts to re-send the current
   * buffered message. */
  task void retryAttempt()
  {
    basic_send();
  }


  error_t notifyContact(tuple *contactTuple, serial_msg_t *notification)
  {
    tuple<uint8_t, uint16_t, uint16_t, uint16_t> *ct = 
        (tuple<uint8_t, uint16_t, uint16_t, uint16_t> *) contactTuple;  
    if (ct->value0 != CONTACT_TUPLE)
      return FAIL;

    notification->type = CONTACT_EVENT;
    notification->data.contact.node1 = ct->value1;
    notification->data.contact.node2 = ct->value2;
    notification->data.contact.rssi = ct->value3;
    return SUCCESS;
  }
 

  error_t notifyPosture(tuple *postureTuple, serial_msg_t *notification)
  {
    tuple<uint8_t, uint8_t> *pt =
        (tuple<uint8_t, uint8_t> *) postureTuple;
    if (pt->value0 != POSTURE_TUPLE)
      return FAIL;

    notification->type = POSTURE_EVENT;
    notification->data.posture.posture = pt->value1;

    call Leds.led0Toggle();
    return SUCCESS;
  }
  
  error_t notifyButton(tuple *buttonTuple, serial_msg_t *notification)
  {
    tuple<uint8_t> *bt = 
        (tuple<uint8_t> *) buttonTuple;  
    if (bt->value0 != BUTTON_TUPLE)
      return FAIL;

    notification->type = BUTTON_EVENT;
    
    call Leds.led2Toggle();
    return SUCCESS;
  }

  error_t notifySensors(tuple *sensorsTuple, serial_msg_t *notification)
  {
    tuple<uint8_t, uint16_t> *st = 
        (tuple<uint8_t, uint16_t> *) sensorsTuple;  
    if (st->value0 != SENSORS_TUPLE)
      return FAIL;

    notification->type = SENSORS_EVENT;
    notification->data.sensors.temperature = st->value1;
    
    call Leds.led1Toggle();
    return SUCCESS;
  }
  
  /* Sends a buffer prepared by forwardTuple to the serial. */
  void basic_send()
  {
    error_t status = 
        call SerialSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(serial_msg_t));

    if (status == SUCCESS) 
      serialBusy = TRUE;
    else 
      post retryAttempt();
  }


  /* Prepares a buffer to be forwarded on the serial. The buffer is stored
   * in the pkt global variable. */
  void fowardTuple(tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *fwTuple)
  {
    tuple *payload = (tuple *) fwTuple->fwPayload_field;
    serial_msg_t *notification = 
        (serial_msg_t *) call SerialSend.getPayload(&pkt); 
    error_t err = SUCCESS;

    if (isOfType(payload, tuple<uint8_t, uint16_t, uint16_t, uint16_t>))
      err = notifyContact(payload, notification);

    if (isOfType(payload, tuple<uint8_t, uint8_t>))
      err = notifyPosture(payload, notification);

    if (isOfType(payload, tuple<uint8_t>))
      err = notifyButton(payload, notification);
    
    if (isOfType(payload, tuple<uint8_t, uint16_t>))
      err = notifySensors(payload, notification);
      
    if (err != SUCCESS)
      return;
      
    notification->node = fwTuple->fwAddress_field;
    notification->seqNumber = fwTuple->fwSeq_field;
    
    basic_send();
  }


  event void TS.tupleReady(TLOpId_t operationId, TupleIterator *iterator)
  {
    tuple<uint8_t, uint16_t, uint32_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *fwTuple =
        (tuple<uint8_t, uint8_t, uint8_t, uint8_t[MAX_PAYLOAD_SIZE]> *) 
        call TS.nextTuple(operationId, iterator);

    PROCESS_OP(fwReaction,
      post forwardAttempt();
    );
    
    PROCESS_OP(fwIn,
      /* If we have a tuple to send, try to fw it and remove it from the tuple
       * space. The tuple must be properly buffered by forwardTuple() in case
       * of a failure. */
      if (fwTuple != NULL) {
        fowardTuple(fwTuple);
        call TS.nextTuple(operationId, iterator);
      };
    );
  }


  event void TS.operationCompleted(uint8_t completionCode, TLOpId_t operationId,
          TLTarget_t target, TLTupleSpace_t ts, tuple *returningTuple)
  {
  }


  event void TS.reifyCapabilityTuple(tuple *ct)
  {
  }


  event void SerialControl.startDone(error_t err)
  {
    if (err == SUCCESS) {
      serialBusy = FALSE;
    } else
      call SerialControl.start();
  }


  event void SerialControl.stopDone(error_t err)
  {
  }


  event void SerialSend.sendDone(message_t* msg, error_t err)
  {
    if (err != SUCCESS) {
      post retryAttempt();
      return;
    }
    serialBusy = FALSE;
    post forwardAttempt();
  }
}

