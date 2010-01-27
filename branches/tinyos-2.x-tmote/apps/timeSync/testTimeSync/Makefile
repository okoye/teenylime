WORKING_DIR = .
TimeS_DIR = ../
TL_DIR = ../../../tl

COMPONENT = $(WORKING_DIR)/TestTimeSyncC
include $(TL_DIR)/Makefile
MSG_SIZE = 100
PFLAGS += -DPRINTF_SUPPORT
PFLAGS += -I$(TimeS_DIR)
PFLAGS += -I$(WORKING_DIR)/LibTimer
PFLAGS += -I$(WORKING_DIR)/Config

#per ridurre la potenza radio da 1 a 31
CFLAGS += -DCC2420_DEF_RFPOWER=15

# For printf over USB support
CFLAGS += -I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
%.class: %.java 
	javac $<

include $(MAKERULES)
