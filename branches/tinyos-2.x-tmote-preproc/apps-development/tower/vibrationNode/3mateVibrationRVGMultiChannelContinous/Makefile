# The main component reference
COMPONENT ?= Test_LIS3L02AL

# Including standard rules
include $(MAKERULES)

# Defining baudrate
DEFAULT_BAUDRATE = 57600

# printf support
PFLAGS += -DPRINTF_SUPPORT
CFLAGS += -I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
%.class: %.java 
	javac $<

# Channel and power settings
CFLAGS += -DCC2420_DEF_RFPOWER=27
CFLAGS += -DCC2420_DEF_CHANNEL=21

