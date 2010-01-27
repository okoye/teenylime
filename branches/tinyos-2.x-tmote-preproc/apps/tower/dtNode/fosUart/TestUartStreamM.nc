#include "msp430usart.h"
#include "UartMsg.h"

#ifdef PRINTF_SUPPORT
#include "printf.h"
#endif

#define SENSE_TIMER 3000

module TestUartStreamM {

  uses {
    interface Boot;
    interface UartStream;
    interface Leds;
    interface Resource as UartResource;

    interface SplitControl as AMControl;
    interface Receive;
    interface AMSend;
    interface Packet;

    interface Timer<TMilli> as SenseTimer;

#ifdef PRINTF_SUPPORT
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
#endif
  }
}

implementation {

  bool locked = FALSE;
  uint8_t singleReq[1] = "l";
  uint8_t bufferReq[1] = "b";
  uint8_t recv[81];
  message_t uartData;
  uint16_t counter = 0;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {

    if (err == SUCCESS) {
#ifdef PRINTF_SUPPORT
	call PrintfControl.start();
#else
	call SenseTimer.startPeriodic(SENSE_TIMER);
#endif
    } else {
      call AMControl.start();
    }
  }

  task void sendStream() {
    // Sending request message
    if (counter % 2 == 0) {
      call UartStream.send(singleReq,sizeof(singleReq));
    } else {
      call UartStream.send(bufferReq,sizeof(bufferReq));    
    }
  }

  event void UartResource.granted() {

    // UART resource obtained, running state signaling
    call Leds.led2On();
    post sendStream();
  }

  async event void UartStream.sendDone(uint8_t* buf, uint16_t len, 
				       error_t error){
    uint8_t i;

    if (error != SUCCESS) {
      post sendStream();
    } else {
      // Waiting for the answer
      call Leds.led2Off();
      call Leds.led0On();
      for (i=0; i<81; i++) {
	recv[i] = 0;
      }
      call UartStream.enableReceiveInterrupt();    
      if (counter % 2 == 0) {
	call UartStream.receive(recv, 3);
      } else {
	call UartStream.receive(recv, 81);      
      }
    }
  }

  task void sendData() {

    uint8_t i;
    call Leds.led0Off();

    if (!locked) {
      UartMsg* uartDataMsg = (UartMsg*) call Packet.getPayload(&uartData, NULL);

      for (i=0; i<81; i++) {
	atomic uartDataMsg->data[i] = recv[i];
      }

      locked = TRUE;
      if (call AMSend.send(AM_BROADCAST_ADDR, &uartData, 
			   sizeof(UartMsg)) != SUCCESS) {
	locked = FALSE;
      }
    } else {
      post sendData();
    }
  }
  
  event void SenseTimer.fired() {
    atomic counter++;
    call UartResource.request();
  }

  async event void UartStream.receiveDone(uint8_t* buf, 
					  uint16_t len, 
					  error_t error ) {
    post sendData();
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&uartData == bufPtr) {
      locked = FALSE;
      call UartResource.release();
    }
  }

  event message_t* Receive.receive(message_t* bufPtr,
				   void* payload, uint8_t len) {


#ifdef PRINTF_SUPPORT
    UartMsg* uartMsg = (UartMsg*) payload;
    uint16_t data[40];
    uint8_t i;

    for (i=0; i<40; i++) {
      data[i] = (uartMsg->data[(i*2)+1] << 8) + uartMsg->data[(i*2)+2];
    } 

    call Leds.led0Toggle();

    if (data[39] != 0) {
      uint32_t sum = 0;
      uint16_t avg;
      for (i=0; i<40; i++) {
	sum += data[i];
      } 
      avg = (uint32_t) sum/40;
      printf("M%d\n", avg); 
    } else {
      printf("I%d,%d,%d,%d\n",
	     uartMsg->data[0],
	     uartMsg->data[1],
	     uartMsg->data[2],
	     data[0]);
    }
    call PrintfFlush.flush();
#endif

    return bufPtr;
  }

  event void AMControl.stopDone(error_t err) {}

  async event void UartStream.receivedByte(uint8_t byte){}

#ifdef PRINTF_SUPPORT
  event void PrintfControl.startDone(error_t error) {}
  
  event void PrintfControl.stopDone(error_t error) {}
  
  event void PrintfFlush.flushDone(error_t error) {}
#endif
}  
