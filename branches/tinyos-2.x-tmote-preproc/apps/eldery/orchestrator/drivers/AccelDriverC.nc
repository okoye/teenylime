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
 * 
 * @author Gianalberto Chini
 * <a href="mailto:gianalberto.chini@gmail.com">gianalberto.chini@gmail.com</a>
 * 
 */

configuration AccelDriverC {
  provides interface Read<uint16_t> as AccelReadX;
  provides interface Read<uint16_t> as AccelReadY;
  provides interface Read<uint16_t> as AccelReadZ;  
}

implementation {

  components MainC;

  components AccelDriverP;
  components new AdcReadClientC() as AdcX;
  components new AdcReadClientC() as AdcY;
  components new AdcReadClientC() as AdcZ; 
  
  AccelReadX = AdcX;
  AccelReadY = AdcY;
  AccelReadZ = AdcZ;  
  AccelDriverP.AdcConfX <- AdcX;
  AccelDriverP.AdcConfY <- AdcY;
  AccelDriverP.AdcConfZ <- AdcZ; 
}

