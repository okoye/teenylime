#include "msp430usart.h"
#include "UartMsg.h"

configuration TestUartStream {
}

implementation {

  components MainC, TestUartStreamM, LedsC;
  components new Msp430Uart1C();
  components new AMSenderC(UART_AM_ID);
  components new AMReceiverC(UART_AM_ID);
  components new TimerMilliC() as Timer0;
  components ActiveMessageC;
  
  MainC.Boot <- TestUartStreamM;

  TestUartStreamM.UartResource -> Msp430Uart1C.Resource;
  TestUartStreamM.UartStream -> Msp430Uart1C.UartStream;

  TestUartStreamM.AMControl -> ActiveMessageC;
  TestUartStreamM.Receive -> AMReceiverC;
  TestUartStreamM.AMSend -> AMSenderC;
  TestUartStreamM.Packet -> AMSenderC;

  TestUartStreamM.SenseTimer -> Timer0;
 
  TestUartStreamM.Leds -> LedsC;

#ifdef PRINTF_SUPPORT
  components PrintfC;
  TestUartStreamM.PrintfControl -> PrintfC;
  TestUartStreamM.PrintfFlush -> PrintfC;
#endif
}
