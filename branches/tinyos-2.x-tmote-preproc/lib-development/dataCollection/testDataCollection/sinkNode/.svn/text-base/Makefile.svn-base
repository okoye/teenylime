WORKING_DIR = .
TL_DIR = ../../../../tl
LIB_DEV_DIR = ../../../../lib-development
LIB_DIR = ../../../../lib
COMPONENT = $(WORKING_DIR)/TL_SinkNode
TL_COMPONENT = $(WORKING_DIR)/SinkNode
TL_OBJECT_FILE = ../tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 97
PFLAGS += -I..
PFLAGS += -I$(LIB_DIR)/dataDissemination/sink
PFLAGS += -I$(LIB_DEV_DIR)/dataCollection/sink
PFLAGS += -I$(LIB_DIR)/watchDog
PFLAGS += -I./config
PFLAGS += -I./
PFLAGS += -I./gateway

CLEAN_EXTRA += ./*.class

CFLAGS += -DCC2420_DEF_RFPOWER=27
CFLAGS += -DCC2420_DEF_CHANNEL=26

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

# Needed to build the reset tool 
CFLAGS += -DTL_CONTROLLER_NODE

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# To collect information about the routing
PFLAGS += -I$(LIB_DEV_DIR)/dataCollection/sink/routingMonitor
CFLAGS += -DROUTING_MONITOR

# To make the sink node proactively build the tree 
CFLAGS += -DACTIVE_TREE_BUILDER

# To activate a watchdog
CFLAGS += -DWATCHDOG

# For printf over USB support
# PFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)
