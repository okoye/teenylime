/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 41 $
 * * DATE
 * *    $LastChangedDate: 2007-05-30 03:28:32 -0500 (Wed, 30 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: Benchmark.nc 41 2007-05-30 08:28:32Z lmottola $
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

includes Constants;

/**
 * Configuration file for a benchmark application.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define CONTROLLER

configuration Benchmark {
}

implementation {
  components Main, TimerC, TeenyLimeC, ReactiveNode, ProactiveNode, Controller;

    Main.StdControl -> TimerC.StdControl;
    Main.StdControl -> TeenyLimeC.StdControl;

#ifdef REACTIVE
    Main.StdControl -> ReactiveNode.StdControl; 
    ReactiveNode.TS -> TeenyLimeC.TupleSpace[unique("TL")]; 
    ReactiveNode.TeenyLIMESystem -> TeenyLimeC;
    ReactiveNode.PeriodicTimer -> TimerC.Timer[unique("Timer")];
#endif

#ifdef PROACTIVE
    Main.StdControl -> ProactiveNode.StdControl; 
    ProactiveNode.TS -> TeenyLimeC.TupleSpace[unique("TL")];
    ProactiveNode.TeenyLIMESystem -> TeenyLimeC;
#endif

#ifdef CONTROLLER
    Main.StdControl -> Controller.StdControl; 
    Controller.TS -> TeenyLimeC.TupleSpace[unique("TL")];
    Controller.TeenyLIMESystem -> TeenyLimeC;
#endif
}

