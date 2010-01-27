/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  09/11/2009
 */

/* 
 * Driver release for the ISL29004 sensor (infrared version)
 */

#include "ISL29004.h"

configuration ISL29004
{
  provides interface ISL29004Read<uint16_t> as Read;

  provides interface ISL29004Control as StdControl;
}
implementation
{
  components ISL29004C;	//MainC, 
  components BusyWaitMicroC;
  
  components new AlarmMilli16C() as Timer;

  //ISL29004C -> MainC.Boot;
  ISL29004C.Delay -> BusyWaitMicroC;
  
  ISL29004C.Timer -> Timer;
  Read = ISL29004C.Read;

  StdControl = ISL29004C.StdControl;
}

