TL_COMPONENT=TestSuite
WORKING_DIR = ..
TL_DIR = ../../../tl
COMPONENT = $(WORKING_DIR)/TL_$(TL_COMPONENT)
TL_OBJECT_FILE = tl_objs
TLPFLAGS = -K
include $(TL_DIR)/Makefile
MSG_SIZE = 80
PFLAGS += -I../config
PFLAGS += -I../
PFLAGS += -I./


CFLAGS += -DREMOTE_REACTIONS

# Needed to specify the platform to use
PFLAGS += -I$(TL_DIR)/system/micaz_sim

include $(MAKERULES)
