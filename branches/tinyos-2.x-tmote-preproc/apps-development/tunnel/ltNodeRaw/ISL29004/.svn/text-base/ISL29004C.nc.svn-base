/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  18/03/2009
 */

/* 
 * Driver release 2.0 for the ISL29004 sensor
 */

//////////////////////////////////////////////////////////
//	Da pensare:					//
//	- nella nack non mettere initialize ma solo	//
//		setclock				//
//    - nel boot mettere in power down i sensori?     	//
//    - nella stop mettere in reset i sensori?   	//
//    - togliere or DONE				//
//////////////////////////////////////////////////////////

#include "Timer.h"
#include "ISL29004.h"

#define SENSORS_SUCCESS		0x00
#define SENSOR1_ERROR		0x01
#define SENSOR2_ERROR		0x02
#define SENSOR3_ERROR		0x04
#define SENSOR4_ERROR		0x08

// Sensor's addresses definitions

#define ADDR1 0x88	// 0x44 * 2

#define ADDR2 0x8A	// 0x45 * 2

#define ADDR3 0x8C	// 0x46 * 2

#define ADDR4 0x8E	// 0x47 * 2

// Energy saving
#define POWER_SAVING_MODE

// Definitions of the I/O pins associated with the I2C bus 
TOSH_ASSIGN_PIN(SDA, 6, 3);
TOSH_ASSIGN_PIN(SCL, 6, 2);

// Range setting

#ifdef RANGE_64K
	#define RANGE 0x0C
#endif
#ifdef RANGE_16K
	#define RANGE 0x08
#endif
#ifdef RANGE_4K
	#define RANGE 0x04
#endif
#ifdef RANGE_1K
	#define RANGE 0x00
#endif

// Number of bit of resolution

#ifdef NBIT_16
	#define NUMBER_OF_BIT	0x80//0x88
#endif
#ifdef NBIT_12
	#define NUMBER_OF_BIT	0x81//0x89
#endif

// Power down
#define POWER_DOWN	0x40

// Diode selection
#define DONE		0x00
#define DTWO		0x04
#define DONE_DTWO	0x08

module ISL29004C {
  //uses interface Boot;
  uses interface BusyWait<TMicro,uint16_t> as Delay;  
  uses interface Alarm<TMilli,uint16_t> as Timer;

  provides interface ISL29004Read;
  provides interface ISL29004Control;
}

