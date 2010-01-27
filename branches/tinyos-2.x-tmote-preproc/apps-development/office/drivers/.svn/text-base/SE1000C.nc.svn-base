configuration SE1000C {
  provides {
    interface Read<uint16_t> as ReadMic;
    interface Read<uint16_t> as ReadPIR;
    interface Read<uint16_t> as ReadMagnetic;
    interface Buzzer;
  }
}

implementation {
  components SE1000M;
  components MicrophoneM;
  components PirM;
  components MainC;
  components BuzzerM;
  components MagneticM;

  components new TimerMilliC() as BuzzTimer;

  components new AdcReadClientC() as AdcMic;
  components new AdcReadClientC() as AdcPir;
  components new AdcReadClientC() as AdcMagnetic;

  MicrophoneM.MicConf <- AdcMic;
  PirM.PirConf <- AdcPir;
  MagneticM.MagneticConf <- AdcMagnetic;

  BuzzerM.BuzzTimer -> BuzzTimer;

  SE1000M.Boot -> MainC;

  ReadMic = AdcMic;
  ReadPIR = AdcPir;
  ReadMagnetic = AdcMagnetic;
  Buzzer = BuzzerM;
}
