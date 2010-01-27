WORKING_DIR = .
TL_DIR = ../../../tl
LIB_DIR = ../../../lib
LIB_DEV_DIR = ../../../lib-development
COMPONENT = $(WORKING_DIR)/TL_THLNode
TL_COMPONENT = $(WORKING_DIR)/THLNode
TL_OBJECT_FILE = ../tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 82
PFLAGS += -I..
PFLAGS += -I./systemMonitor
PFLAGS += -I$(LIB_DEV_DIR)/dataDissemination
PFLAGS += -I$(LIB_DEV_DIR)/dataCollection
PFLAGS += -I./config
PFLAGS += -I$(LIB_DIR)/timeSync
PFLAGS += -I./

CLEAN_EXTRA += ./*.class

CFLAGS +=-DCC2420_DEF_RFPOWER=27
CFLAGS +=-DCC2420_DEF_CHANNEL=22

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

#CFLAGS += -DFAKE_TIMESYNCH

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