implementation {
	
  // wait when triggering the clock
 void wait() {
	call Delay.wait(5);
  }

  // hardware pin functions
  
  void MAKE_CLOCK_OUTPUT() { TOSH_MAKE_SCL_OUTPUT(); }
  void MAKE_CLOCK_INPUT() { TOSH_MAKE_SCL_INPUT(); }
  char GET_CLOCK() { return TOSH_READ_SCL_PIN(); }
  void SET_CLOCK() { MAKE_CLOCK_INPUT(); }
  void CLEAR_CLOCK() { MAKE_CLOCK_OUTPUT(); TOSH_CLR_SCL_PIN(); }

  void MAKE_DATA_OUTPUT() { TOSH_MAKE_SDA_OUTPUT(); }
  void MAKE_DATA_INPUT() { TOSH_MAKE_SDA_INPUT(); }
  char GET_DATA() { return TOSH_READ_SDA_PIN(); }
  void SET_DATA() { MAKE_DATA_INPUT(); }
  void CLEAR_DATA() { MAKE_DATA_OUTPUT(); TOSH_CLR_SDA_PIN(); }


  void clock_high() {
    SET_CLOCK();
    while (!GET_CLOCK()) ;
  }

  void pulse_clock() {
    wait();
    clock_high();
    wait();
    CLEAR_CLOCK();
  }

   uint8_t read_bit() {
    uint8_t i;
	
    SET_DATA();
    wait();
    clock_high();
    wait();
    i = GET_DATA();
    CLEAR_CLOCK();
    return i;
  }

  uint8_t i2c_read(){
    uint8_t data = 0;
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	data = data << 1;
	if (read_bit())
	  data |= 0x1;
      }
    return data;
  }

  void i2c_write(uint8_t c) {
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	if (c & 0x80)
	  SET_DATA();
	else
	  CLEAR_DATA();
	pulse_clock();
	c = c << 1;
      }
  }

  void i2c_start() {
    SET_DATA();
    clock_high();
    wait();
    CLEAR_DATA();
    wait();
    CLEAR_CLOCK();
  }

  void i2c_ack() {
    CLEAR_DATA();
    pulse_clock();
  }

  uint8_t i2c_nack() {
    return read_bit();
  }

  void i2c_end() {
    CLEAR_DATA();
    wait();
    clock_high();
    wait();
    SET_DATA();
  }
  
  void initialize(){
	SET_DATA();	
	SET_CLOCK();
	
  }
  uint8_t write_byte(uint8_t devAdd, uint8_t add, uint8_t data){
	atomic{	
		i2c_start();
	    	i2c_write(devAdd);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_write(add);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_write(data);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_end();
		return 0;
	}
  }

  uint8_t read_byte(uint8_t devAdd, uint8_t add, uint8_t * buffer){
	
	atomic{	
		i2c_start();
	    	i2c_write(devAdd);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_write(add);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_end();
		i2c_start();
	    	i2c_write(devAdd+1);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		*buffer=i2c_read();
		i2c_end();

		return 0;
	}	
  }


  uint8_t read_word(uint8_t devAdd, uint8_t add, uint16_t * buffer){
	uint8_t LSB,MSB;
	
	atomic{	
		i2c_start();
	    	i2c_write(devAdd);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_write(add);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		i2c_end();
		
		i2c_start();
	    	i2c_write(devAdd+1);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		LSB=i2c_read();
		i2c_end();
			
		
		i2c_start();
	    	i2c_write(devAdd+1);
		if(i2c_nack()){
			initialize();			
			return 1;
		}
		MSB=i2c_read();
		i2c_end();
	}
	/*	old to signed int
	if(0x80 & MSB)
	{	
		MSB &= 0x3F;//0x7F;
		*buffer= -(((int16_t) LSB) + (((int16_t)MSB)<<8));
	}
	else
	{
		*buffer=((int16_t) LSB) + (((int16_t)MSB)<<8);
	}*/		
	
	*buffer = ((uint16_t)MSB)<<8 | LSB;

	return 0;	
  }
 
  norace uint8_t result;

  norace uint8_t L_state;

  norace uint16_t data_read1;
  norace uint16_t data_read2;
  norace uint16_t data_read3;
  norace uint16_t data_read4;

  norace uint8_t sensors;
  
  uint8_t sensors_started;


  task void readDone_task(){atomic{signal ISL29004Read.readDone(result,data_read1,data_read2,data_read3,data_read4);}}

  command uint8_t ISL29004Read.read(uint8_t set_sensors)
  {
	//uint8_t return_value = SENSORS_SUCCESS;
	result = SENSORS_SUCCESS;
	
	sensors = set_sensors;

	data_read1 = 0;
	data_read2 = 0;
	data_read3 = 0;
	data_read4 = 0;
		 	
	if( (sensors & SENSOR1) && (sensors_started & SENSOR1) )
	{		
		if(write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE))
			result |= SENSOR1_ERROR;
	}
	else
		result |= SENSOR1_ERROR;
		
	if( (sensors & SENSOR2) && (sensors_started & SENSOR2) )
	{
		if(write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE))
			result |= SENSOR2_ERROR;
	}
	else
		result |= SENSOR2_ERROR;
		
	if( (sensors & SENSOR3) && (sensors_started & SENSOR3) )
	{	
		if(write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE))
			result |= SENSOR3_ERROR;
	}
	else
		result |= SENSOR3_ERROR;
		
	if( (sensors & SENSOR4) && (sensors_started & SENSOR4) )
	{
		if(write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE))
			result |= SENSOR4_ERROR;
	}
	else
		result |= SENSOR4_ERROR;
	
	L_state = 0;

	call Timer.start(CONVERSION_DELAY);
		
	return result;
  }

  #define SENSORS_ALL_NEXT_OPERATION_ENABLED	0x0F
  #define SENSOR1_BLOCK_NEXT_OPERATION		0x0E
  #define SENSOR2_BLOCK_NEXT_OPERATION		0x0D
  #define SENSOR3_BLOCK_NEXT_OPERATION		0x0B
  #define SENSOR4_BLOCK_NEXT_OPERATION		0x07

  uint8_t next_operation;

  async event void Timer.fired() 
  {	
	switch (L_state)
	{
		case 1:	
			if( (next_operation & SENSOR1) && (sensors & SENSOR1))
			{
				// Reading of D2
				if(read_word(ADDR1,0x04, & data_read1))
				{
					result |= SENSOR1_ERROR;
					next_operation &= SENSOR1_BLOCK_NEXT_OPERATION;
				}
				if(next_operation & SENSOR1)
				{				
					if(data_read1 & 0x8000)
						data_read1 = 0;

					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE))
						{
							result |= SENSOR1_ERROR;
						}
					#endif
				}
			}
			if( (next_operation & SENSOR2) && (sensors & SENSOR2))
			{	
				// Reading of D2
				if(read_word(ADDR2,0x04, & data_read2))
				{
					result |= SENSOR2_ERROR;
					next_operation &= SENSOR2_BLOCK_NEXT_OPERATION;
				}

				if(next_operation & SENSOR2)
				{
					if(data_read2 & 0x8000)
						data_read2 = 0;

					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR2_ERROR;
						}
					#endif
				}
			}
			if( (next_operation & SENSOR3) && (sensors & SENSOR3))
			{
				// Reading of D2
				if(read_word(ADDR3,0x04, & data_read3))
				{
					result |= SENSOR3_ERROR;
					next_operation &= SENSOR3_BLOCK_NEXT_OPERATION;
					
				}
				if(next_operation & SENSOR3)
				{
					if(data_read3 & 0x8000)
						data_read3 = 0;

					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR3_ERROR;
						}
					#endif
				}
			}
			if( (next_operation & SENSOR4) && (sensors & SENSOR4))
			{
				// Reading of D2
				if(read_word(ADDR4,0x04, & data_read4))
				{
					result |= SENSOR4_ERROR;
					next_operation &= SENSOR4_BLOCK_NEXT_OPERATION;
				}
				if(next_operation & SENSOR4)
				{
					if(data_read4 & 0x8000)
						data_read4 = 0;

					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR4_ERROR;
						}
					#endif
				}
			}

			post readDone_task();
			
			break;

		case 0:		// Reading of D1
		default:
			next_operation = SENSORS_ALL_NEXT_OPERATION_ENABLED;
			next_operation &= ~result;
			//result = SENSORS_SUCCESS;
			
			if( (sensors & SENSOR1) && (next_operation & SENSOR1) )
			{			
				if(read_word(ADDR1,0x04, & data_read1))
				{
					result |= SENSOR1_ERROR;
					next_operation &= SENSOR1_BLOCK_NEXT_OPERATION;
				}
				if( (next_operation & SENSOR1) && (0xFFFF == data_read1) )	// check if D1 is saturated and if that's the case, return 0xFFFF as reading
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR1_ERROR;
						}
					#endif
					next_operation &= SENSOR1_BLOCK_NEXT_OPERATION;
				}
				// put the sensor down before change the settings
				if((next_operation & SENSOR1) && (write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE) ) )
				{
					result |= SENSOR1_ERROR;
					next_operation &= SENSOR1_BLOCK_NEXT_OPERATION;
				}
				// select D1-D2
				if( (next_operation & SENSOR1) && ( write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE_DTWO) ) )
				{
					result |= SENSOR1_ERROR;
					next_operation &= SENSOR1_BLOCK_NEXT_OPERATION;
				}
			}
			if( (sensors & SENSOR2) && (next_operation & SENSOR2) )
			{
				if(read_word(ADDR2,0x04, & data_read2))
				{
					result |= SENSOR2_ERROR;
					next_operation &= SENSOR2_BLOCK_NEXT_OPERATION;
				}
				if((next_operation & SENSOR2) && (0xFFFF == data_read2))	// check if D1 is saturated and if that's the case, return 0xFFFF as reading
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR2_ERROR;
						}
					#endif
					next_operation &= SENSOR2_BLOCK_NEXT_OPERATION;
				}
				// put the sensor down before change the settings
				if((next_operation & SENSOR2) && (write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)) ){
					result |= SENSOR2_ERROR;
					next_operation &= SENSOR2_BLOCK_NEXT_OPERATION;
				}
				// select D1-D2
				if((next_operation & SENSOR2) && (write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE_DTWO)) )
				{
					result |= SENSOR2_ERROR;
					next_operation &= SENSOR2_BLOCK_NEXT_OPERATION;
				}
			}
			if( (sensors & SENSOR3) && (next_operation & SENSOR3) )
			{
				if(read_word(ADDR3,0x04, & data_read3))
				{
					result |= SENSOR3_ERROR;
					next_operation &= SENSOR3_BLOCK_NEXT_OPERATION;
				}
				if((next_operation & SENSOR3) && (0xFFFF == data_read3))	// check if D1 is saturated and if that's the case, return 0xFFFF as reading
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR3_ERROR;
						}
					#endif
					next_operation &= SENSOR3_BLOCK_NEXT_OPERATION;
				}
				// put the sensor down before change the settings
				if((next_operation & SENSOR3) && (write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE))){
					result |= SENSOR3_ERROR;
					next_operation &= SENSOR3_BLOCK_NEXT_OPERATION;
				}
				// select D1-D2
				if( (next_operation & SENSOR3) && (write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE_DTWO)))
				{
					result |= SENSOR3_ERROR;
					next_operation &= SENSOR3_BLOCK_NEXT_OPERATION;
				}
			}
			if( (sensors & SENSOR4) && (next_operation & SENSOR4) )
			{
				if(read_word(ADDR4,0x04, & data_read4))
				{
					result |= SENSOR4_ERROR;
					next_operation &= SENSOR4_BLOCK_NEXT_OPERATION;
				}
				if( (next_operation & SENSOR4) && (0xFFFF == data_read4) )	// check if D1 is saturated and if that's the case, return 0xFFFF as reading
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result |= SENSOR4_ERROR;
						}
					#endif
					next_operation &= SENSOR4_BLOCK_NEXT_OPERATION;
				}
				// put the sensor down before change the settings
				if((next_operation & SENSOR4) && (write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)) ){
					result |= SENSOR4_ERROR;
					next_operation &= SENSOR4_BLOCK_NEXT_OPERATION;
				}
				// select D1-D2
				if( (next_operation & SENSOR4) && (write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE_DTWO)) )
				{
					result |= SENSOR4_ERROR;
					next_operation &= SENSOR4_BLOCK_NEXT_OPERATION;
				}
			}

			if(next_operation)
			{			
				L_state = 1;
				call Timer.start(CONVERSION_DELAY);
			}
			else
				post readDone_task();

			break;
	}
  }

  #define SENSOR1_MASK				0x0E
  #define SENSOR2_MASK				0x0D
  #define SENSOR3_MASK				0x0B
  #define SENSOR4_MASK				0x07
  
  #define ALL_SENSORS_STARTED		0x0F
  
  uint8_t sensor_state;

  command void ISL29004Control.start(uint8_t set_sensors)
  {

		uint8_t rbyte;	
		uint8_t ret_result = SENSORS_SUCCESS;
		
		sensors_started = ALL_SENSORS_STARTED;
		
		// If you need to give power to the sensors decomment the
		// following two macros.
		// The commented code concerns the case where the supply is
		// on the HUM_PWR pin
		
		//TOSH_MAKE_HUM_PWR_OUTPUT();  	//power supply to sensor device
	  	//TOSH_SET_HUM_PWR_PIN();  	//power supply to sensor device	

		// SENSOR 1
		if(set_sensors & SENSOR1)
		{
			initialize();
			
			write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
			write_byte(ADDR1,0x01,RANGE);	//0x0C
			
			#ifndef POWER_SAVING_MODE
				write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE);
			#endif 
			
			//check if the sensor is set correctly
			
			if(read_byte(ADDR1,0x00, & rbyte))
				ret_result |= SENSOR1_ERROR;
			#ifdef POWER_SAVING_MODE		
				if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR1_ERROR;
			#else
				if((NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR1_ERROR;
			#endif

			if(read_byte(ADDR1,0x01, & rbyte))
				ret_result |= SENSOR1_ERROR;
			if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
				ret_result |= SENSOR1_ERROR;
		}
		else
			ret_result |= SENSOR1_ERROR;
			
		if(ret_result & SENSOR1)
			sensors_started &= SENSOR1_MASK;
		
		
		// SENSOR2
		if(set_sensors & SENSOR2)
		{
			initialize();
			
			write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
			write_byte(ADDR2,0x01,RANGE);	//0x0C
		
			#ifndef POWER_SAVING_MODE
				write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE);
			#endif 
			
			//check if the sensor is set correctly
			
			if(read_byte(ADDR2,0x00, & rbyte))
				ret_result |= SENSOR2_ERROR;
			#ifdef POWER_SAVING_MODE		
				if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR2_ERROR;
			#else
				if((NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR2_ERROR;
			#endif

			if(read_byte(ADDR2,0x01, & rbyte))
				ret_result |= SENSOR2_ERROR;
			if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
				ret_result |= SENSOR2_ERROR;
		}
		else
			ret_result |= SENSOR2_ERROR;
			
		if(ret_result & SENSOR2)
			sensors_started &= SENSOR2_MASK;
		
			
		// SENSOR3
		if(set_sensors & SENSOR3)
		{
			initialize();
			
			write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
			write_byte(ADDR3,0x01,RANGE);	//0x0C

			#ifndef POWER_SAVING_MODE
				write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE);
			#endif 
			
			//check if the sensor is set correctly
			
			if(read_byte(ADDR3,0x00, & rbyte))
				ret_result |= SENSOR3_ERROR;
			#ifdef POWER_SAVING_MODE		
				if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR3_ERROR;
			#else
				if((NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR3_ERROR;
			#endif

			if(read_byte(ADDR3,0x01, & rbyte))
				ret_result |= SENSOR3_ERROR;
			if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
				ret_result |= SENSOR3_ERROR;
		}
		else
			ret_result |= SENSOR3_ERROR;
			
		if(ret_result & SENSOR3)
			sensors_started &= SENSOR3_MASK;
			
		
		// SENSOR4
		if(set_sensors & SENSOR4)
		{
			initialize();
			
			write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
			write_byte(ADDR4,0x01,RANGE);	//0x0C		
			
			#ifndef POWER_SAVING_MODE
				write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE);
			#endif 
			
			//check if the sensor is set correctly
			
			if(read_byte(ADDR4,0x00, & rbyte))
				ret_result |= SENSOR4_ERROR;
			#ifdef POWER_SAVING_MODE		
				if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR4_ERROR;
			#else
				if((NUMBER_OF_BIT | DONE) != rbyte)
					ret_result |= SENSOR4_ERROR;
			#endif

			if(read_byte(ADDR4,0x01, & rbyte))
				ret_result |= SENSOR4_ERROR;
			if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
				ret_result |= SENSOR4_ERROR;
		}
		else
			ret_result |= SENSOR4_ERROR;
			
		if(ret_result & SENSOR4)
			sensors_started &= SENSOR4_MASK;
			
		sensor_state = ret_result;
  }

  command error_t ISL29004Control.stop(){return SUCCESS;}

  command uint8_t ISL29004Control.status(){return sensor_state;}

  // event void Boot.booted(){}
  
}

