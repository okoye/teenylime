#include "Msp430Adc12.h"

module SE1000M {
  uses interface Boot;
}

implementation {
  event void Boot.booted()
  {
    TOSH_MAKE_GIO0_OUTPUT();
    TOSH_MAKE_GIO2_OUTPUT();
    TOSH_SET_GIO2_PIN();
  }
}
