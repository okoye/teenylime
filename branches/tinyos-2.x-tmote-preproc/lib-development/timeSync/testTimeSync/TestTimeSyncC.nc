/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 319 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 13:36:17 +0200 (Thu, 13 Mar 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: ben_christian $
 * *
 * *	$Id: TestTimeSyncC.nc 319 2008-03-13 11:36:17Z ben_christian $
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
 
configuration TestTimeSyncC {
}

implementation {

  components MainC, TimeSyncC, TeenyLimeC, LedsC ,TestTimeSyncM as App;
  components new TimerMilliC() as Boot;

#if defined(PRINTF_SUPPORT) || defined(PRINTF_SUPPORT_TIME_SYNCH)
  components PrintfC;
  App.PrintfControl -> PrintfC;
  App.PrintfFlush -> PrintfC;
#endif
    
  App -> MainC.Boot;
  App.TeenyLIMESystem -> TeenyLimeC;   
  App.BootTimer -> Boot;
  App.Leds -> LedsC;
  App.GlobalTime -> TimeSyncC;	
}
