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



configuration SerialForwarderC {
}

implementation {
  components MainC;
  components SerialForwarderP;
  components TeenyLimeC;
  components LedsC;
  components TLObjectsParsed;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_SERIAL_MSG);
  
  SerialForwarderP.Boot -> MainC;
  SerialForwarderP.TLObjects -> TLObjectsParsed;
  SerialForwarderP -> TeenyLimeC.TupleSpace[unique("TL")];
  SerialForwarderP.SerialSend -> SerialAMSenderC;
  SerialForwarderP.SerialControl -> SerialActiveMessageC;
  SerialForwarderP.Leds -> LedsC;
}


