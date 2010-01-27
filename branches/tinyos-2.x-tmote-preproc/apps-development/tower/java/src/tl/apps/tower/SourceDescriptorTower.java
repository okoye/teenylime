/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 705 $
 * * DATE
 * *    $LastChangedDate: 2008-11-03 12:19:03 -0600 (Mon, 03 Nov 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SourceDescriptorTower.java 705 2008-11-03 18:19:03Z mceriotti $
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

package tl.apps.tower;

import java.text.NumberFormat;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionSourceDescriptor;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class SourceDescriptorTower implements _CollectionSourceDescriptor {

	public SourceDescriptorTower() {

	}

	public String getOneLineHeader() {
		return "NODE\tREC\tLOST\tPARENT\tCOST\tBATTERY\tINFO TS\t\t\t\tLAST SAMPLE\n";
	}

	@SuppressWarnings("unchecked")
	public String getOneLineDescription(SourceId sourceId) {
		SourceTower source = (SourceTower) SourcesManager.getSource(sourceId);
		String ret = source.identifier().toString();
		ret += "\t" + source.numberOfCollectedSamples();
		ret += "\t" + source.numberOfLostSamples();
		ret += "\t" + source.getParent();
		ret += "\t" + source.getPathCost();
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		ret += "\t" + df.format(source.getBattery());
		ret += "\t" + source.getLastTimeSeen();
		Hashtable<_CollectionFeature, Sample> sample = source.getLastSamples();
		Enumeration<_CollectionFeature> keys = sample.keys();
		ret += "\t";
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			if (key.equals(Deformation.getFeature())) {
				ret += " Deformation: "
						+ df.format(((Vector<Double>) sample.get(
								Deformation.getFeature()).getValue()).get(0));
			} else if (key.equals(Humidity.getFeature())) {
				ret += " Humidity: "
						+ df.format(((Vector<Double>) sample.get(
								Humidity.getFeature()).getValue()).get(0));
			} else if (key.equals(Light.getFeature())) {
				ret += " Light: "
						+ df.format(((Vector<Long>) sample.get(
								Light.getFeature()).getValue()).get(0));
			} else if (key.equals(SolarLight.getFeature())) {
				ret += " SolarLight: "
						+ df.format(((Vector<Double>) sample.get(
								SolarLight.getFeature()).getValue()).get(0));
			} else if (key.equals(SynthLight.getFeature())) {
				ret += " SynthLight: "
						+ df.format(((Vector<Double>) sample.get(
								SynthLight.getFeature()).getValue()).get(0));
			} else if (key.equals(Temperature.getFeature())) {
				ret += " Temperature: "
						+ df.format(((Vector<Double>) sample.get(
								Temperature.getFeature()).getValue()).get(0));
			} else if (key.equals(Vibration.getFeature())) {
				if (sample.get(Vibration.getFeature()).isEndingSession())
					ret += " Vibration: closed session";
				else
					ret += " Vibration: open session";
			}
		}
		return ret;
	}

	@SuppressWarnings("unchecked")
	public String getLastSampleDescription(SourceId sourceId) {
		SourceTower source = (SourceTower) SourcesManager.getSource(sourceId);
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		Hashtable<_CollectionFeature, Sample> sample = source.getLastSamples();
		Enumeration<_CollectionFeature> keys = sample.keys();
		String ret = "";
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			if (key.equals(Deformation.getFeature())) {
				ret += "Deformation = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(Humidity.getFeature())) {
				ret += "Humidity = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(Light.getFeature())) {
				ret += "Light = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(SolarLight.getFeature())) {
				ret += "SolarLight = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(SynthLight.getFeature())) {
				ret += "SynthLight = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(Temperature.getFeature())) {
				ret += "Temperature = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(Vibration.getFeature())) {
				if (sample.get(Vibration.getFeature()).isEndingSession())
					ret += " Vibration: closed session\n";
				else
					ret += " Vibration: open session\n";
			}
		}
		ret += "\nLast Time Seen\n" + source.getLastTimeSeen() + "\n";
		return ret;
	}

	public String getMultiLineDescription(SourceId sourceId) {
		SourceTower source = (SourceTower) SourcesManager.getSource(sourceId);
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		String ret = "";
		if (!source.isSink()) {
			ret += "Battery " + df.format(source.getBattery()) + "\n";
			ret += getLastSampleDescription(sourceId);
		} else {
			ret += "Sink Node\n";
		}
		return ret;
	}

	public SourceId getParent(SourceId sourceId) {
		SourceTower source = (SourceTower) SourcesManager.getSource(sourceId);
		return source.getParent();
	}

	public Integer getPathCost(SourceId sourceId) {
		SourceTower source = (SourceTower) SourcesManager.getSource(sourceId);
		return source.getPathCost();
	}
}
