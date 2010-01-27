#include "Msp430Adc12.h"

module Test_LIS3L02AL_P {

  provides {  
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfX;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfY;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfZ;
  }
  uses {
    interface Boot;
    interface Read<uint16_t> as AccelReadX;
    interface Read<uint16_t> as AccelReadY;
    interface Read<uint16_t> as AccelReadZ;
    interface Timer<TMilli> as SenseTimer;
    interface Leds;
  }
}

implementation {
	
  enum {
    th_val = 25,
  };

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

  async command const msp430adc12_channel_config_t* AdcConfX.getConfiguration() {
    return &configX;
  }

  async command const msp430adc12_channel_config_t* AdcConfY.getConfiguration() {
    return &configY;
  }

  async command const msp430adc12_channel_config_t* AdcConfZ.getConfiguration() {
    return &configZ;
  }

  uint16_t ref_val_x = 0;
  uint16_t ref_val_y = 0;
  uint16_t ref_val_z = 0;

  event void AccelReadX.readDone(error_t result, uint16_t val) {

    if (val < ref_val_x-th_val || val > ref_val_x+th_val) {
      call Leds.led0On();
      ref_val_x = val;
    } else {
      call Leds.led0Off();
    }
  }

  event void AccelReadY.readDone(error_t result, uint16_t val) {

    if (val < ref_val_y-th_val || val > ref_val_y+th_val) {
      call Leds.led1On();
      ref_val_y = val;
    } else {
      call Leds.led1Off();
    }
  }

  event void AccelReadZ.readDone(error_t result, uint16_t val) {

    if (val < ref_val_z-th_val || val > ref_val_z+th_val) {
      call Leds.led2On();
      ref_val_z = val;
    } else {
      call Leds.led2Off();
    }
  }

  event void SenseTimer.fired() {
    call AccelReadX.read();
    call AccelReadY.read();
    call AccelReadZ.read();
  }
  
  event void Boot.booted() {
    
    TOSH_MAKE_GIO2_OUTPUT();
    TOSH_SET_GIO2_PIN();

    call SenseTimer.startPeriodic(10);
  }
}

