/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 296 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:31:13 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataCollection.nc 296 2008-02-26 18:31:13Z mceriotti $
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
 * Configuration for the data collection on top of a collecting tree.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 *
 */

configuration DataCollection {

  provides{
    interface CollectionInfo;
  }

  uses{
    interface Boot;
    interface TupleSpace as TS;
    interface AMPacket;
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }

}

implementation {

  components TreeBuilderC as TB;
  components DataForwarderC as DF;
  components LedsC;

  components new TimerMilliC() as TimerT;
  components new TimerMilliC() as TimerD;

  components RandomC;

  CollectionInfo = DF;
  TB.TS = TS;
  DF.TS = TS;

  TB.Boot = Boot;
  DF.Boot = Boot;
  TB.TimerTree -> TimerT;
  TB.TimerDelay -> TimerD;
  TB.Random -> RandomC;
  TB.AMPacket = AMPacket;
  DF.AMPacket = AMPacket;
  DF.TreeConnection -> TB.TreeConnection;

  // For debugging
  TB.Leds -> LedsC;
  DF.Leds -> LedsC;

#ifdef PRINTF_SUPPORT
  TB.PrintfControl = PrintfControl;
  TB.PrintfFlush = PrintfFlush;
  DF.PrintfControl = PrintfControl;
  DF.PrintfFlush = PrintfFlush;
#endif
}
