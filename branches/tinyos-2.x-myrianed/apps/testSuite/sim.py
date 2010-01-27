from TOSSIM import *
import sys

t = Tossim([]);
m = t.getNode(0);
m.bootAtTime(1000);

t.addChannel("laurens", sys.stdout);
t.addChannel("paolo", sys.stdout);
t.addChannel("luca", sys.stdout);
#t.addChannel("TinyMallocC", sys.stdout);
t.addChannel("ERROR", sys.stdout);
t.addChannel("LTL", sys.stdout);
t.addChannel("DTL", sys.stdout);
t.addChannel("TeenyLimeM", sys.stdout);

for i in range(0, 26):
  t.runNextEvent();

