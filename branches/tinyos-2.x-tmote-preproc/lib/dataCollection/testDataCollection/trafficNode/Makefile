WORKING_DIR = .
TL_DIR = ../../../../tl
LIB_DIR = ../../../../lib
COMPONENT = $(WORKING_DIR)/TL_TrafficNode
TL_COMPONENT = $(WORKING_DIR)/TrafficNode
TL_OBJECT_FILE = ../tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 66
PFLAGS += -I..
PFLAGS += -I$(LIB_DIR)/dataDissemination
PFLAGS += -I$(LIB_DIR)/dataCollection
PFLAGS += -I$(LIB_DIR)/watchDog
PFLAGS += -I./config
PFLAGS += -I./

CLEAN_EXTRA += ./*.class

CFLAGS +=-DCC2420_DEF_RFPOWER=27
CFLAGS +=-DCC2420_DEF_CHANNEL=18

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# To collect information about the routing
PFLAGS += -I$(LIB_DIR)/dataCollection/routingMonitor
CFLAGS += -DROUTING_MONITOR

# To activate a watchdog
CFLAGS += -DWATCHDOG

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
