/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 298 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 20:37:20 +0200 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataCollection.nc 298 2008-02-26 18:37:20Z mceriotti $
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

#include "Constants.h"
#include "TupleSpace.h"

/** 
 * Configuration for the data collection on top of a collecting tree at the
 * tree root.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration DataCollection {

  provides{
    interface CollectionDebug;
    interface CollectionTuning;
    interface CollectionInfo;
  }

  uses{
    interface Boot;
    interface TupleSpace as TS;
    interface AMPacket;
    interface Leds;

    interface TeenyLIMEExceptions;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

}

#ifdef ACTIVE_TREE_BUILDER
#warning "*** TREE ROUTING: THIS NODE IS GOING TO PROACTIVELY BUILD THE TREE ***"
#endif

implementation {

  components TreeBuilderC as TB;
  components new TimerMilliC() as TimerReliablePath;
#ifdef ACTIVE_TREE_BUILDER
  components new TimerMilliC() as TimerTree;
#endif
  components DataForwarderC as DF;
  components TLObjectsParsed;

  components FakeRetriesInfoC as Retries;

  DF.RetriesInfo -> Retries.RetriesInfo;

  CollectionInfo = DF;
  CollectionDebug = DF;
  CollectionTuning = DF;
  TB.TS = TS;
  TeenyLIMEExceptions = DF;

  TB.Boot = Boot;
  TB.AMPacket = AMPacket;

#ifdef ACTIVE_TREE_BUILDER
  TB.TimerTree -> TimerTree;
#endif
  
  DF.TS = TS;
  DF.Boot = Boot;
  DF.AMPacket = AMPacket;
  DF.TLObjects -> TLObjectsParsed;
  DF.TreeConnection -> TB.TreeConnection;
  DF.TimerReliablePath -> TimerReliablePath;

  // For debugging
  TB.Leds = Leds;
  DF.Leds = Leds;
#ifdef PRINTF_SUPPORT
  DF.PrintfControl = PrintfControl;
  DF.PrintfFlush = PrintfFlush;
  TB.PrintfControl = PrintfControl;
  TB.PrintfFlush = PrintfFlush;
#endif
}
