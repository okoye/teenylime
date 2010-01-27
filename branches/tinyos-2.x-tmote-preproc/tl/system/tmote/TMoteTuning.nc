/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 949 $
 * * DATE
 * *    $LastChangedDate: 2009-11-25 09:19:47 -0600 (Wed, 25 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TMoteTuning.nc 949 2009-11-25 15:19:47Z sguna $
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

#include "TupleSpace.h"
#include "TMoteTuning.h"

#include "TLConf.h"
#include "TMoteStackConf.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

/**
 * The component implementing the Tuning interface for low-level
 * parameters on TMote nodes.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

module TMoteTuning {

  provides {
    interface Tuning[uint8_t componentId];
    interface Init;
  }

  uses {

    interface Queue<setRequest> as RequestQueue;

    // To handle KEY_LPL_SLEEP_INTERVAL 
    interface LowPowerListening;
    // To handle KEY_RADIO_CONTROL
    interface SplitControl as AMControl;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {
  
  bool radioOn;
  uint8_t currentComponent;
  uint16_t remoteOpTimeout;
  uint16_t remoteLPLinterval;
  uint16_t txPower;

#if defined(TL_LPL) || defined(TL_PACKET_LINK)
  uint8_t msgRetries;
  bool lplAcks;
#endif

  command error_t Init.init() {

    // Initial settings
    radioOn = TRUE;
    remoteOpTimeout = REMOTE_OP_TIMEOUT;
    remoteLPLinterval = REMOTE_LPL_INTERVAL;
    txPower = CC2420_DEF_RFPOWER;
#if defined(TL_LPL) || defined(TL_PACKET_LINK)
    msgRetries = MAX_MSG_RETRIES;
    lplAcks = TRUE;
#endif
    return SUCCESS;

  }

  task void signalRadioStatus() {
    if (radioOn) 
      signal Tuning.setDone[currentComponent](KEY_RADIO_CONTROL, RADIO_ON); 
    else 
      signal Tuning.setDone[currentComponent](KEY_RADIO_CONTROL, RADIO_OFF);       
  }

  void task serveRequest() {

    setRequest r = call RequestQueue.dequeue();
    error_t res;
    currentComponent = r.componentId;
    switch (r.key) {
      case KEY_RADIO_CONTROL:
	if (r.value == RADIO_ON) {
	  if (radioOn) {
	    post signalRadioStatus();	  
	  } else {
	    res = call AMControl.start();
	    if (res != SUCCESS && res != EALREADY)
	      post serveRequest();
	    else
	      post signalRadioStatus();
	  }
	} else if (r.value == RADIO_OFF) {
	  if (!radioOn) {
	    post signalRadioStatus();
	  } else {
        res = call AMControl.stop();
	    if (res != SUCCESS && res != EALREADY)
	      post serveRequest();
	    else
	      post signalRadioStatus();
	  }
	} 
	break;
    }
  }

  void serveNextRequest() {

    if (!call RequestQueue.empty()) {
      post serveRequest();
    }
  }

  command error_t Tuning.set[uint8_t componentId](uint8_t key, uint16_t value) {

    if (call RequestQueue.size() < call RequestQueue.maxSize()) {
      setRequest r;
      r.componentId = componentId;
      r.key = key;
      r.value = value;
      call RequestQueue.enqueue(r);
      post serveRequest();    
      return SUCCESS;
    } else {
      return FAIL;
    }
  }
  
  command error_t Tuning.setImmediate[uint8_t componentId](uint8_t key, 
							   uint16_t value) {

    switch (key) {
    case KEY_LOCAL_LPL_SLEEP:
      call LowPowerListening.setLocalSleepInterval(value);
      return SUCCESS;

    case KEY_REMOTE_LPL_SLEEP:
      remoteLPLinterval = value;
      return SUCCESS;

    case KEY_REMOTE_OP_TIMEOUT:
      remoteOpTimeout = value;
      return SUCCESS;

    case KEY_TX_POWER:
      txPower = value;
      return SUCCESS;

#if defined(TL_LPL) || defined(TL_PACKET_LINK)
    case KEY_MSG_RETRIES:
      msgRetries = (uint8_t) value;
      return SUCCESS;

    case KEY_LPL_ACKS:
      if (value == 1) 
	lplAcks = TRUE;
      else 
	lplAcks = FALSE;
      return SUCCESS;
#endif

    default:
      return FAIL;
    }
  }

  command uint16_t Tuning.get[uint8_t componentId](uint8_t key){

    switch (key) {
    case KEY_RADIO_CONTROL:
      if (radioOn) {
	return RADIO_ON;
      } else {
	return RADIO_OFF;
      }
      
    case KEY_REMOTE_LPL_SLEEP:
      return remoteLPLinterval;

    case KEY_LOCAL_LPL_SLEEP:
      return call LowPowerListening.getLocalSleepInterval();

    case KEY_REMOTE_OP_TIMEOUT:
      return remoteOpTimeout;

    case KEY_TX_POWER:
      return txPower;

#if defined(TL_LPL) || defined(TL_PACKET_LINK)
    case KEY_MSG_RETRIES:
      return msgRetries;

    case KEY_LPL_ACKS:
      return lplAcks;
#endif

    default:
      return 0;
    }
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      post serveRequest();
      return;
    }
    radioOn = TRUE;
    signal Tuning.setDone[currentComponent](KEY_RADIO_CONTROL, RADIO_ON);
    serveNextRequest();
  }

  event void AMControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      post serveRequest();
      return;
    }
    radioOn = FALSE;
    signal Tuning.setDone[currentComponent](KEY_RADIO_CONTROL, RADIO_OFF);
    serveNextRequest();
  }
  
  default event void Tuning.setDone[uint8_t componentId](uint8_t key, 
							 uint16_t value) {}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {
  }

  event void PrintfControl.stopDone(error_t error) {
  }

  event void PrintfFlush.flushDone(error_t error) {
  }
#endif  
}
