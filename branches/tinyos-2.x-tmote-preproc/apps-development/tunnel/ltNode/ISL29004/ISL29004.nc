/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  18/03/2009
 */

/* 
 * Driver release 2.1 for the ISL29004 sensor
 */

#include "ISL29004.h"

configuration ISL29004 {
  provides interface ISL29004Read;
  provides interface ISL29004Control;
}
implementation
{
  components ISL29004C;	//MainC, 
  components BusyWaitMicroC;
  
  components new AlarmMilli16C() as Timer;

  //ISL29004C -> MainC.Boot;
  ISL29004C.Delay -> BusyWaitMicroC;
  
  ISL29004C.Timer -> Timer;

  ISL29004Read = ISL29004C;
  ISL29004Control = ISL29004C;
}

