

configuration TinyMallocC {
  provides {
    interface TinyMalloc;
  }
}

implementation {
  components TinyMallocM as Malloc, MainC;
  MainC.SoftwareInit -> Malloc;
  TinyMalloc = Malloc;
}
