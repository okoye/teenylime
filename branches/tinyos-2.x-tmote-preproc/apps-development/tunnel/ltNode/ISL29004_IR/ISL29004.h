/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  09/11/2009
 */

/* 
 * Definitions for the ISL29004 sensor's driver(infrared version)
 */

#ifndef ISL29004_H
#define ISL29004_H

// On 3MATE! T.R.I.T.On's sensors board
// LIGHT1 = U1
// LIGHT2 = U2
// LIGHT3 = U3
// LIGHT4 = U4
// On the same I2C bus the max number of ISL29004 sensors is 4

#define SENSOR1			0x01
#define SENSOR2			0x02
#define SENSOR3			0x04
#define SENSOR4			0x08
#define IR_SENSOR1		0x10
#define IR_SENSOR2		0x20
#define IR_SENSOR3		0x40
#define IR_SENSOR4		0x80

#define ALL_SENSORS             0xFF

#define SENSORS_SUCCESS		0x00
#define SENSOR1_ERROR		0x01
#define SENSOR2_ERROR		0x02
#define SENSOR3_ERROR		0x04
#define SENSOR4_ERROR		0x08

// Sensors senttings

// Conversion delay (ms)
#define CONVERSION_DELAY	120//5//120//30//120

// Working range (lux)
//#define RANGE_64K
#define RANGE_16K
//#define RANGE_4K
//#define RANGE_1K

// n-bit resolution
#define NBIT_16
//#define NBIT_12

#endif


