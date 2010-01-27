includes AM;
includes TupleSpace;

#define MAX_REGIONS 4
#define REFRESH_TIMER 4096 
#define MAX_NEIGHBORS 4
#define NULL_REGION 0

#define INTEREST 0
#define TOKEN 1
#define NOTIFY 2
#define RETRIEVE 3

module BareMutualExclusion {

  uses { 
    interface ReliableSend as Send;
    interface ReceiveMsg as Receive;
    interface Timer as PeriodicRefresh;
  }
  provides interface MutualExclusion;
}

implementation {

  struct MEMsg {
    uint16_t sender;
    uint8_t cmd;
  };

  TOS_Msg lookingForToken, releasingToken, notifyAvail, retrieveToken;

  struct MEMsg token;
  struct MEMsg tokenTempl;

  bool tokenAquired;

  uint16_t recipients[MAX_NEIGHBORS];
  uint8_t recipientsNum = 0;

  command result_t MutualExclusion.startRequestCriticalRegion(uint8_t regionId) {

    if (!tokenAquired) {
      tokenTempl.sender = TOS_LOCAL_ADDRESS;
      tokenTempl.cmd = INTEREST;
      call PeriodicRefresh.start(TIMER_REPEAT, REFRESH_TIMER);
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command result_t MutualExclusion.releaseCriticalRegion(uint8_t regionId) {
    
    uint8_t i;
    struct MEMsg* data = (struct MEMsg*) notifyAvail.data;

    if (tokenAquired) {
      for (i=0; i<recipientsNum; i++) {
	data->sender = TOS_LOCAL_ADDRESS;
	data->cmd = NOTIFY;
	call Send.send(recipients[i], sizeof(struct MEMsg), &notifyAvail, TRUE);
      }
      dbg (DBG_USR1, "Releasing critical region...\n");
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command result_t MutualExclusion.stopRequestCriticalRegion(uint8_t regionId) {
    
    // NOT IMPLEMENTED
    return FAIL;
  }
 
  command result_t MutualExclusion.initRegion(uint8_t regionId) {

    token.sender = TOS_LOCAL_ADDRESS;
    token.cmd = TOKEN;
    tokenAquired = TRUE;
    signal MutualExclusion.criticalRegionAquired(regionId);
  
    return SUCCESS;
  }

  event result_t PeriodicRefresh.fired() {
    
    struct MEMsg* request = (struct MEMsg*) lookingForToken.data;
    *request = tokenTempl;
    call Send.send(TOS_BCAST_ADDR, sizeof(struct MEMsg), &lookingForToken, FALSE);

    return SUCCESS;
  }
  
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg){
    
    uint8_t i;
    bool found = FALSE;
    
    struct MEMsg* receive = (struct MEMsg*) msg->data;
    struct MEMsg* retrieve = (struct MEMsg*) retrieveToken.data;
    struct MEMsg* tokenRelease = (struct MEMsg*) releasingToken.data;

    switch (receive->cmd) {

    case INTEREST:
      for (i=0; i<recipientsNum; i++) {
	if (receive->sender == recipients[i]) {
	  found = TRUE;
	}
      }
      if (!found) {
	recipients[recipientsNum++] = receive->sender;
      }
      break;
      
    case NOTIFY:
      dbg (DBG_USR1, "Token released from %d\n", receive->sender);
      retrieve->sender = TOS_LOCAL_ADDRESS;
      retrieve->cmd = RETRIEVE;
      call Send.send(receive->sender, sizeof(struct MEMsg), &retrieveToken, TRUE);
      break;

    case RETRIEVE:
      // Only the firs retrieve will be served
      if (tokenAquired) {
	tokenAquired = FALSE;
	*tokenRelease = token;
	call Send.send(receive->sender, sizeof(struct MEMsg), 
		       &releasingToken, TRUE);
      }
      break;

    case TOKEN:
      tokenAquired = TRUE;
      token = *receive;
      signal MutualExclusion.criticalRegionAquired(NULL_REGION);
      call PeriodicRefresh.stop();
      dbg (DBG_USR1, "Token acquired!\n");
      break;
    }

    return msg;
  }
  
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t Send.deliveredMessage(TOS_MsgPtr msg) {
    return SUCCESS;
  }
}
