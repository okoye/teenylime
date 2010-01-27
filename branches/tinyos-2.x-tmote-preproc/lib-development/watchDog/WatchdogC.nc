/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 818 $
 * * DATE
 * *    $LastChangedDate: 2009-05-07 04:32:52 -0500 (Thu, 07 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: WatchdogC.nc 818 2009-05-07 09:32:52Z mceriotti $
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

/** 
 *  Watchdog component.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration WatchdogC {
  provides interface Watchdog;
}

implementation {
  components WatchdogP, MainC;
  components new TimerMilliC() as ResetTimer;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif

  WatchdogP.Boot -> MainC;
  WatchdogP.ResetTimer -> ResetTimer;
  Watchdog = WatchdogP.Watchdog;

#ifdef PRINTF_SUPPORT
  WatchdogP.PrintfControl -> PrintfC;
  WatchdogP.PrintfFlush -> PrintfC;
#endif
}
