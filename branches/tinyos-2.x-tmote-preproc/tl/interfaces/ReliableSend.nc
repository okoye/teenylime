/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 894 $
 * * DATE
 * *    $LastChangedDate: 2009-09-07 12:03:39 -0500 (Mon, 07 Sep 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: ReliableSend.nc 894 2009-09-07 17:03:39Z sguna $
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
 * Interface for sending reliable messages. 
 * In principle, this should really redefine AMSend.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

interface ReliableSend {

#ifdef SECURE_TL
  command error_t send(am_addr_t addr, message_t* msg, uint8_t len,  
            bool reliable, bool reconf);  
#else
  command error_t send(am_addr_t addr, message_t* msg, 
			uint8_t len,  bool reliable);  
#endif
  event void sendDone(message_t* msg, error_t error, bool reliableSendFailed);

  command error_t cancel(message_t* msg);

  command uint8_t maxPayloadLength();  
  command void* getPayload(message_t* msg);

/*   event void reliableSendFailed(am_addr_t addr, message_t* msg); */
}
