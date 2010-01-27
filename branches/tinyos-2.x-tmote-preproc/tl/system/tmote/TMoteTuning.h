/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 859 $
 * * DATE
 * *    $LastChangedDate: 2009-06-18 09:20:22 -0500 (Thu, 18 Jun 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TMoteTuning.h 859 2009-06-18 14:20:22Z lmottola $
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

#ifndef TMOTE_TUNING_H
#define TMOTE_TUNING_H

/* Allows for queueing requests */
typedef struct setRequest {
  uint8_t componentId;
  uint8_t key;
  uint16_t value;
} setRequest;

/* Key definitions */
#define KEY_RADIO_CONTROL 0  
#define KEY_LOCAL_LPL_SLEEP 1 // Immediate tuning
#define KEY_REMOTE_LPL_SLEEP 2 // Immediate tuning
#define KEY_REMOTE_OP_TIMEOUT 3  // Immediate tuning
#define KEY_TX_POWER 4 // Immediate tuning
#define KEY_MSG_RETRIES 5 // Immediate tuning
#define KEY_LPL_ACKS 6 // Immediate tuning

/* Value definitions (when applicabile) */
#define RADIO_ON 0
#define RADIO_OFF 1

#endif
