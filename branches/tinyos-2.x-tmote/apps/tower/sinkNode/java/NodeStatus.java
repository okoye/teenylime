/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 299 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:43:52 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: NodeStatus.java 299 2008-02-26 18:43:52Z mceriotti $
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

import java.util.Vector;
import java.sql.Timestamp;

/**
 * The Class NodeStatus.
 * 
 * This class contains the information about one single node (tuples, startup
 * time).
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

class NodeStatus {
  int node_identifier;
  int lastT;
  Vector<Integer> lostT;
  boolean first_received;
  int collected;
  int lost;
  int prevNode;
  float battery;
  int parent;
  int path_cost;
  Timestamp info_ts;
  
	NodeStatus(int node_identifier) {
    this.node_identifier = node_identifier;
    lastT = 0;
    lostT = new Vector<Integer>();
    first_received = false;
    collected = 0;
    lost = 0;
    prevNode = -1;
	}

  void updateNodeInfo(float battery, int parent, int path_cost, Timestamp
                      info_ts){
    this.battery = battery;
    this.parent = parent;
    this.path_cost = path_cost;
    this.info_ts = info_ts;
  }

  int getCollected(){
    return collected;
  }

  int getLost(){
    return lost;
  }

	private void registerPeriod(int period) {
    if (period < lastT) {
      if (lostT.contains(new Integer(period))){
        lostT.remove(new Integer(period));
        lost --;
      } else {
        lastT = 0;
        lostT = new Vector<Integer>();
        for (int i = lastT + 1; i < period; i++) {
          lostT.add(new Integer(i));
          lost++;
        }
        lastT = period;
      }
    } else {
      for (int i = lastT + 1; i < period; i++) {
		    lostT.add(new Integer(i));
        lost++;
      }
      lastT = period;
    }
	}
  
    
	void registerTuple(long time, int period) {
    if (!first_received) {
      first_received = true;
      lastT = period - 1;
    }
    this.registerPeriod(period);
    collected++;
	}
  
  boolean updateOrder(int lastNode){
    if (lastNode == node_identifier){
      return false;
    } else if (prevNode == -1){
      prevNode = lastNode;
      return true;
    } else if (prevNode == lastNode){
	    return true;
    } else {
      prevNode = lastNode;
      return false;
    }
  }
}
