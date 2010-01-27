/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Test application for the ISL29004 sensor's driver (release 1.5)
 */

#include "Timer.h"
#include "Fm25lc.h"

module TestC
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
  uses interface SplitControl as PrintfControl;
  uses interface PrintfFlush;
  
  uses interface Fm25lcSpi;
  uses interface Resource;

}
implementation
{

  uint8_t rd_buffer[10];
  uint8_t wr_buffer[10];
  
  event void Boot.booted(){
	call PrintfControl.start();	
  }

  

  event void PrintfControl.stopDone(error_t error) { }

  event void PrintfFlush.flushDone(error_t error) { }
	
  event void PrintfControl.startDone(error_t error) {   
	
	
	if (error == SUCCESS) {
		
		//printf("Attenzione FAIL nella start4\r\n");
		//call PrintfFlush.flush();
		
		//call Timer0.startPeriodic(2000);
		call Leds.led0Toggle();
		call Leds.led1Off();
		call Leds.led2Off();
		call Resource.request();
			
	} 
	else {
		call PrintfControl.start();
	}
  }
  
  event void Timer0.fired() {		
	call Leds.led0Toggle();
	call Resource.request();
  }


  event void Resource.granted() {
	/*if(call Fm25lcSpi.pageProgram( 100, "ciaooo", 4 ))
		;*/
	if(call Fm25lcSpi.read( 0, rd_buffer,1))
		;

  }

  async event void Fm25lcSpi.readDone( Fm25lc_addr_t addr, uint8_t* buf, Fm25lc_len_t len, error_t error ){
	atomic{	
	if(0 == buf[0]){
		call Leds.led1On();
		wr_buffer[0]=1;
		if(call Fm25lcSpi.pageProgram( 0, wr_buffer, 1 ))
			;
	}
	else{
		call Leds.led2On();
		wr_buffer[0]=0;
		if(call Fm25lcSpi.pageProgram(0, wr_buffer, 1 ))
			;

	}
	}
	//call Resource.release();
  }

  async event void Fm25lcSpi.computeCrcDone( uint16_t crc, Fm25lc_addr_t addr,Fm25lc_len_t len, error_t error ){}
  
  async event void Fm25lcSpi.pageProgramDone( Fm25lc_addr_t addr, uint8_t* buf,Fm25lc_len_t len, error_t error ){
	//if(call Fm25lcSpi.read( 100, rd_buffer,4 ))
	//	;
	call Resource.release();

  }
  
  async event void Fm25lcSpi.sectorEraseDone( uint8_t sector, error_t error ){}
  async event void Fm25lcSpi.bulkEraseDone( error_t error ){}



}

