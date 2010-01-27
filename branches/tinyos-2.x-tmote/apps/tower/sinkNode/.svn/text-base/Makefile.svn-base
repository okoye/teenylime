WORKING_DIR = .
TL_DIR = ../../../tl
COMPONENT = $(WORKING_DIR)/SinkNode
include $(TL_DIR)/Makefile
MSG_SIZE = 69
PFLAGS += -I..
PFLAGS += -I./dataCollection
PFLAGS += -I./gateway
PFLAGS += -I./config
PFLAGS += -I../../timeSync

BUILD_EXTRA_DEPS += java/TupleSerialReader.class
CLEAN_EXTRA += ./*.class ./java/*.class ./java/TupleSerialMsg.java 

java/TupleSerialReader.class: $(wildcard *.java) java/TupleSerialMsg.java
	javac java/*.java

java/TupleSerialMsg.java:
	mig java -I./config -I$(TL_DIR)/system -target=null -java-classname=TupleSerialMsg gateway/TupleSerialMsg.h tuple_serial_msg -o $@

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
