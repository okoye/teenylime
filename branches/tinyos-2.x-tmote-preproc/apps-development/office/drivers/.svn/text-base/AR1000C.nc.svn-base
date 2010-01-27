configuration AR1000C {
  provides {
    interface Read<uint16_t> as ReadCO;
    interface Read<uint16_t> as ReadCO2;
    interface Read<uint16_t> as ReadDust;
  }
}

implementation {
  components COM;
  components CO2M;
  components DustM;
  components MainC;
  components AR1000M;

  components new AdcReadClientC() as AdcCO;
  components new AdcReadClientC() as AdcCO2;
  components new AdcReadClientC() as AdcDust;

  COM.AdcCO <- AdcCO;
  CO2M.AdcCO2 <- AdcCO2;
  DustM.AdcDust <- AdcDust;

  AR1000M.Boot -> MainC;
  
  ReadCO = AdcCO;
  ReadCO2 = AdcCO2;
  ReadDust = AdcDust;
}
