TL_COMPONENT=ElderyC
WORKING_DIR=.
TL_DIR = ../../tl
COMPONENT=$(WORKING_DIR)/TL_$(TL_COMPONENT)
TL_OBJECT_FILE= tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE=80

PFLAGS += -I./
PFLAGS += -I./config
PFLAGS += -I./proximity
PFLAGS += -I./orchestrator
PFLAGS += -I./orchestrator/drivers
PFLAGS += -I./orchestrator/vtimer
PFLAGS += -I./posture
PFLAGS += -I./serial
PFLAGS += -I./tree
PFLAGS += -I./buttonMessage
PFLAGS += -I./sensorsData


#to debug
#PFLAGS += -DDEBUG_ON
#CFLAGS += -I$(TOSDIR)/lib/printf
#CFLAGS += -DPRINTF_BUFFER_SIZE=999

TARGET ?= UNDEF
ifeq ($(TARGET), UNDEF)
CFLAGS += -DNO_TYPE
endif

ifeq ($(NO_POSTURE), yes)
CFLAGS += -DNO_POSTURE
endif

CFLAGS += -DMY_TYPE=$(TARGET)_NODE 

# TeenyLIME specific flags
#CFLAGS += -DTL_PACKET_LINK
CFLAGS += -DTL_LPL

CFLAGS += -DCC2420_DEF_CHANNEL=14
CFLAGS += -DCC2420_DEF_RFPOWER=27
#CFLAGS += -DCC2420_DEF_RFPOWER=3
CFLAGS += -DREMOTE_REACTIONS

PFLAGS += -I$(TL_DIR)/system/tmote
#PFLAGS += -I$(TL_DIR)/system/micaz_sim

include $(TL_DIR)/system/tmote/Makefile
include $(MAKERULES)
