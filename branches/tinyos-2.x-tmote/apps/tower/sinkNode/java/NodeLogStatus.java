/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 262 $
 * * DATE
 * *    $LastChangedDate: 2008-02-02 05:00:33 -0600 (Sat, 02 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: NodeLogStatus.java 262 2008-02-02 11:00:33Z mceriotti $
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

/**
 * The Class NodeLogStatus.
 * 
 * This class contains the information about one single node (tuples, startup
 * time).
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

class NodeLogStatus {
    int lastT;
    Vector<Integer> lostT;
    long timeRef;
    int periodRef;
    int collected;
	
    NodeLogStatus() {
	lastT = 0;
	lostT = new Vector<Integer>();
	timeRef = 0;
	periodRef = 0;
	collected = 0;
    }
    
    private void registerPeriod(int period) {
		if (period < lastT) {
			lostT.remove(new Integer(period));
		} else {
			for (int i = lastT + 1; i < period; i++) {
				lostT.add(new Integer(i));
			}
			lastT = period;
		}
    }
    
    boolean updateTimeRef(long time, int period){
	timeRef = time;
	periodRef = period;
// 		if (timeRef == 0) {
// 			return false;
// 		} else if (period > (lastT + Short.MAX_VALUE)) {
// 			return false;
// 		} else if (timeRef > (time - ((period - periodRef -1) * Properties.TEMP_PERIOD) - 0.5 * Properties.TEMP_PERIOD)) {
// 			if ((period - periodRef) > 15){
// 				periodRef = period - 15;
// 				timeRef = time - (period-periodRef) * Properties.TEMP_PERIOD;
// 			}
// 			return true;
// 		} else {
// 			return false;
// 		}
	return false;
    }

    long getTime(int period){
	return timeRef;
	//return timeRef + (period - periodRef) * Properties.TEMP_PERIOD;   
    }

    void registerTuple(long time, int period) {
	collected++;
	if (timeRef == 0) {
	    timeRef = time;
	    periodRef = period;
	    lastT = period - 1;
	    this.registerPeriod(period);
	} else if (period > lastT + Short.MAX_VALUE) {
	    return;
	} else if (period < lastT - Short.MAX_VALUE) {
	    lastT = 0;
	    lostT = new Vector<Integer>();
	    periodRef= 0;
	    timeRef = time - period * Properties.TEMP_PERIOD;
	    this.registerPeriod(period);
	} else {
	    this.registerPeriod(period);
	}
    }
}
