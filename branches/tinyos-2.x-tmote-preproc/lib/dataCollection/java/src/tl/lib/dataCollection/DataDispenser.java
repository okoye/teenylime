/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 720 $
 * * DATE
 * *    $LastChangedDate: 2008-12-18 05:15:40 -0600 (Thu, 18 Dec 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataDispenser.java 720 2008-12-18 11:15:40Z mceriotti $
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

package tl.lib.dataCollection;

import java.io.FileWriter;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.common.serial._ITupleHandler;
import tl.common.types.Tuple;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class DataDispenser extends Thread implements _ITupleHandler {

	private boolean active;
	private Vector<Tuple> tuples;
	private _CollectionScenario scenario;

	public DataDispenser(_CollectionScenario scenario) {
		this.active = false;
		this.tuples = new Vector<Tuple>();
		this.scenario = scenario;
	}

	public void activate() {
		active = true;
		new Thread(this).start();
	}

	public void handleTuple(Tuple tuple) {
		synchronized (tuples) {
			tuples.add(tuple);
			tuples.notifyAll();
		}
	}

	public void run() {
		while (this.active) {
			Tuple tuple = null;
			synchronized (tuples) {
				if (!tuples.isEmpty()) {
					tuple = (Tuple) tuples.remove(0);
				} else {
					try {
						tuples.wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
			}
			if (tuple != null) {
				_CollectionTupleReader reader = scenario.getTupleReader(tuple);
				if (reader != null) {
					Hashtable<_CollectionFeature, Sample> samples = reader.read(tuple);
					if (samples.isEmpty())
						continue;
					SourceId id = reader.getSource(tuple);
					if (!SourcesManager.exists(id))
						SourcesManager.addSource(scenario, id);
					if (!SourcesManager.getSource(id).isDuplicate(samples)) {
						SourcesManager.getSource(id).updateCollectedSamples(
								samples);
						Vector<_CollectionSamplesMsgListener> samplesMsglisteners = scenario
								.getSampleMsgListeners();
						for (int i = 0; i < samplesMsglisteners.size(); i++) {
							samplesMsglisteners.get(i).receivedSampleMsg(id,
									samples);
						}
						Enumeration<_CollectionFeature> keys = samples.keys();
						while (keys.hasMoreElements()) {
							_CollectionFeature key = keys.nextElement();
							Vector<_CollectionFeatureListener> sampleFeatureListeners = scenario
									.getSampleFeatureListeners(key);
							for (int i = 0; i < sampleFeatureListeners.size(); i++) {
								sampleFeatureListeners.get(i).receivedSample(
										id, samples.get(key));
							}
						}
					} else {
						try {
							FileWriter writer = new FileWriter(
									"duplicates.txt", true);
							writer.write("SENSOR: " + id);
							Enumeration<_CollectionFeature> keys = samples.keys();
							while (keys.hasMoreElements()) {
								_CollectionFeature key = keys.nextElement();
								writer.write(samples.get(key)
										.getSamplingPeriod());
								writer.write("\t" + key.label());
								if (samples.get(key).isEndingSession())
									writer.write("\tCLOSING SESSION");
								writer.write("\n");
							}
							writer.flush();
							writer.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
					}
				}
			}
		}
	}

	public void deactivate() {
		active = false;
		synchronized (tuples) {
			tuples.clear();
			tuples.notifyAll();
		}
	}
}
