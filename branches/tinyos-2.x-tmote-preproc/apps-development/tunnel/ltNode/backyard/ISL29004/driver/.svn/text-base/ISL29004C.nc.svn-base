/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Driver release 1.5 for the ISL29004 sensor
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

// Sensor's addresses definitions

#ifdef LIGHT1
	#define ADDR1 0x88	// 0x44 * 2
#endif

#ifdef LIGHT2
	#define ADDR2 0x8A	// 0x45 * 2
#endif

#ifdef LIGHT3
	#define ADDR3 0x8C	// 0x46 * 2
#endif

#ifdef LIGHT4
	#define ADDR4 0x8E	// 0x47 * 2
#endif

// Definitions of the I/O pins associated with the I2C bus 

//TOSH_ASSIGN_PIN(SDA, 3, 1);
//TOSH_ASSIGN_PIN(SCL, 3, 3);

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
  
  #ifdef LIGHT1
    	uses interface Alarm<TMilli,uint16_t> as Timer1;
  	provides interface Read<uint16_t> as Read1;
 	provides interface StdControl as StdControl1;
  #endif

  #ifdef LIGHT2
	uses interface Alarm<TMilli,uint16_t> as Timer2;
  	provides interface Read<uint16_t> as Read2;
	provides interface StdControl as StdControl2;
  #endif

  #ifdef LIGHT3
	uses interface Alarm<TMilli,uint16_t> as Timer3;
  	provides interface Read<uint16_t> as Read3;
	provides interface StdControl as StdControl3;
  #endif

  #ifdef LIGHT4
	uses interface Alarm<TMilli,uint16_t> as Timer4;
  	provides interface Read<uint16_t> as Read4;
	provides interface StdControl as StdControl4;
  #endif

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
 	
  #ifdef LIGHT1
	uint16_t data_read1;
	error_t result1;
	norace uint8_t L1_state;

	task void read1Done_task(){
		atomic{signal Read1.readDone(result1,data_read1);}	
	}

	async event void Timer1.fired() {
		switch (L1_state)
		{
			case 1:		// Reading of D2
				if(read_word(ADDR1,0x04, & data_read1))
				{
					result1 = ERETRY;
					post read1Done_task();
					return ;
				}

				if(data_read1 & 0x8000)		// clip to 0
					data_read1 = 0;

				#ifdef POWER_SAVING_MODE
					if(write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
						result1 = ERETRY;
						post read1Done_task();
						return;
					}
				#endif
				result1 = SUCCESS;
				post read1Done_task();
				break;

			case 0:		// Reading of D1
			default:
				if(read_word(ADDR1,0x04, & data_read1))
				{
					result1 = ERETRY;
					post read1Done_task();
					return ;
				}
				if(0xFFFF == data_read1)	// check if D1 saturated
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result1 = ERETRY;
							post read1Done_task();
							return;
						}
					#endif			
					result1 = SUCCESS;
					post read1Done_task();
					return;
				}
				// put the sensor down before change the settings
				if(write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
					result1 = ERETRY;
					post read1Done_task();
					return;
				}
				// select read D1-D2
				if(write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE_DTWO))
				{	
					result1 = ERETRY;					
					post read1Done_task();
					return;
				}
				L1_state = 1;
				call Timer1.start(CONVERSION_DELAY);
				
				break;
		}
	}	  
	command error_t Read1.read(){
		#ifdef POWER_SAVING_MODE	 	
			if(write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE))
				return ERETRY;
		#endif
		L1_state = 0;
 		call Timer1.start(CONVERSION_DELAY);
		return SUCCESS;
	}

	command error_t StdControl1.start(){

		uint8_t rbyte;	
		
		// If you need to give power to the sensors decomment the
		// following two macros.
		// The commented code concerns the case where the supply is
		// on the HUM_PWR pin
		
		//TOSH_MAKE_HUM_PWR_OUTPUT();  	//power supply to sensor device
	  	//TOSH_SET_HUM_PWR_PIN();  	//power supply to sensor device	

		initialize();
		
		write_byte(ADDR1,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
		write_byte(ADDR1,0x01,RANGE);	//0x0C
		
		#ifndef POWER_SAVING_MODE
			write_byte(ADDR1,0x00,NUMBER_OF_BIT | DONE);
		#endif 
		
		//check if the sensor is set correctly
		
		if(read_byte(ADDR1,0x00, & rbyte))
			return FAIL;
		#ifdef POWER_SAVING_MODE		
			if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#else
			if((NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#endif

		if(read_byte(ADDR1,0x01, & rbyte))
			return FAIL;
		if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
			return FAIL;
		
		return SUCCESS;
	  }
  #endif

  #ifdef LIGHT2
	uint16_t data_read2;
	error_t result2;
	norace uint8_t L2_state;	
	
	task void read2Done_task(){
		atomic{signal Read2.readDone(result2,data_read2);}
	}	

	async event void Timer2.fired() {
		
		switch (L2_state)
		{
			case 1:		// Reading of D2
				if(read_word(ADDR2,0x04, & data_read2))
				{
					result2 = ERETRY;
					post read2Done_task();
					return ;
				}

				if(data_read2 & 0x8000)		// clip to 0
					data_read2 = 0;

				#ifdef POWER_SAVING_MODE
					if(write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
						result2 = ERETRY;
						post read2Done_task();
						return;
					}
				#endif
				result2 = SUCCESS;
				post read2Done_task();
				break;

			case 0:		// Reading of D1
			default:
				if(read_word(ADDR2,0x04, & data_read2))
				{
					result2 = ERETRY;
					post read2Done_task();
					return ;
				}
				if(0xFFFF == data_read2)	// check if D1 saturated
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result2 = ERETRY;
							post read2Done_task();
							return;
						}
					#endif			
					result2 = SUCCESS;
					post read2Done_task();
					return;
				}
				// put the sensor down before change the settings
				if(write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
					result2 = ERETRY;
					post read2Done_task();
					return;
				}
				// select read D1-D2
				if(write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE_DTWO))
				{	
					result2 = ERETRY;					
					post read2Done_task();
					return;
				}
				L2_state = 1;
				call Timer2.start(CONVERSION_DELAY);
				
				break;
		}
	}	  

	command error_t Read2.read(){
	 	#ifdef POWER_SAVING_MODE	 	
			if(write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE))
				return ERETRY;
		#endif
		L2_state = 0;
 		call Timer2.start(CONVERSION_DELAY);
		return SUCCESS;
	}
	  
	command error_t StdControl2.start(){

		uint8_t rbyte;	
		
		// If you need to give power to the sensors decomment the
		// following two macros.
		// The commented code concerns the case where the supply is
		// on the HUM_PWR pin
		
		//TOSH_MAKE_HUM_PWR_OUTPUT();  	//power supply to sensor device
	  	//TOSH_SET_HUM_PWR_PIN();  	//power supply to sensor device	

		initialize();
		
		write_byte(ADDR2,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
		write_byte(ADDR2,0x01,RANGE);	//0x0C
	
		#ifndef POWER_SAVING_MODE
			write_byte(ADDR2,0x00,NUMBER_OF_BIT | DONE);
		#endif 
		
		//check if the sensor is set correctly
		
		if(read_byte(ADDR2,0x00, & rbyte))
			return FAIL;
		#ifdef POWER_SAVING_MODE		
			if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#else
			if((NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#endif

		if(read_byte(ADDR2,0x01, & rbyte))
			return FAIL;
		if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
			return FAIL;
			
		return SUCCESS;
	}
  #endif

  #ifdef LIGHT3
	uint16_t data_read3;
	error_t result3;
	norace uint8_t L3_state;
	
	task void read3Done_task(){
		atomic{signal Read3.readDone(result3,data_read3);}
	}

    	async event void Timer3.fired() {
		
		switch (L3_state)
		{
			case 1:		// Reading of D2
				if(read_word(ADDR3,0x04, & data_read3))
				{
					result3 = ERETRY;
					post read3Done_task();
					return ;
				}

				if(data_read3 & 0x8000)		// clip to 0
					data_read3 = 0;

				#ifdef POWER_SAVING_MODE
					if(write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
						result3 = ERETRY;
						post read3Done_task();
						return;
					}
				#endif
				result3 = SUCCESS;
				post read3Done_task();
				break;

			case 0:		// Reading of D1
			default:
				if(read_word(ADDR3,0x04, & data_read3))
				{
					result3 = ERETRY;
					post read3Done_task();
					return ;
				}
				if(0xFFFF == data_read3)	// check if D1 saturated
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result3 = ERETRY;
							post read3Done_task();
							return;
						}
					#endif			
					result3 = SUCCESS;
					post read3Done_task();
					return;
				}
				// put the sensor down before change the settings
				if(write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
					result3 = ERETRY;
					post read3Done_task();
					return;
				}
				// select read D1-D2
				if(write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE_DTWO))
				{	
					result3 = ERETRY;					
					post read3Done_task();
					return;
				}
				L3_state = 1;
				call Timer3.start(CONVERSION_DELAY);
				
				break;
		}
	}	  

	command error_t Read3.read(){
	 	#ifdef POWER_SAVING_MODE	 	
			if(write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE))
				return ERETRY;
		#endif
		L3_state = 0;
 		call Timer3.start(CONVERSION_DELAY);
		return SUCCESS;
	}

	command error_t StdControl3.start(){

		uint8_t rbyte;	
		
		// If you need to give power to the sensors decomment the
		// following two macros.
		// The commented code concerns the case where the supply is
		// on the HUM_PWR pin
		
		//TOSH_MAKE_HUM_PWR_OUTPUT();  	//power supply to sensor device
	  	//TOSH_SET_HUM_PWR_PIN();  	//power supply to sensor device	

		initialize();
		
		write_byte(ADDR3,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
		write_byte(ADDR3,0x01,RANGE);	//0x0C

		#ifndef POWER_SAVING_MODE
			write_byte(ADDR3,0x00,NUMBER_OF_BIT | DONE);
		#endif 
		
		//check if the sensor is set correctly
		
		if(read_byte(ADDR3,0x00, & rbyte))
			return FAIL;
		#ifdef POWER_SAVING_MODE		
			if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#else
			if((NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#endif

		if(read_byte(ADDR3,0x01, & rbyte))
			return FAIL;
		if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
			return FAIL;
		
		return SUCCESS;
	}
  #endif

  #ifdef LIGHT4
	uint16_t data_read4;
	error_t result4;
	norace uint8_t L4_state;

	task void read4Done_task(){
		atomic{signal Read4.readDone(result4,data_read4);}
	}

	async event void Timer4.fired() {
		
		switch (L4_state)
		{
			case 1:		// Reading of D2
				if(read_word(ADDR4,0x04, & data_read4))
				{
					result4 = ERETRY;
					post read4Done_task();
					return ;
				}

				if(data_read4 & 0x8000)		// clip to 0
					data_read4 = 0;

				#ifdef POWER_SAVING_MODE
					if(write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
						result4 = ERETRY;
						post read4Done_task();
						return;
					}
				#endif
				result4 = SUCCESS;
				post read4Done_task();
				break;

			case 0:		// Reading of D1
			default:
				if(read_word(ADDR4,0x04, & data_read4))
				{
					result4 = ERETRY;
					post read4Done_task();
					return ;
				}
				if(0xFFFF == data_read4)	// check if D1 saturated
				{
					#ifdef POWER_SAVING_MODE
						if(write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
							result4 = ERETRY;
							post read4Done_task();
							return;
						}
					#endif			
					result4 = SUCCESS;
					post read4Done_task();
					return;
				}
				// put the sensor down before change the settings
				if(write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE)){
					result4 = ERETRY;
					post read4Done_task();
					return;
				}
				// select read D1-D2
				if(write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE_DTWO))
				{	
					result4 = ERETRY;					
					post read4Done_task();
					return;
				}
				L4_state = 1;
				call Timer4.start(CONVERSION_DELAY);
				
				break;
		}
	}	  
	command error_t Read4.read(){
	 	#ifdef POWER_SAVING_MODE	 	
			if(write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE))
				return ERETRY;
		#endif
		L4_state = 0;
		call Timer4.start(CONVERSION_DELAY);
		return SUCCESS;
	}

	command error_t StdControl4.start(){

		uint8_t rbyte;	
		
		// If you need to give power to the sensors decomment the
		// following two macros.
		// The commented code concerns the case where the supply is
		// on the HUM_PWR pin
		
		//TOSH_MAKE_HUM_PWR_OUTPUT();  	//power supply to sensor device
	  	//TOSH_SET_HUM_PWR_PIN();  	//power supply to sensor device	

		initialize();
		
		write_byte(ADDR4,0x00,POWER_DOWN | NUMBER_OF_BIT | DONE);
		write_byte(ADDR4,0x01,RANGE);	//0x0C		
		
		#ifndef POWER_SAVING_MODE
			write_byte(ADDR4,0x00,NUMBER_OF_BIT | DONE);
		#endif 
		
		//check if the sensor is set correctly
		
		if(read_byte(ADDR4,0x00, & rbyte))
			return FAIL;
		#ifdef POWER_SAVING_MODE		
			if((POWER_DOWN | NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#else
			if((NUMBER_OF_BIT | DONE) != rbyte)
				return FAIL;
		#endif

		if(read_byte(ADDR4,0x01, & rbyte))
			return FAIL;
		if((RANGE != rbyte) && ((RANGE | 0x20) != rbyte))
			return FAIL;

		return SUCCESS;

	}
  #endif

  command error_t StdControl1.stop(){}

  command error_t StdControl2.stop(){}

  command error_t StdControl3.stop(){}

  command error_t StdControl4.stop(){}

  // event void Boot.booted(){}
  
}

