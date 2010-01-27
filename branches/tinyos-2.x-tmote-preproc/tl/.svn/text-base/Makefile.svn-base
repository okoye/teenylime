PFLAGS += $(foreach goal,$(MAKECMDGOALS), -D$(goal))
PFLAGS += -I$(TL_DIR)
PFLAGS += -I$(TL_DIR)/config
PFLAGS += -I$(TL_DIR)/interfaces
PFLAGS += -I$(TL_DIR)/system

BUILD_EXTRA_DEPS += teenylime_objects
CLEAN_EXTRA += $(BUILD_EXTRA_DEPS) $(TL_OBJECT_FILE) TL_$(TL_COMPONENT).nc `$(TL_DIR)/../tl-parser/conf-parser $(TL_COMPONENT).nc | awk 'BEGIN{ FS=" " } { for (i=1; i <= NF; i++) printf "TL_%s.nc ", $$i }'` TLObjectsParsed.nc tl_objs.h

teenylime_objects:
	$(TL_DIR)/../tl-parser/tl-preprocess $(TL_COMPONENT) $(TL_OBJECT_FILE) $(TL_DIR) $(TLPFLAGS) $(PFLAGS)

