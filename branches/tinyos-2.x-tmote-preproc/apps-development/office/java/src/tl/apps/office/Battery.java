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
 * *	$Id: Battery.java 883 2009-07-14 12:51:17Z mceriotti $
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

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.TimeSeriesChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class Battery implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;
	private static _ChartPanel panel = null;

	private String fileName;
	private boolean gui;
	private boolean console;

	public Battery(boolean gui) {
		this.gui = gui;
		this.console = false;
	}

	public Battery(String dir, boolean gui) {
		feature = new FeatureOffice(FeatureOffice.BATTERY, "Battery");
		this.fileName = "";
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.fileName = dir + File.separator;
		}
		this.fileName += feature.id() + ".txt";
		this.gui = gui;
		this.console = true;
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Double> sampleValue = (Vector<Double>) sample.getValue();
		if (console) {
			FileWriter writer;
			try {
				writer = new FileWriter(fileName, true);
				writer.write("SENSOR: " + sourceId.toString());
				writer.write("\tBATTERY: " + sampleValue.get(0));
				writer.write(" (" + sampleValue.get(1).intValue() + ")");
				writer.write("\t" + sample.getTimestamp());
				if (sample.isEndingSession())
					writer.write("\tCLOSING SESSION");
				writer.write("\n");
				writer.flush();
				writer.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		if (gui && panel != null) {
			panel.addPoint(sourceId, sample.getTimestamp().getTime(),
					sampleValue.get(0).doubleValue());
		}
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureOffice(FeatureOffice.BATTERY, "Battery");
		return feature;
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null)
			panel = new TimeSeriesChart(scenario, "Battery", "Battery", "Volts");
		return panel;
	}

	public static Vector<Double> convert(int rawValue) {
		Vector<Double> ret = new Vector<Double>();
		double battery = rawValue / 4096.0 * 3.0;
		ret.add(new Double(battery));
		ret.add(new Double(rawValue));
		return ret;
	}

}
