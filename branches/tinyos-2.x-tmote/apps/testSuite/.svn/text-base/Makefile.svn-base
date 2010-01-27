WORKING_DIR = .
TL_DIR = ../../tl
COMPONENT = $(WORKING_DIR)/TestSuite
include $(TL_DIR)/Makefile
MSG_SIZE = 69
PFLAGS += -I./config

# TeenyLIME-specific flags
CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DACK_LOW_POWER_LISTENING

CFLAGS +=-DCC2420_DEF_CHANNEL=18

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
