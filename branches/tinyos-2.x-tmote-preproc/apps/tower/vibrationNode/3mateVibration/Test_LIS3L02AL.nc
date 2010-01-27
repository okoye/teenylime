// $Id: Test_LIS3L02AL.nc 902 2006-08-02 18:38:24Z lzuech $

#define ACCEL_AM_ID 5

configuration Test_LIS3L02AL {
}

implementation {

  components MainC;

  components Test_LIS3L02AL_P;
  components LedsC;
  components new AdcReadClientC() as AdcX;
  components new AdcReadClientC() as AdcY;
  components new AdcReadClientC() as AdcZ;
  components new TimerMilliC() as Timer0;

  components new AMSenderC(ACCEL_AM_ID);
  components new AMReceiverC(ACCEL_AM_ID);
  components ActiveMessageC;

  components PrintfC;

  MainC.Boot <- Test_LIS3L02AL_P.Boot;
  Test_LIS3L02AL_P.Leds -> LedsC;
  Test_LIS3L02AL_P.AccelReadX -> AdcX;
  Test_LIS3L02AL_P.AccelReadY -> AdcY;
  Test_LIS3L02AL_P.AccelReadZ -> AdcZ;
  Test_LIS3L02AL_P.AdcConfX <- AdcX;
  Test_LIS3L02AL_P.AdcConfY <- AdcY;
  Test_LIS3L02AL_P.AdcConfZ <- AdcZ;
  Test_LIS3L02AL_P.SenseTimer -> Timer0;
  
  Test_LIS3L02AL_P.Receive -> AMReceiverC;
  Test_LIS3L02AL_P.AMSend -> AMSenderC;
  Test_LIS3L02AL_P.AMControl -> ActiveMessageC;
  Test_LIS3L02AL_P.AMPacket -> AMSenderC;
  Test_LIS3L02AL_P.Packet -> AMSenderC;

  Test_LIS3L02AL_P.PrintfControl -> PrintfC;
  Test_LIS3L02AL_P.PrintfFlush -> PrintfC;
}

