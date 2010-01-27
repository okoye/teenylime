/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 1 $
 * * DATE
 * *    $LastChangedDate: 2007-04-27 09:33:25 -0500 (Fri, 27 Apr 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: MutationRoutingC.nc 1 2007-04-27 14:33:25Z lmottola $
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
 * Configuration file for mutation routing.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

configuration MutationRoutingC {

  provides {
    interface MutationRouting;
    interface StdControl;
  }
}

implementation {
  components TimerC, TeenyLimeC, MutationRoutingM, TokenMutualExclusion;

    MutationRouting = MutationRoutingM;
    StdControl = TimerC.StdControl;
    StdControl = TeenyLimeC.StdControl;
    StdControl = MutationRoutingM.StdControl;
    MutationRoutingM.TS -> TeenyLimeC.TupleSpace[unique("Component")];
    MutationRoutingM.TimeOut -> TimerC.Timer[unique("Timer")];
    MutationRoutingM.LocalTime -> TimerC.Timer[unique("Timer")];
    MutationRoutingM.TeenyLIMESystem -> TeenyLimeC.TeenyLIMESystem;
    MutationRoutingM.MutualExclusion -> TokenMutualExclusion;
}

