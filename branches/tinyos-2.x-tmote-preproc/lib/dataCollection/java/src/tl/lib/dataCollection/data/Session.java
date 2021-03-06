/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 755 $
 * * DATE
 * *    $LastChangedDate: 2009-03-28 07:18:49 -0500 (Sat, 28 Mar 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Session.java 755 2009-03-28 12:18:49Z mceriotti $
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

class Session {
	private Vector<Integer> samples_lost;
	protected Sample lastSample;
	private int sessionId;
	private int totalCollected;
	private int totalLost;
	private boolean ended;

	protected Session(int sessionId, Sample firstSample) {
		samples_lost = new Vector<Integer>();
		totalCollected = 1;
		totalLost = 0;
		lastSample = firstSample;
		ended = firstSample.isEndingSession();
		this.sessionId = sessionId;
		ended = false;
	}

	protected Session(int sessionId, int first_sampling_period,
			Sample firstSample) {
		this(sessionId, new Sample(null, first_sampling_period));
		totalCollected = 0;
		receivedSample(firstSample);
	}

	protected int getSessionId() {
		return sessionId;
	}

	protected boolean isDuplicate(Sample sample, int windowToConsider) {
		Sample oldestToConsider = new Sample(null, lastSample
				.getSamplingPeriod()
				- windowToConsider);
		if (!sample.isNewerThan(oldestToConsider)) {
			return false;
		} else if (!samples_lost.contains(new Integer(sample
				.getSamplingPeriod()))
				&& !sample.isNewerThan(lastSample)) {
			return true;
		} else {
			return false;
		}
	}

	protected void receivedSample(Sample sample) {
		if (samples_lost.contains(new Integer(sample.getSamplingPeriod()))) {
			samples_lost.remove(new Integer(sample.getSamplingPeriod()));
			totalLost--;
		}
		Sample expectedSample = new Sample(null,
				lastSample.getSamplingPeriod() + 1);
		while (sample.isNewerThan(expectedSample)) {
			totalLost++;
			if (samples_lost.size() > 50) {
				samples_lost.clear();
			}
			samples_lost.add(new Integer(expectedSample.getSamplingPeriod()));
			expectedSample = new Sample(null, expectedSample
					.getSamplingPeriod() + 1);
		}
		if (sample.isNewerThan(lastSample)) {
			lastSample = sample;
			ended = sample.isEndingSession();
		}
		totalCollected++;
	}

	protected int numberOfLostSamples() {
		return totalLost;
	}

	protected int numberOfCollectedSamples() {
		return totalCollected;
	}

	@SuppressWarnings("unchecked")
	protected Vector<Integer> getLostSamplesPeriods() {
		return (Vector<Integer>) samples_lost.clone();
	}

	protected boolean isSessionIncomplete() {
		return totalLost != 0;
	}

	protected boolean isEnded() {
		return ended;
	}
}
