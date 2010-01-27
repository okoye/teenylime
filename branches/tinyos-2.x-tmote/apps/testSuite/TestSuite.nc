/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 287 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 04:41:46 -0600 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TestSuite.nc 287 2008-02-19 10:41:46Z lmottola $
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

configuration TestSuite {}

implementation {

  components MainC, TeenyLimeC;
  components LedsC;

#ifdef PRINTF_SUPPORT
  components PrintfC;
#endif
  
  components ActiveMessageC;
  components new TimerMilliC() as TimerA;
  components new TimerMilliC() as TimerB;

  components HammerNail as App1;

  components RandomC;

  // Application component wirings
  App1.Boot -> MainC.Boot;
  App1.TeenyLIMESystem -> TeenyLimeC;
  App1.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  App1.TimerApp -> TimerA;
  App1.AMPacket -> ActiveMessageC;
  App1.Random -> RandomC;

  // For debugging
  App1.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  App1.PrintfControl -> PrintfC;
  App1.PrintfFlush -> PrintfC;
#endif

/*   // Second application component wirings */
/*   components LocalGroupOpsSideB as App2; */

/*   App2.Boot -> MainC.Boot; */
/*   App2.TS -> TeenyLimeC.TupleSpace[unique("TL")]; */
/*   App2.AMPacket -> ActiveMessageC; */
/*   App2.Random -> RandomC; */
/*   App2.TimerAppB -> TimerB; */

/*   // For debugging */
/*   App2.Leds -> LedsC; */
/* #ifdef PRINTF_SUPPORT */
/*   App2.PrintfControl -> PrintfC; */
/*   App2.PrintfFlush -> PrintfC; */
/* #endif */
}
