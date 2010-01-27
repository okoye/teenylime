/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Driver release 1.5 for the ISL29004 sensor
 */

#include "ISL29004.h"

configuration ISL29004 {
  #ifdef LIGHT1
  	provides interface Read<uint16_t> as Read1;
	provides interface StdControl as StdControl1;
  #endif

  #ifdef LIGHT2
  	provides interface Read<uint16_t> as Read2;
	provides interface StdControl as StdControl2;
  #endif

  #ifdef LIGHT3
  	provides interface Read<uint16_t> as Read3;
	provides interface StdControl as StdControl3;
  #endif

  #ifdef LIGHT4
  	provides interface Read<uint16_t> as Read4;
	provides interface StdControl as StdControl4;
  #endif

}
implementation {
  components ISL29004C;	//MainC, 
  components BusyWaitMicroC;
  
  #ifdef LIGHT1
  	components new AlarmMilli16C() as Timer1;
  #endif
  
  #ifdef LIGHT2
  	components new AlarmMilli16C() as Timer2;
  #endif
  
  #ifdef LIGHT3
  	components new AlarmMilli16C() as Timer3;
  #endif

  #ifdef LIGHT4
  	components new AlarmMilli16C() as Timer4;
  #endif

  //ISL29004C -> MainC.Boot;
  ISL29004C.Delay -> BusyWaitMicroC;
  
  #ifdef LIGHT1
  	ISL29004C.Timer1 -> Timer1;
       	Read1 = ISL29004C.Read1;
	StdControl1 = ISL29004C.StdControl1;
  #endif

  #ifdef LIGHT2  
	ISL29004C.Timer2 -> Timer2;
	Read2 = ISL29004C.Read2;
	StdControl2 = ISL29004C.StdControl2;
  #endif

  #ifdef LIGHT3
  	ISL29004C.Timer3 -> Timer3;
	Read3 = ISL29004C.Read3;
	StdControl3 = ISL29004C.StdControl3;
  #endif

  #ifdef LIGHT4
	ISL29004C.Timer4 -> Timer4;
	Read4 = ISL29004C.Read4;
	StdControl4 = ISL29004C.StdControl4;
  #endif

}

