#include <tossim.h>
#include <stdlib.h>

int main()
{
    Tossim *t = new Tossim(NULL);
    Radio *r = t->radio();
    
    
    Mote *m = t->getNode(11);
    m->bootAtTime(878010);
    r->add(11, 12, -90.71);
    for (int j = 0; j < 500; j++) 
        m->addNoiseTraceReading(-97);
    m->createNoiseModel();
    
    m = t->getNode(12);
    m->bootAtTime(371173);
    r->add(12, 11, -90.71);
    for (int j = 0; j < 500; j++) 
        m->addNoiseTraceReading(-97);
    m->createNoiseModel();
    
    t->addChannel("app", stdout);
//    t->addChannel("TL", stdout);
    while(1)
        t->runNextEvent();
}
