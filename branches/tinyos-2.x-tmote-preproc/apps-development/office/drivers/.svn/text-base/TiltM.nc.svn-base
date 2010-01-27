#include "Msp430Adc12.h"

module TiltM {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t *> as AdcTiltX;
    interface AdcConfigure<const msp430adc12_channel_config_t *> as AdcTiltY;
  }
}

implementation {

  const msp430adc12_channel_config_t configTiltX = {
    inch: INPUT_CHANNEL_A1,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  const msp430adc12_channel_config_t configTiltY = {
    inch: INPUT_CHANNEL_A2,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t * AdcTiltX.getConfiguration()
  {
    return &configTiltX;
  }

  async command const msp430adc12_channel_config_t * AdcTiltY.getConfiguration()
  {
    return &configTiltY;
  }
}
