WORKING_DIR = .
TIME_SYNCH_DIR = ../
TL_DIR = ../../../tl

COMPONENT = $(WORKING_DIR)/TL_TestTimeSyncC
TL_COMPONENT = $(WORKING_DIR)/TestTimeSyncC
TL_OBJECT_FILE = ../tl_objs
include $(TL_DIR)/Makefile
MSG_SIZE = 100
PFLAGS += -I$(TIME_SYNCH_DIR)
PFLAGS += -I$(WORKING_DIR)/config
PFLAGS += -I./

CFLAGS += -DCC2420_DEF_RFPOWER=1
CFLAGS += -DCC2420_DEF_CHANNEL=13

CFLAGS += -DTL_LPL

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# For printf over USB support
PFLAGS += -DPRINTF_SUPPORT_TIME_SYNCH
PFLAGS += -DPRINTF_SUPPORT
CFLAGS += -I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
%.class: %.java 
	javac $<

include $(MAKERULES)
