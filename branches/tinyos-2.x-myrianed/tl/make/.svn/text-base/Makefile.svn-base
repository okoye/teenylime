
# Execute preprocessing script for tuple formats

# TODO: stop processing if syntax error if the preprocessor itself crashes
# Right now we only stop if the pp encounters an error in the files it processes.
result=$(shell python $(TL_DIR)/make/preprocessor/preprocess.py $(TL_DIR)/config $(TL_DIR)/generated)

#$(if $(result), $(error Error in preprocessing))
$(if $(result), $(error $(result)))

include $(MAKERULES)

	
PFLAGS += $(foreach goal,$(MAKECMDGOALS), -D$(goal))
PFLAGS += -I$(TL_DIR)/interfaces
PFLAGS += -I$(TL_DIR)/system
PFLAGS += -I$(TL_DIR)/config
PFLAGS += -I$(TL_DIR)/generated


