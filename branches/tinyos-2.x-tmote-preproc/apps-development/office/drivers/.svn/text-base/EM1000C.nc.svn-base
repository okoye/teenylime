configuration EM1000C {
  provides {
    interface Read<uint16_t> as ReadAccelX;
    interface Read<uint16_t> as ReadAccelY;
    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadHumidity;
    interface Read<uint16_t> as ReadTotalSolar;
    interface Read<uint16_t> as ReadPhotoSynth;
  }
}

implementation {
  components Acceleration321M;
  components MainC;

  components new AdcReadClientC() as AdcX;
  components new AdcReadClientC() as AdcY;

  components new SensirionSht11C() as TempHum;
  components new HamamatsuS10871TsrC() as TotalSolar;
  components new HamamatsuS1087ParC() as PhotoSynth;


  Acceleration321M.AdcConfX <- AdcX;
  Acceleration321M.AdcConfY <- AdcY;

  Acceleration321M.Boot -> MainC;

  ReadAccelX = AdcX;
  ReadAccelY = AdcY;
  ReadTemperature = TempHum.Temperature;
  ReadHumidity = TempHum.Humidity;
  ReadTotalSolar = TotalSolar;
  ReadPhotoSynth = PhotoSynth;
}
