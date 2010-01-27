#include "Msp430Adc12.h"
#include "AccelMsg.h"

// In microSeconds
#define SENSE_TIMER 500

#define TH_VAL 25
#define ACCEL_NODE 10

module Test_LIS3L02AL_P {

  provides {  
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConf;
  }

  uses {
    interface Boot;

    interface Msp430Adc12MultiChannel as AccelRead;
    interface Resource as ResourceADC;

    interface Alarm<T32khz, uint16_t> as SenseTimer;
    interface Receive;
    interface AMSend;
    interface AMPacket;
    interface Packet;
    interface SplitControl as AMControl;
    interface Leds;

    interface SplitControl as PrintfControl;
    interface PrintfFlush;
  }
}

implementation {

  uint16_t currentX;
  uint16_t currentY;
  uint16_t currentZ;

  uint16_t ref_val_x = 0;
  uint16_t ref_val_y = 0;
  uint16_t ref_val_z = 0;

  uint16_t senseBuffer[3];

  adc12memctl_t memctl_additional[2];

  message_t msg;
  bool locked = FALSE;

  uint16_t microTo32Khz(uint32_t microsecs) {
    uint32_t temp = ((uint32_t)32767)*microsecs;
    return (uint16_t)(temp/1000000);
  }
	
  const msp430adc12_channel_config_t configX = {
      inch: INPUT_CHANNEL_A3,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  const msp430adc12_channel_config_t configY = {
      inch: INPUT_CHANNEL_A2,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  const msp430adc12_channel_config_t configZ = {
      inch: INPUT_CHANNEL_A4,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* AdcConf.getConfiguration() {
    return &configX;
  }

  void checkX(uint16_t val) {

    if (val < ref_val_x-TH_VAL || val > ref_val_x+TH_VAL) {
/*       call Leds.led0On(); */
      ref_val_x = val;
    } else {
/*       call Leds.led0Off(); */
    }
  }

  void checkY(uint16_t val) {

    if (val < ref_val_y-TH_VAL || val > ref_val_y+TH_VAL) {
/*       call Leds.led1On(); */
      ref_val_y = val;
    } else {
/*       call Leds.led1Off(); */
    }
  }

  void checkZ(uint16_t val) {

    if (val < ref_val_z-TH_VAL || val > ref_val_z+TH_VAL) {
/*       call Leds.led2On(); */
      ref_val_z = val;
    } else {
/*       call Leds.led2Off(); */
    }
  }

  async event void SenseTimer.fired() {

    AccelMsg* accelMsg = (AccelMsg*) call Packet.getPayload(&msg, NULL);

    call SenseTimer.start(microTo32Khz(SENSE_TIMER));

    atomic {
      call Leds.led1Toggle();
      checkX(currentX);
      checkY(currentY);
      checkZ(currentZ);
    }

/*     accelMsg->accelX = ref_val_x; */
/*     accelMsg->accelY = ref_val_y; */
/*     accelMsg->accelZ = ref_val_z; */

/*     accelMsg->serial1X = (ref_val_x & 0x00FF); */
/*     accelMsg->serial2X = 0; */
/*     accelMsg->serial2X = (ref_val_x & 0x0F00) >> 8; */

/*     accelMsg->serial1Y = (ref_val_y & 0x00FF); */
/*     accelMsg->serial2Y = 0; */
/*     accelMsg->serial2Y = (ref_val_y & 0x0F00) >> 8; */

/*     accelMsg->serial1Z = (ref_val_z & 0x00FF); */
/*     accelMsg->serial2Z = 0; */
/*     accelMsg->serial2Z = (ref_val_z & 0x0F00) >> 8; */

/*     accelMsg->serial1X = 0; */
/*     accelMsg->serial1X |= (ref_val_x & 0x000F) << 4; */
/*     accelMsg->serial2X = (ref_val_x & 0x0FF0) >> 4; */

/*     accelMsg->serial1Y = 0; */
/*     accelMsg->serial1Y |= (ref_val_y & 0x000F) << 4; */
/*     accelMsg->serial2Y = (ref_val_y & 0x0FF0) >> 4; */

/*     accelMsg->serial1Z = 0; */
/*     accelMsg->serial1Z |= (ref_val_z & 0x000F) << 4; */
/*     accelMsg->serial2Z = (ref_val_z & 0x0FF0) >> 4; */

/*     locked = TRUE; */
/*     if (call AMSend.send(AM_BROADCAST_ADDR, &msg,  */
/* 			 sizeof(AccelMsg)) != SUCCESS) { */
/*       locked = FALSE; */
/*     } */

  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&msg == bufPtr) {
      locked = FALSE;
    }
  }

  event void ResourceADC.granted() {

    call AccelRead.configure(&configX, memctl_additional, 2, senseBuffer, 3, 0);
    call AccelRead.getData();
      
    call SenseTimer.start(microTo32Khz(SENSE_TIMER)); 
  }


  event void Boot.booted() {

    if (call AMPacket.address() == ACCEL_NODE) {
      TOSH_MAKE_GIO2_OUTPUT();
      TOSH_SET_GIO2_PIN();
    }

    // Y axis
    memctl_additional[0].inch = INPUT_CHANNEL_A2;
    memctl_additional[0].sref = REFERENCE_VREFplus_AVss;
    memctl_additional[0].eos = 0;

    // Z axis
    memctl_additional[1].inch = INPUT_CHANNEL_A4;
    memctl_additional[1].sref = REFERENCE_VREFplus_AVss;
    memctl_additional[1].eos = 1;

    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (call AMPacket.address() == ACCEL_NODE) {
	call ResourceADC.request();
      } else {	
	call PrintfControl.start();
      }
    } else {
      call AMControl.start();
    }
  }

  event void PrintfControl.startDone(error_t error) {
  }
  
  event message_t* Receive.receive(message_t* bufPtr,
				   void* payload, uint8_t len) {

    AccelMsg* accelMsg = (AccelMsg*) payload;
    printf("X%d,Y%d,Z%d,S1X%d,S2X%d,S1Y%d,S2Y%d,S1Z%d,S2Z%d\n", 
	   accelMsg->accelX, 
	   accelMsg->accelY, 
	   accelMsg->accelZ,
	   accelMsg->serial1X,
	   accelMsg->serial2X,
	   accelMsg->serial1Y,
	   accelMsg->serial2Y,
	   accelMsg->serial1Z,
	   accelMsg->serial2Z);
    call PrintfFlush.flush();
    return bufPtr;
  }

  async event void AccelRead.dataReady(uint16_t* buffer, 
				       uint16_t numSamples) {
    
    currentX = buffer[0];
    currentY = buffer[1];
    currentZ = buffer[2];

    call AccelRead.getData();
  } 

  event void AMControl.stopDone(error_t err) {}

  event void PrintfControl.stopDone(error_t error) {}
  
  event void PrintfFlush.flushDone(error_t error) {}

}

