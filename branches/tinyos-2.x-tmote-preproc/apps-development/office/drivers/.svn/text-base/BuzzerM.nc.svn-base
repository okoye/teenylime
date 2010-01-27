module BuzzerM {
  uses interface Timer<TMilli> as BuzzTimer;
  provides interface Buzzer;
}

implementation {
  bool buzz_on = FALSE;

  command void Buzzer.start(uint16_t frequency)
  {
    call BuzzTimer.startPeriodic(1000 / frequency);
  }

  command void Buzzer.stop()
  {
    call BuzzTimer.stop();
  }

  event void BuzzTimer.fired()
  {
    if (buzz_on)
      TOSH_CLR_GIO0_PIN();
    else
      TOSH_SET_GIO0_PIN();
    buzz_on = !buzz_on;
  }
}
