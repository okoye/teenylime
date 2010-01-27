/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 895 $
 * * DATE
 * *    $LastChangedDate: 2009-09-10 04:13:45 -0500 (Thu, 10 Sep 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Temperature.java 895 2009-09-10 09:13:45Z mceriotti $
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

import java.io.File;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.TimeSeriesChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class Temperature implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;
	private static _ChartPanel panel = null;

	private String fileName;
	private boolean gui;

	public Temperature(boolean gui) {
		this.gui = gui;
	}

	public Temperature(String dir, boolean gui) {
		feature = new TunnelFeature(TunnelFeature.TEMPERATURE,
				"Temperature");
		this.fileName = "";
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.fileName = dir + File.separator;
		}
		this.fileName += feature.id() + ".txt";
		this.gui = gui;
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Double> sampleValue = (Vector<Double>) sample.getValue();
		if (gui && panel != null) {
			panel.addPoint(sourceId, sample.getTimestamp().getTime(),
					sampleValue.get(0).doubleValue());
		}
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null)
			panel = new TimeSeriesChart(scenario, "Temperature",
					"Temperature", "Raw Value");
		return panel;
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new TunnelFeature(TunnelFeature.TEMPERATURE,
					"Temperature");
		return feature;
	}

	public static Vector<Double> convert(long rawValue) {
		Vector<Double> ret = new Vector<Double>();
		double temperature = rawValue;
		temperature = (temperature / 4096 * 150 - 50.00);
		ret.add(new Double(temperature));
		ret.add(new Double(rawValue));
		return ret;
	}
}
