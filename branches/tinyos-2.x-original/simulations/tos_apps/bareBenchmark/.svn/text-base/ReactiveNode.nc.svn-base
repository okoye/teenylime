includes Messages;

#define TIMER 5120
#define BOOT 20480
#define MAX_INTERESTS 2
#define NULL_ID TOS_BCAST_ADDR

module ReactiveNode {

  uses {
    interface SendMsg as Send;
    interface ReceiveMsg as Receive;
    interface Timer as PeriodicTimer;
  }

  provides interface StdControl;
}

implementation {

  TOS_Msg interestReply;    

  struct Interest {
    uint8_t dataType;
    uint16_t recipient;
  };

  struct Interest interests[MAX_INTERESTS];
  
  void insertInterest(uint8_t type, uint16_t recipient) {

    uint8_t i;
    for (i=0; i<MAX_INTERESTS; i++) {
      if (interests[i].recipient == NULL_ID) {
	interests[i].dataType = type;
	interests[i].recipient = recipient;
	return;
      }
    }
  }

  command result_t StdControl.init() {

    uint8_t i;
    for (i=0; i<MAX_INTERESTS; i++) {
      interests[i].recipient = NULL_ID;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg (DBG_USR1, "Starting reactive node!\n");
    return call PeriodicTimer.start (TIMER_ONE_SHOT, BOOT);
  }

  command result_t StdControl.stop() {
    return call PeriodicTimer.stop ();
  }

  event result_t PeriodicTimer.fired() {

    uint8_t i;
    BenchmarkMsg* reply = (BenchmarkMsg*) interestReply.data;

    for (i=0; i<MAX_INTERESTS; i++) {
      if (interests[i].dataType == DATA_TEMPERATURE) {
	reply->type = TYPE_REPLY;
	reply->dataType = DATA_TEMPERATURE;
	reply->sender = TOS_LOCAL_ADDRESS;
	call Send.send(interests[i].recipient, sizeof(BenchmarkMsg), 
		       &interestReply);
      }
    }    
    return call PeriodicTimer.start (TIMER_ONE_SHOT, TIMER);
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
    
    BenchmarkMsg* data = (BenchmarkMsg*) msg->data;

    switch (data->type) {

    case TYPE_INTEREST:
      
      if (data->dataType == DATA_TEMPERATURE) {
	dbg (DBG_USR1, "Interest inserted...\n");
	insertInterest(data->dataType, data->sender);
      } else {
	dbg (DBG_USR1, "Unknown interest type\n");
      }
      break;

    default: 
      dbg (DBG_USR1, "Unknown message type\n");
      break;
    }

    return msg;
  }
 
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
