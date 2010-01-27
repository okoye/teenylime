/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 48 $
 * * DATE
 * *    $LastChangedDate: 2007-06-15 10:05:40 +0200 (Fri, 15 Jun 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: bronwasser $
 * *
 * *	$Id: TokenMutualExclusion.nc 48 2007-06-15 08:05:40Z bronwasser $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU Lesser General Public License
 * *   as published by the Free Software Foundation; either version 2
 * *   of the License, or (at your option) any later version.
 * *
 * *   This program is distributed in the hope that it will be useful,
 * *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 * *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * *   GNU General Public License for more details.
 * *
 * *   You should have received a copy of the GNU General Public License
 * *   along with this program; if not, you may find a copy at the FSF web
 * *   site at 'www.gnu.org' or 'www.fsf.org', or you may write to the
 * *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * *   Boston, MA  02111-1307, USA
 ***/



#include "AM.h"
#include "Tos2Defs.h"
#include "TupleSpace.h"

/**
 * A module implementing a token-based mutual exclusion mechanisms on
 * top of TeenyLIME.
 * 
 * @author Luca Mottola 
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 * 
 */

#define MAX_REGIONS 1

module TokenMutualExclusion {

  uses interface TupleSpace as TS;
  uses interface AMPacket;
  provides interface MutualExclusion;
}

implementation {

  TLOpId_t tokenAvailable, gettingToken;
  struct regionToken_t {
    tuple token;
    bool tokenAquired;
    uint8_t regionId;
    TLOpId_t lookingForToken;
    TLOpId_t gettingToken;
  };
  struct regionToken_t regionTokens[MAX_REGIONS];
  uint8_t regionTokensNum = 0;

  void acquireToken(tuple token, uint8_t regionId) {
    
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      uart_puts("looking for token\n");
      if (regionTokens[i].regionId == regionId) {
      	regionTokens[i].tokenAquired = TRUE;
        regionTokens[i].token = token;
      }
    }
  }

  void setLookingForToken(uint8_t regionId, TLOpId_t lookingForToken) {
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
        regionTokens[i].lookingForToken = lookingForToken;
        return;
      }
    }
  }

  bool isTokenAquired(uint8_t regionId) {
 
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
      	return regionTokens[i].tokenAquired;
      }
    }

    // Creating a new spot 
    if (regionTokensNum < MAX_REGIONS) {
      regionTokens[regionTokensNum].tokenAquired = FALSE;
      regionTokens[regionTokensNum].regionId = regionId;
      regionTokensNum++;
    }    
    return FALSE;
  }

  tuple getTokenForRegion(uint8_t regionId) {
 
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
      	return regionTokens[i].token;
      }
    }
    return emptyTuple();
  }

  TLOpId_t getReactionForRegion(uint8_t regionId) {
 
    uint8_t i;
    TLOpId_t lookingForToken;

    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
      	lookingForToken = regionTokens[i].lookingForToken;
      	break;
      }
    }
    return lookingForToken;
  }

  bool isTokenAvailable(TLOpId_t operationId) {
 
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].lookingForToken.commandId == operationId.commandId) {
      	return TRUE;
      }
    }
    return FALSE;
  }

  void releaseToken(int8_t regionId) {
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
      	regionTokens[i].tokenAquired = FALSE;
      	return;
      }
    }    
  }

  void setGettingToken(uint8_t regionId, TLOpId_t gettingTokenOpId) {
    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].regionId == regionId) {
        regionTokens[i].gettingToken = gettingTokenOpId;	
        return;
      }
    }
  }

  bool isGettingToken(TLOpId_t operationId, uint8_t* regionId) {

    uint8_t i;
    for (i=0; i<regionTokensNum; i++) {
      if (regionTokens[i].gettingToken.commandId == operationId.commandId) {
        *regionId = regionTokens[i].regionId;
        return TRUE;
      }
    }
    return FALSE;
  }
  
  command error_t MutualExclusion.startRequestCriticalRegion(uint8_t regionId) {

    tuple tokenTempl;

    if (isTokenAquired(regionId) == FALSE) {
      tokenTempl = newTuple(2, 
			    formalField(TYPE_UINT16_T), 
			    actualField_uint8(regionId));
      tokenAvailable = call TS.addReaction(TRUE, TOS_BCAST_ADDR, &tokenTempl); 
      setLookingForToken(regionId, tokenAvailable); 
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command error_t MutualExclusion.releaseCriticalRegion(uint8_t regionId) {
    
    tuple token;
    if (isTokenAquired(regionId)) {
      token = getTokenForRegion(regionId); 
      token.fields[0].value.int16 = call AMPacket.address();
      call TS.out(FALSE, call AMPacket.address(), &token);
      releaseToken(regionId);
      dbg (DBG_USR1, "Releasing critical region...\n");
      uart_puts("Rls cr\n");
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command error_t MutualExclusion.stopRequestCriticalRegion(uint8_t regionId) {
    call TS.removeReaction(getReactionForRegion(regionId));
  }

  event error_t TS.reifyCapabilityTuple(tuple* ct) {
    return SUCCESS;
  }

  event error_t TS.tupleReady(TLOpId_t operationId, 
			       tuple *tuples, uint8_t number) {
  
    uint8_t regionId = 0;
    TLOpId_t gettingTokenOpId;

    if (isTokenAvailable(operationId)) {

      // Some token has been released, trying to get it
      dbg (DBG_USR1, "Token released from %d\n", tuples[0].fields[0].value.int16);
      uart_puts("Tkn rlsd from \n");
      uart_puthex4(tuples[0].fields[0].value.int16);
      gettingTokenOpId = call TS.in(TRUE, 
				    tuples[0].fields[0].value.int16, 
				    &tuples[0]);
      setGettingToken(tuples[0].fields[1].value.int8, gettingTokenOpId);

    } else if (isGettingToken(operationId, &regionId)) {

      if (number > 0) {

        // We got the token!
        acquireToken(tuples[0], regionId);
        signal MutualExclusion.criticalRegionAquired(regionId);
        call TS.removeReaction(getReactionForRegion(regionId));
	      dbg (DBG_USR1, "Token acquired!\n");
        uart_puts("Tkn acqrd!\n");

      } else {

        // We lost the race for the token...
        signal MutualExclusion.lostCriticalRegion(regionId);
        dbg (DBG_USR1, "Lost the race for the token!\n");
        uart_puts("Lost race for tkn!\n");
      }
    }  
    return SUCCESS;
  }
 
  command error_t MutualExclusion.initRegion(uint8_t regionId) {

    tuple token = newTuple(2, 
			   actualField_uint16(call AMPacket.address()), 
			   actualField_uint8(regionId));

    dbg (DBG_USR1, "Tuple size %d\n", sizeof(tuple));
    acquireToken(token, regionId);
    signal MutualExclusion.criticalRegionAquired(regionId);
  
    return SUCCESS;
  }
}
