/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Test application for the ISL29004 sensor's driver (release 1.5)
 */


configuration TestAppC
{
}
implementation
{
  components MainC, TestC, LedsC, ISL29004;
  components new TimerMilliC() as Timer0;
  components PrintfC;

  components ActiveMessageC;
  components new AMSenderC(AM_RADIO);
  components new AMReceiverC(AM_RADIO);

  TestC.Packet -> AMSenderC;
  TestC.AMPacket -> AMSenderC;
  TestC.AMControl -> ActiveMessageC;
  TestC.AMSend -> AMSenderC;
  TestC.Receive -> AMReceiverC;

  TestC -> MainC.Boot;

  TestC.Timer0 -> Timer0;
  TestC.Leds -> LedsC;

  TestC.PrintfControl -> PrintfC;
  TestC.PrintfFlush -> PrintfC;
  TestC.Read1 -> ISL29004.Read1;
  TestC.Read2 -> ISL29004.Read2;
  TestC.Read3 -> ISL29004.Read3;
  TestC.Read4 -> ISL29004.Read4;
  TestC.StdControl1 -> ISL29004.StdControl1;
  TestC.StdControl2 -> ISL29004.StdControl2;
  TestC.StdControl3 -> ISL29004.StdControl3;
  TestC.StdControl4 -> ISL29004.StdControl4;
}
