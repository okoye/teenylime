#include "Msp430Adc12.h"

module MagneticM {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t *> as 
        MagneticConf;
  }
}

implementation {

  const msp430adc12_channel_config_t magnetic_conf = {
    inch: INPUT_CHANNEL_A3,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t * 
      MagneticConf.getConfiguration()
  {
    return &magnetic_conf;
  }
}
