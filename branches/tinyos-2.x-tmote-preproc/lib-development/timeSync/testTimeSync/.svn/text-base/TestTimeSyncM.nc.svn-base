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
 * *	$Id: TestTimeSyncM.nc 319 2008-03-13 11:36:17Z ben_christian $
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
 
#include "TimeSynchConf.h"

#define BOOT_TIME 32000
#define ROOT_ID 0
#define SYNCH_PERIODS 60

module TestTimeSyncM{   
  uses{
    interface Leds;
    interface Timer<TMilli> as BootTimer;
    interface Boot;
    interface GlobalTime; 
    interface TeenyLIMESystem; 

#if defined(PRINTF_SUPPORT) || defined(PRINTF_SUPPORT_TIME_SYNCH)
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif  
  }
}

implementation {
    
  NeighborTuple<uint16_t, uint16_t> neighborTuple;
  uint8_t numRuns = 0;

  event void Boot.booted(){
    
    neighborTuple = newTuple(actualField(TOS_NODE_ID),actualField(0));
    call BootTimer.startOneShot(BOOT_TIME);
    
#if defined(PRINTF_SUPPORT) || defined(PRINTF_SUPPORT_TIME_SYNCH)
    call PrintfControl.start();    
#endif
  }
  
  event void BootTimer.fired(){

    call GlobalTime.startTimer();
    if (TOS_NODE_ID == ROOT_ID){
      numRuns++;
      call GlobalTime.startSync();
    }
  }
 	
  task void tick() {

    uint16_t epoch = call GlobalTime.getGlobalTime();
    
#ifdef PRINTF_SUPPORT
    printf("e%d\n",epoch);
/*     call PrintfFlush.flush(); */
#endif
    
    if (epoch % 2 == 0) {
      call Leds.led0On();
    } else {
      call Leds.led0Off();
    }  
    
    if (epoch > (numRuns*(SYNCH_PERIODS + (uint16_t)BOOT_TIME/EPOCH_RATE))
	&& TOS_NODE_ID == ROOT_ID
	&& !call BootTimer.isRunning())  {
      call BootTimer.startOneShot(BOOT_TIME);
#ifdef PRINTF_SUPPORT
      printf ("Restart\n");
#endif
    } 
  }

  async event void GlobalTime.timeEvent(){
    post tick();
  }
 		 	        
  event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return (tuple *) &neighborTuple;
  }
  
#if defined(PRINTF_SUPPORT) || defined(PRINTF_SUPPORT_TIME_SYNCH)
  event void PrintfControl.startDone(error_t error) {
  }
  
  event void PrintfControl.stopDone(error_t error) {
  }
  
  event void PrintfFlush.flushDone(error_t error) {
  }
#endif
}

