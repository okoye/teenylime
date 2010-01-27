#define REFRESH 4096

includes Messages;

module Controller {

  uses {
    interface SendMsg as Send;
    interface ReceiveMsg as Receive;
    interface Timer as RefreshTimer;
  }

  provides interface StdControl;
}

implementation {

  TOS_Msg interestMsg, queryMsg;    
  bool pendingRead;

  command result_t StdControl.init() {

    pendingRead = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {

    dbg (DBG_USR1, "Starting controller node!\n");
    return call RefreshTimer.start(TIMER_REPEAT, REFRESH);
  }

  command result_t StdControl.stop() {

    return call RefreshTimer.stop();
  }

  event result_t RefreshTimer.fired() {

    BenchmarkMsg* interest = (BenchmarkMsg*) interestMsg.data;

    interest->type = TYPE_INTEREST;
    interest->dataType = DATA_TEMPERATURE;
    interest->sender = TOS_LOCAL_ADDRESS;
    
    call Send.send(TOS_BCAST_ADDR, sizeof(BenchmarkMsg), &interestMsg);
    return SUCCESS;
  }
  
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
    
    BenchmarkMsg* query = (BenchmarkMsg*) queryMsg.data;
    BenchmarkMsg* data = (BenchmarkMsg*) msg->data;

    switch (data->type) {

    case TYPE_REPLY:
      
      if (data->dataType == DATA_TEMPERATURE && !pendingRead) {

	dbg (DBG_USR1, "Interest matched!\n");
	pendingRead = TRUE;

	query->type = TYPE_QUERY;
	query->dataType = DATA_HUMIDITY;
	query->sender = TOS_LOCAL_ADDRESS;
	call Send.send(TOS_BCAST_ADDR, sizeof(BenchmarkMsg), &queryMsg);

      } else if (data->dataType == DATA_HUMIDITY && pendingRead) {
	
	pendingRead = FALSE;
	dbg (DBG_USR1, "Query result received\n");

      } else {
	dbg (DBG_USR1, "Unknown reply type\n");
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
