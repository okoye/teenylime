WORKING_DIR = .
TL_DIR = ../../../tl
COMPONENT = $(WORKING_DIR)/TemperatureNode
include $(TL_DIR)/Makefile
MSG_SIZE = 69
PFLAGS += -I..
PFLAGS += -I../common
PFLAGS += -I../common/dataCollection
PFLAGS += -I./config
PFLAGS += -I../../timeSync

CLEAN_EXTRA += ./*.class

CFLAGS += -DCC2420_DEF_RFPOWER=27

# TeenyLIME-specific flags
CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DACK_LOW_POWER_LISTENING

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
