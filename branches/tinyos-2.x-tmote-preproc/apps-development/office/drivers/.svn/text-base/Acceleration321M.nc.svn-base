#include "Msp430Adc12.h"

module Acceleration321M {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t *> as AdcConfX;
    interface AdcConfigure<const msp430adc12_channel_config_t *> as AdcConfY;
  }
  uses {
    interface Boot;
  }
}

implementation {

  const msp430adc12_channel_config_t configX = {
    inch: INPUT_CHANNEL_A2,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  const msp430adc12_channel_config_t configY = {
    inch: INPUT_CHANNEL_A3,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t * AdcConfX.getConfiguration()
  {
    return &configX;
  }

  async command const msp430adc12_channel_config_t * AdcConfY.getConfiguration()
  {
    return &configY;
  }

  event void Boot.booted()
  {
    TOSH_MAKE_GIO2_OUTPUT();
    TOSH_SET_GIO2_PIN();
  }
}
