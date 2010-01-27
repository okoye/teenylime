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
  components MainC, TestC, LedsC,Fm25lcSpiC;
  components new TimerMilliC() as Timer0;
  components PrintfC;




  TestC -> MainC.Boot;

  TestC.Timer0 -> Timer0;
  TestC.Leds -> LedsC;

  TestC.PrintfControl -> PrintfC;
  TestC.PrintfFlush -> PrintfC;

  TestC.Fm25lcSpi -> Fm25lcSpiC;

  TestC.Resource -> Fm25lcSpiC;
  
}
