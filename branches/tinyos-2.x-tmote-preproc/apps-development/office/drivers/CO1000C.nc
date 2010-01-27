configuration CO1000C {
  provides {
    interface Read<uint16_t> as ReadAccelX;
    interface Read<uint16_t> as ReadAccelY;
    interface Read<uint16_t> as ReadTiltX;
    interface Read<uint16_t> as ReadTiltY;
    interface Read<uint16_t> as ReadForce;
  }
}

implementation {
  components Acceleration203M;
  components TiltM;
  components ForceM;
  components MainC;
  components CO1000M;

  components new AdcReadClientC() as AdcX;
  components new AdcReadClientC() as AdcY;
  components new AdcReadClientC() as AdcTiltX;
  components new AdcReadClientC() as AdcTiltY;
  components new AdcReadClientC() as AdcForce;

  Acceleration203M.AdcConfX <- AdcX;
  Acceleration203M.AdcConfY <- AdcY;
  TiltM.AdcTiltX <- AdcTiltX;
  TiltM.AdcTiltY <- AdcTiltY;
  ForceM.AdcForce <- AdcForce;

  CO1000M.Boot -> MainC;

  ReadAccelX = AdcX;
  ReadAccelY = AdcY;
  ReadTiltX = AdcTiltX;
  ReadTiltY = AdcTiltY;
  ReadForce = AdcForce;
}
