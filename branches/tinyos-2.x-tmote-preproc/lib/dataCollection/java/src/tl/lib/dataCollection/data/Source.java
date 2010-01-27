/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 779 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 04:10:01 -0500 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Source.java 779 2009-04-29 09:10:01Z mceriotti $
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

import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;

public class Source {
	private SourceId sourceId;
	private Date lastTimeSeen;
	private int totalCollected;
	private int totalLost;
	private boolean sink;
	private int duplicatesWindow;

	private Hashtable<_CollectionFeature, SamplingInfo> samplingInfos;

	public Source(SourceId identifier, boolean sink, int duplicatesWindow) {
		this.sourceId = identifier;
		samplingInfos = new Hashtable<_CollectionFeature, SamplingInfo>();
		totalCollected = 0;
		totalLost = 0;
		lastTimeSeen = new Date(System.currentTimeMillis());
		this.sink = sink;
		this.duplicatesWindow = duplicatesWindow;
	}

	public SourceId identifier() {
		return sourceId;
	}

	public boolean isSink() {
		return sink;
	}

	public int numberOfCollectedSamples() {
		return totalCollected;
	}

	public int numberOfLostSamples() {
		return totalLost;
	}

	public Hashtable<_CollectionFeature, Vector<Integer>> getLostSamplesPeriods() {
		Hashtable<_CollectionFeature, Vector<Integer>> lost = new Hashtable<_CollectionFeature, Vector<Integer>>();
		Enumeration<_CollectionFeature> keys = samplingInfos.keys();
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			SamplingInfo history = samplingInfos.get(key);
			Vector<Integer> lostSamples = history.getLostSamplesPeriods();
			if (!lostSamples.isEmpty()) {
				lost.put(key, lostSamples);
			}
		}
		return lost;
	}

	public void updateCollectedSamples(Hashtable<_CollectionFeature, Sample> samples) {
		lastTimeSeen = new Date(System.currentTimeMillis());
		int diffLost = 0;
		boolean toCount = false;
		Enumeration<_CollectionFeature> keys = samples.keys();
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			SamplingInfo history = samplingInfos.get(key);
			if (history == null) {
				history = new SamplingInfo(duplicatesWindow);
				samplingInfos.put(key, history);
			}
			int temp = history.numberOfLostSamples();
			history.addSample(samples.get(key));
			diffLost += history.numberOfLostSamples() - temp;
			if (samples.get(key).getSamplingPeriod() != -1)
				toCount = true;
		}
		if (toCount)
			totalCollected++;
		totalLost += diffLost / samples.size();
	}

	public boolean isSendingReliably() {
		Enumeration<_CollectionFeature> keys = samplingInfos.keys();
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			SamplingInfo history = samplingInfos.get(key);
			if (key.isReliable()) {
				if (history.isLastSessionEnded())
					return false;
				else
					return true;
			}
		}
		return false;
	}

	public boolean isDuplicate(Hashtable<_CollectionFeature, Sample> samples) {
		Enumeration<_CollectionFeature> keys = samples.keys();
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			if (samplingInfos.contains(key)
					&& samplingInfos.get(key).isDuplicate(samples.get(key)))
				return true;
		}
		return false;
	}

	public Date getLastTimeSeen() {
		// if (this.isSink()) {
		// return new Date(System.currentTimeMillis());
		// } else {
		return lastTimeSeen;
		// }
	}

	public int getSessionId(_CollectionFeature feature, Sample sample) {
		SamplingInfo info = samplingInfos.get(feature);
		if (info != null)
			return info.getSessionId(sample);
		else
			return -1;
	}
}
