/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Test application for the ISL29004 sensor's driver (release 1.5)
 */

#include "Timer.h"
#include "radio.h"

module TestC
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
  uses interface SplitControl as PrintfControl;
  uses interface PrintfFlush;
  uses interface Read<uint16_t> as Read1;
  uses interface Read<uint16_t> as Read2;
  uses interface Read<uint16_t> as Read3;
  uses interface Read<uint16_t> as Read4;
  uses interface StdControl as StdControl1;
  uses interface StdControl as StdControl2;
  uses interface StdControl as StdControl3;
  uses interface StdControl as StdControl4;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation
{
  message_t pkt;
  bool busy = FALSE;
  bool started[4];

  event void Boot.booted(){
	started[0]=1;	
	started[1]=1;
	started[2]=1;
	started[3]=1;
	call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    	if (err == SUCCESS) {
		call PrintfControl.start();
    	}
    	else {
      		call AMControl.start();
    	}
  }

  event void AMControl.stopDone(error_t err) {
  }


  event void PrintfControl.stopDone(error_t error) { }

  event void PrintfFlush.flushDone(error_t error) { }
	
  event void PrintfControl.startDone(error_t error) {   
	error_t res;
	
	if (error == SUCCESS) {
		
		res = call StdControl1.start();		
		if(SUCCESS != res){
			call Leds.led1On();
			printf("Attenzione FAIL nella start1\r\n");
			started[0]=0;	
		}

		res = call StdControl2.start();		
		if(SUCCESS != res){
			call Leds.led1On();
			printf("Attenzione FAIL nella start2\r\n");
			started[1]=0;
		}

		res = call StdControl3.start();		
		if(SUCCESS != res){
			call Leds.led1On();
			printf("Attenzione FAIL nella start3\r\n");
			started[2]=0;
		}

		res = call StdControl4.start();		
		if(SUCCESS != res){
			call Leds.led1On();
			printf("Attenzione FAIL nella start4\r\n");	
			started[3]=0;
		}

		call PrintfFlush.flush();
		
		call Timer0.startPeriodic(2000);	
	} 
	else {
		call PrintfControl.start();
	}
  }
  
  event void Timer0.fired() {

	//if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RadioMsg)) == SUCCESS) {
	//	busy = TRUE;
	//}	
	call Leds.led0Toggle();
	//printf("\r\n");
	//call PrintfFlush.flush();

	//if(started[0])
	call Read1.read();
	/*if(started[1])	
		call Read2.read();
	if(started[2])		
		call Read3.read();
	if(started[3])	
		call Read4.read();*/
	
   }
   event void Read1.readDone(error_t result, uint16_t data){
	if(SUCCESS == result)	
		printf("value1: %d \r\n",data);
		if (!busy) {
			RadioMsg* btrpkt = 
			(RadioMsg*)(call Packet.getPayload(&pkt, NULL));
			btrpkt->sensor1 = data;	
		}
	else{
		call Leds.led2On();		
		printf("Attenzione errore nella read1\r\n");	
	}
	call Read2.read();
	//call PrintfFlush.flush();
   }
   event void Read2.readDone(error_t result, uint16_t data){
	if(SUCCESS == result)	
		printf("value2: %d \r\n",data);
		if (!busy) {
			RadioMsg* btrpkt = 
			(RadioMsg*)(call Packet.getPayload(&pkt, NULL));
			btrpkt->sensor2 = data;	
		}	
	else{
		call Leds.led2On();		
		printf("Attenzione errore nella read2\r\n");	
	}
	call Read3.read();
	//call PrintfFlush.flush();
   }

   event void Read3.readDone(error_t result, uint16_t data){
	if(SUCCESS == result)	
		printf("value3: %d \r\n",data);
		if (!busy) {
			RadioMsg* btrpkt = 
			(RadioMsg*)(call Packet.getPayload(&pkt, NULL));
			btrpkt->sensor3 = data;	
		}
	else{
		call Leds.led2On();		
		printf("Attenzione errore nella read3\r\n");	
	}
	call Read4.read();
	//call PrintfFlush.flush();
   }
   
   event void Read4.readDone(error_t result, uint16_t data){
	if(SUCCESS == result)	
		printf("value4: %d \r\n",data);
		if (!busy) {
			RadioMsg* btrpkt = 
			(RadioMsg*)(call Packet.getPayload(&pkt, NULL));
			btrpkt->sensor4 = data;	
		}
	else{
		call Leds.led2On();		
		printf("Attenzione errore nella read4\r\n");	
	}
	printf("\r\n");
	call PrintfFlush.flush();
	if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RadioMsg)) == SUCCESS) {
		busy = TRUE;
	}
	
   }

   event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) { return msg; }

}

