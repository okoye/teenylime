/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 972 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 00:40:36 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SourceDescriptorTunnel.java 972 2009-12-03 06:40:36Z mceriotti $
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

package tl.apps.tunnel;

import java.text.NumberFormat;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionSourceDescriptor;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class SourceDescriptorTunnel implements _CollectionSourceDescriptor {

	public SourceDescriptorTunnel() {

	}

	public String getOneLineHeader() {
		return "NODE\tREC\tLOST\tPARENT\tLQI\tBATTERY\tINFO TS\t\t\t\tLAST SAMPLE\n";
	}

	@SuppressWarnings("unchecked")
	public String getOneLineDescription(SourceId sourceId) {
		SourceTunnel source = (SourceTunnel) SourcesManager.getSource(sourceId);
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		String ret = source.identifier().toString();
		ret += "\t" + source.numberOfCollectedSamples();
		ret += "\t" + source.numberOfLostSamples();
		ret += "\t" + source.getParent();
		ret += "\t" + source.getPathCost();
		ret += "\t" + df.format(source.getBattery());
		ret += "\t" + source.getLastTimeSeen();
		Hashtable<_CollectionFeature, Sample> sample = source.getLastSamples();
		if (sample.size() > 0) {
			ret += "\tML:"
					+ df.format(((Vector<Double>) sample.get(
							MeanLight.getFeature()).getValue()).get(0));
			ret += "\tSDL:"
					+ df.format(((Vector<Double>) sample.get(
							StdDevLight.getFeature()).getValue()).get(0));
			ret += "\tMT:"
					+ df.format(((Vector<Double>) sample.get(
							MeanTemperature.getFeature()).getValue()).get(0));
			ret += "\tSDT:"
					+ df.format(((Vector<Double>) sample.get(
							StdDevTemperature.getFeature()).getValue()).get(0));
		}
		return ret;

	}

	@SuppressWarnings("unchecked")
	public String getLastSampleDescription(SourceId sourceId) {
		SourceTunnel source = (SourceTunnel) SourcesManager.getSource(sourceId);
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		Hashtable<_CollectionFeature, Sample> sample = source.getLastSamples();
		Enumeration<_CollectionFeature> keys = sample.keys();
		String ret = "";
		while (keys.hasMoreElements()) {
			_CollectionFeature key = keys.nextElement();
			if (key.equals(MeanLight.getFeature())) {
				ret += "Mean Light = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(MeanTemperature.getFeature())) {
				ret += "Mean Temperature = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(StdDevLight.getFeature())) {
				ret += "Std Dev Light = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			} else if (key.equals(StdDevTemperature.getFeature())) {
				ret += "Std Dev Temperature = "
						+ df.format(((Vector<Double>) sample.get(key)
								.getValue()).get(0)) + "\n";
			}
		}
		ret += "\nLast Time Seen\n" + source.getLastTimeSeen() + "\n";
		return ret;
	}

	public String getMultiLineDescription(SourceId sourceId) {
		SourceTunnel source = (SourceTunnel) SourcesManager.getSource(sourceId);
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
		SourceTunnel source = (SourceTunnel) SourcesManager.getSource(sourceId);
		return source.getParent();
	}

	public Integer getPathCost(SourceId sourceId) {
		SourceTunnel source = (SourceTunnel) SourcesManager.getSource(sourceId);
		return source.getPathCost();
	}
}
