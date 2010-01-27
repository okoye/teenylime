interface Orchestrator {
  command void requestRadioOn();
  command void requestRadioOff();
  command bool isRadioOn();
}

