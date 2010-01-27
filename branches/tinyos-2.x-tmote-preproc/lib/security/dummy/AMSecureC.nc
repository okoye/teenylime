/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 287 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 12:41:46 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *    $Id: AMSecureC.nc 287 2008-02-19 10:41:46Z sguna $
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
 * Dummy security component.
 *
 * @author Stefan Guna 
 * <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 *
 */

generic configuration AMSecureC(am_id_t AMId) {
  provides {
    interface AMSend;
    interface Receive;
    interface Receive as Snoop;
  }
}

implementation {
  components new AMSenderC(AMId);
  components new AMReceiverC(AMId);
  components new AMSnooperC(AMId);

  AMSend = AMSenderC;
  Receive = AMReceiverC;
  Snoop = AMSnooperC;
}