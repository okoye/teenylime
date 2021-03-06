/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 319 $
 * * DATE
 * *    $LastChangedDate: 2008-03-13 06:36:17 -0500 (Thu, 13 Mar 2008) $
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
 
includes Timer;
module TestTimeSyncM{   
  uses{
    interface Leds;
    interface Timer<TMilli> as TimerSinc;
    interface Boot;
    interface GlobalTime; 
        interface TeenyLIMESystem; 
#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif  
  }
}implementation
 {
#ifndef TIMETOSYNC
#define TIMETOSYNC   50 
#endif
    
   int32_t time=150; 
   bool start;
   tuple neighborTuple;
   bool avviato;	
   event void Boot.booted(){
#ifdef PRINTF_SUPPORT
     call PrintfControl.start();    
#endif
     //al nodo root non viene segnalato l'evento synced  
     start = FALSE;
     
     neighborTuple = newTuple(2,actualField_uint16(TOS_NODE_ID),actualField_uint16(0));
     avviato=FALSE;
     call TimerSinc.startOneShot(5000);
   }
  
   event void TimerSinc.fired(){
   	call Leds.led2Toggle();
	   if (avviato==FALSE){
		 avviato=TRUE;
	     call GlobalTime.startTimer();
	     if (TOS_NODE_ID==0){
	 	 	call GlobalTime.startSync(145);
			call Leds.led1Toggle();
			}
	   }
   }
 	
   event void GlobalTime.timeEvent(){
     uint16_t GTime = 0;
     call GlobalTime.getGlobalTime(&GTime);
     if (GTime>time){
       call Leds.led0Off();
       time += TIMETOSYNC;
       if (start == TRUE){
	 start = FALSE;
	 call TimerSinc.stop();
       }else{
	 start = TRUE;
	 call TimerSinc.startPeriodic(500);
       }	
     }
     	call Leds.led0Toggle();
   }
 		 	        
   event void GlobalTime.synced(){}
    
   event void GlobalTime.lostSynced(){}
   
   event tuple* TeenyLIMESystem.reifyNeighborTuple() {
    return &neighborTuple;
   }
   
#ifdef PRINTF_SUPPORT
   event void PrintfControl.startDone(error_t error) {
   }

   event void PrintfControl.stopDone(error_t error) {
   }

   event void PrintfFlush.flushDone(error_t error) {
   }
#endif
}

