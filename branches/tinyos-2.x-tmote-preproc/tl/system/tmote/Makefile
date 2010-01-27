PFLAGS += -I$(TL_DIR)/system/tmote
PFLAGS += -I$(TL_DIR)/system/tmote/cc2420

# Needed to build the Java reset tool for TMotes
BUILD_EXTRA_DEPS += TupleMsgHeader.java HeaderConstants.java TMoteTLReset.class
CLEAN_EXTRA = *.class $(TL_DIR)/system/tmote/TupleMsgHeader.java $(TL_DIR)/system/tmote/HeaderConstants.java

TupleMsgHeader.java:
	mig java -target=null -java-classname=TupleMsgHeader $(TL_DIR)/system/tmote/TupleMsgHeader.h TL_header -o $(TL_DIR)/system/tmote/$@

HeaderConstants.java:
	ncg java -target=null -java-classname=HeaderConstants $(TL_DIR)/system/tmote/TupleMsgHeader.h CTRL_RESET -o $(TL_DIR)/system/tmote/$@

TMoteTLReset.class: $(wildcard *.java) 
	javac -cp $(TL_DIR)/system/tmote:$(TOSROOT)/support/sdk/java/tinyos.jar $(TL_DIR)/system/tmote/TMoteTLReset.java && mv $(TL_DIR)/system/tmote/*.class $(WORKING_DIR)
