/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SourceOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;

public class SourceOffice extends Source {

	private SourceId parent;
	private Integer pathCost;
	private Double battery;
	private Hashtable<_CollectionFeature, Sample> lastSamples;
	private _CollectionFeature batteryF;
	private _CollectionFeature treeInfo;

	public SourceOffice(SourceId identifier, boolean sink,
			_CollectionFeature batteryF, _CollectionFeature treeInfo) {
		super(identifier, sink, Properties.CACHE_SIZE);
		this.batteryF = batteryF;
		this.treeInfo = treeInfo;
		this.battery = new Double(0);
		this.lastSamples = new Hashtable<_CollectionFeature, Sample>();
		this.treeInfo = treeInfo;
		this.parent = this.identifier();
		this.pathCost = new Integer(0);
	}

	public SourceId getParent() {
		return parent;
	}

	public Integer getPathCost() {
		return pathCost;
	}

	public Double getBattery() {
		return battery;
	}

	public Hashtable<_CollectionFeature, Sample> getLastSamples() {
		return lastSamples;
	}

	@SuppressWarnings("unchecked")
	public void updateCollectedSamples(
			Hashtable<_CollectionFeature, Sample> samples) {
		Enumeration<_CollectionFeature> keys = samples.keys();
		boolean replaceLast = false;
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			if (key.equals(batteryF)) {
				Vector<Double> value = (Vector<Double>) samples.get(key)
						.getValue();
				battery = new Double(value.get(0));
			} else if (key.equals(treeInfo)) {
				Vector<Integer> value = (Vector<Integer>) samples.get(key)
						.getValue();
				this.parent = new SourceId(value.get(0));
				this.pathCost = value.get(1);
			} else if (!key.id().equals(FeatureOffice.NULL)) {
				replaceLast = true;
			}
		}
		if (replaceLast)
			lastSamples = (Hashtable<_CollectionFeature, Sample>) samples
					.clone();
		super.updateCollectedSamples(samples);
	}
}
