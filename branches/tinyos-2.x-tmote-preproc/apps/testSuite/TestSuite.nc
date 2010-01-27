/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 287 $
 * * DATE
 * *    $LastChangedDate: 2008-02-19 12:41:46 +0200 (Tue, 19 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: TestSuite.nc 287 2008-02-19 10:41:46Z lmottola $
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

  components PingPongPush as App1;

  components RandomC;
  components TLObjectsParsed;

  // Application component wirings
  App1.Boot -> MainC.Boot;
/*   App1.TeenyLIMEExceptions -> TeenyLimeC; */
  App1.TeenyLIMESystem -> TeenyLimeC;
  App1.TimerApp -> TimerA;
  App1.TS -> TeenyLimeC.TupleSpace[unique("TL")];

  App1.AMPacket -> ActiveMessageC;

  // Only if the Tuning interface is used
/*   App1.Tuning -> TeenyLimeC.Tuning[unique("TLTuning")]; */

  // For debugging
  App1.Leds -> LedsC;
#ifdef PRINTF_SUPPORT
  App1.PrintfControl -> PrintfC;
  App1.PrintfFlush -> PrintfC;
#endif

/*   components LocalOpsCompB as App2; 

   // Application component wirings 
   App2.Boot -> MainC.Boot; 
   App2.TS -> TeenyLimeC.TupleSpace[unique("TL")]; 
   App2.AMPacket -> ActiveMessageC; 
//   App2.TLObjects -> TLObjectsParsed; 

   // For debugging 
   App2.Leds -> LedsC; 
 #ifdef PRINTF_SUPPORT 
   App2.PrintfControl -> PrintfC; 
   App2.PrintfFlush -> PrintfC; 
 #endif 
   */

}
