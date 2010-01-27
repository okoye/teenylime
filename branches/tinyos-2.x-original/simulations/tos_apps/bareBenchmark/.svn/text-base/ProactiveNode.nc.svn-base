includes Messages;

module ProactiveNode {

  uses {
    interface SendMsg as Send;
    interface ReceiveMsg as Receive;
  }

  provides interface StdControl;
}

implementation {

  TOS_Msg queryReply;
    
  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
    
    BenchmarkMsg* reply;
    BenchmarkMsg* data = (BenchmarkMsg*) msg->data;

    switch (data->type) {

    case TYPE_QUERY:
      
      if (data->dataType == DATA_HUMIDITY) {
	dbg (DBG_USR1, "Query received: replying...\n");
	reply = (BenchmarkMsg*) queryReply.data;
	reply->type = TYPE_REPLY;
	reply->dataType = DATA_HUMIDITY;
	reply->sender = TOS_LOCAL_ADDRESS;
	call Send.send(data->sender, sizeof(BenchmarkMsg), 
		       &queryReply);
      } else {
	dbg (DBG_USR1, "Unknown query type\n");
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
