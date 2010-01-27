/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 684 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:07:49 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SamplingInfo.java 684 2008-10-01 10:07:49Z mceriotti $
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

package tl.lib.dataCollection.data;

import java.util.Vector;

class SamplingInfo {

	private static int NUM_MAX_RECORDED_SESSIONS = 4;

	private Vector<Session> sessions;
	private Vector<Integer> lostSamples;
	private int sessionId;
	private int numberOfLostSamples;
	private int numberOfCollectedSamples;
	private int duplicatesWindow;

	protected SamplingInfo(int duplicatesWindow) {
		sessions = new Vector<Session>();
		lostSamples = new Vector<Integer>();
		sessionId = 0;
		numberOfLostSamples = 0;
		numberOfCollectedSamples = 0;
		this.duplicatesWindow = duplicatesWindow;
	}

	@SuppressWarnings("unchecked")
	protected Vector<Integer> getLostSamplesPeriods() {
		Vector<Integer> lost = (Vector<Integer>) lostSamples.clone();
		for (int i = 0; i < sessions.size(); i++) {
			lost.addAll(sessions.get(i).getLostSamplesPeriods());
		}
		return lost;
	}

	protected int numberOfLostSamples() {
		return numberOfLostSamples;
	}

	protected int numberOfCollectedSamples() {
		return numberOfCollectedSamples;
	}

	protected void addSample(Sample sample) {
		boolean found = false;
		for (int i = 0; i < sessions.size(); i++) {
			if (notNewerThanThisSession(sample, sessions.get(i))) {
				if (!sessions.get(i).isDuplicate(sample, duplicatesWindow)) {
					int diffLost = sessions.get(i).numberOfLostSamples();
					sessions.get(i).receivedSample(sample);
					diffLost = sessions.get(i).numberOfLostSamples() - diffLost;
					numberOfCollectedSamples++;
					numberOfLostSamples += diffLost;
				}
				found = true;
				break;
			}
		}
		if (!found) {
			sessionId++;
			Session session = new Session(sessionId, sample);
			session.receivedSample(sample);
			sessions.add(session);
			while (sessions.size() > NUM_MAX_RECORDED_SESSIONS) {
				lostSamples.addAll(sessions.remove(0).getLostSamplesPeriods());
			}
			numberOfCollectedSamples++;
		}
	}

	protected boolean isLastSessionEnded() {
		return sessions.lastElement().isEnded();
	}

	protected int getSessionId(Sample sample) {
		if (sample.getSamplingPeriod() == Sample.NO_PERIOD)
			return -1;
		for (int i = 0; i < sessions.size(); i++) {
			if (notNewerThanThisSession(sample, sessions.get(i))) {
				return sessions.get(i).getSessionId();
			}
		}
		return -1;
	}

	protected boolean isDuplicate(Sample sample) {
		if (sample.getSamplingPeriod() == Sample.NO_PERIOD)
			return false;
		for (int i = 0; i < sessions.size(); i++) {
			if (notNewerThanThisSession(sample, sessions.get(i))) {
				return sessions.get(i).isDuplicate(sample, duplicatesWindow);
			}
		}
		return false;
	}

	private boolean notNewerThanThisSession(Sample sample, Session session) {
		if (sample.isNewerThan(session.lastSample) && !session.isEnded()) {
			return true;
		} else if (session.lastSample.isNewerThan(sample)
				|| session.lastSample.isSamePeriod(sample)) {
			return true;
		} else {
			return false;
		}
	}

}
