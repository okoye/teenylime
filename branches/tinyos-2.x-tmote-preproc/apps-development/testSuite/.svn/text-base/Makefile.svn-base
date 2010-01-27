TL_COMPONENT=TestSuite
WORKING_DIR = .
TL_DIR = ../../tl
COMPONENT = $(WORKING_DIR)/TL_$(TL_COMPONENT)
TL_OBJECT_FILE = tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 80
PFLAGS += -I./config
PFLAGS += -I./

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

CFLAGS +=-DCC2420_DEF_CHANNEL=21
CFLAGS +=-DCC2420_DEF_RFPOWER=27

CFLAGS += -DREMOTE_REACTIONS

# Needed to build the reset tool 
# CFLAGS += -DTL_CONTROLLER_NODE

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile
#include $(TL_DIR)/system/micaz_sim/Makefile

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
