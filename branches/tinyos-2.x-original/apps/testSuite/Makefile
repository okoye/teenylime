WORKING_DIR = .
TL_DIR = ../../tl
COMPONENT = $(WORKING_DIR)/TestSuite
PFLAGS += -D$(BENCHMARK_NODE) -DCONFIG_B

# Unfortunately this doesn't work. BENCHMARK_NODE will be defined as '1' if we try 
# to define it as a string
#PFLAGS += -DBENCHMARK_NODE=$(BENCHMARK_NODE)

MSG_SIZE = 60

include $(TL_DIR)/make/Makefile
include $(MAKERULES)
