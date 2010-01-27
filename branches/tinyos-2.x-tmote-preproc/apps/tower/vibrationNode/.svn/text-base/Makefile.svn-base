WORKING_DIR = .
TL_DIR = ../../../tl
LIB_DIR = ../../../lib
COMPONENT = $(WORKING_DIR)/TL_VibrationNode
TL_COMPONENT = $(WORKING_DIR)/VibrationNode
TL_OBJECT_FILE = ../tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 64
PFLAGS += -I..
PFLAGS += -I$(LIB_DIR)/dataDissemination
PFLAGS += -I$(LIB_DIR)/dataCollection
PFLAGS += -I$(LIB_DIR)/systemMonitor
PFLAGS += -I./config
PFLAGS += -I$(LIB_DIR)/timeSync
PFLAGS += -I./

CLEAN_EXTRA += ./*.class

CFLAGS += -DCC2420_DEF_RFPOWER=27
CFLAGS += -DCC2420_DEF_CHANNEL=18

#To enable FRAM memory
CFLAGS += -DFRAM_CHIP
PFLAGS += -I./fm25lc

# Needed to specify the platform to use
include $(TL_DIR)/system/tmote/Makefile

# To enable Flash memory
#CFLAGS += -DFLASH
#PFLAGS += -I./rincon/tos/chips/stm25p
#PFLAGS += -I./rincon/tos/interfaces

# Decides what compression scheme to use
ifeq ($(ACCEL_COMPRESS_ID),144)
CFLAGS += -DHUFFMAN_COMPRESSION
PFLAGS += -I./vibrationTools/dictionaries/144
endif

ifeq ($(ACCEL_COMPRESS_ID),145)
CFLAGS += -DHUFFMAN_COMPRESSION
PFLAGS += -I./vibrationTools/dictionaries/145
endif

ifeq ($(ACCEL_COMPRESS_ID),146)
CFLAGS += -DHUFFMAN_COMPRESSION
PFLAGS += -I./vibrationTools/dictionaries/146
endif

# TeenyLIME-specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

#CFLAGS += -DFAKE_TIMESYNCH
#CFLAGS += -DFAKE_ACCEL
#CFLAGS += -DTEST_VIBR

# Tells the routing layer this node must be a leaf in the tree
CFLAGS += -DLEAF_NODE

#For printf over USB support
#PFLAGS += -DPRINTF_SUPPORT
#CFLAGS += -I$(TOSDIR)/lib/printf
#BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
#%.class: %.java 
#	javac $<

include $(MAKERULES)
