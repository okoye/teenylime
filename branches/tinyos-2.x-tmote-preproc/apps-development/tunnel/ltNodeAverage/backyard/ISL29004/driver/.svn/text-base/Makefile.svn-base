COMPONENT=TestAppC
CFLAGS+=-I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
%.class: %.java 
	javac $<
include $(MAKERULES)

#per ridurre la potenza radio da 1 a 31
CFLAGS += -DCC2420_DEF_RFPOWER=27

#cambio il canale di comunicazione
CFLAGS +=-DCC2420_DEF_CHANNEL=15

