WORKING_DIR = .
TL_DIR = ../../../tl
LIB_DIR = ../../../lib
LIB_DEV_DIR = ../../../lib-development
COMPONENT = $(WORKING_DIR)/TL_LTNode
TL_COMPONENT = $(WORKING_DIR)/LTNode
TL_OBJECT_FILE = ../tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 97
PFLAGS += -I..
PFLAGS += -I$(LIB_DIR)/dataDissemination
PFLAGS += -I$(LIB_DEV_DIR)/dataCollection
PFLAGS += -I./systemMonitor
PFLAGS += -I./config
PFLAGS += -I$(LIB_DIR)/timeSync
PFLAGS += -I./
PFLAGS += -I./ISL29004
#PFLAGS += -I./ISL29004_IR

CLEAN_EXTRA += ./*.class

CFLAGS +=-DCC2420_DEF_RFPOWER=27
CFLAGS +=-DCC2420_DEF_CHANNEL=18

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

#CFLAGS += -DFAKE_LIGHT

CFLAGS += -DFAKE_TIMESYNCH

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# To activate a watchdog
CFLAGS += -DWATCHDOG

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
