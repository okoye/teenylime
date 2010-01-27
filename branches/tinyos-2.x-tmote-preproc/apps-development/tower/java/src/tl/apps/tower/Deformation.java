/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 978 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 01:01:27 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Deformation.java 978 2009-12-03 07:01:27Z mceriotti $
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

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Calendar;
import java.util.Locale;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.MultipleChartsPanel;
import tl.lib.dataCollection.gui.NumXYChart;
import tl.lib.dataCollection.gui.TimeSeriesChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class Deformation implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;
	private static MultipleChartsPanel panel = null;

	private String dirName = "";
	private boolean gui;
	private boolean console;

	private Vector<Double> lastSamples153 = null;
	private Vector<Double> lastSamples154 = null;
	private int MAX_SAMPLES = 5;

	public Deformation(boolean gui) {
		this.gui = gui;
		this.console = false;
		lastSamples153 = new Vector<Double>();
		lastSamples154 = new Vector<Double>();
	}

	public Deformation(String dir, boolean gui) {
		feature = new FeatureTower(FeatureTower.DEFORMATION, "Deformation");
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.dirName = dir;
		}
		this.gui = gui;
		this.console = true;
		lastSamples153 = new Vector<Double>();
		lastSamples154 = new Vector<Double>();
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Double> sampleValue = (Vector<Double>) sample.getValue();
		if (console) {
			String fileName = "";
			if (dirName.length() > 0)
				fileName += dirName + File.separator;
			Calendar cal = Calendar.getInstance(Locale.ITALY);

			// session type
			String currentSessionType = feature.id();

			// step timestamp
			String currentDay = cal.get(Calendar.YEAR) + "-"
					+ (1 + cal.get(Calendar.MONTH)) + "-"
					+ cal.get(Calendar.DAY_OF_MONTH);

			// building formatted filename
			fileName += currentSessionType + "_"
			/* day YYYY-MM-DD */
			+ currentDay + ".txt";
			
			FileWriter writer;
			try {
				writer = new FileWriter(fileName, true);
				writer.write("SENSOR: " + sourceId.toString());
				writer.write("\tPERIOD: " + sample.getSamplingPeriod());
				writer.write("\tDEFORMATION: " + sampleValue.get(0));
				writer.write(" (" + sampleValue.get(1).longValue() + "/"
						+ sampleValue.get(2).intValue() + ")");
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
			if (sourceId.address() == 153
					&& sampleValue.get(0).doubleValue() < 0xFFFF) {
				lastSamples153.add(sampleValue.get(0).doubleValue());
				// panel
				// .addPoint(
				// 1,
				// sourceId,
				// sample.getTimestamp().getTime(),
				// -65858.0
				// * (sampleValue.get(0).doubleValue() - lastSample153
				// .get(0).doubleValue())
				// * Math.pow(10, -6) * 15);
				double mean = 0;
				double count = 0;
				for (int i = 0; i < lastSamples153.size(); i++) {
					mean += (i + 1) * lastSamples153.get(i);
					count += i + 1;
				}
				panel.addPoint(1, sourceId, sample.getTimestamp().getTime(),
						(mean / count));
				if (lastSamples153.size() > this.MAX_SAMPLES)
					lastSamples153.remove(0);
			} else if (sourceId.address() == 154
					&& sampleValue.get(0).doubleValue() < 0xFFFF) {
				lastSamples154.add(sampleValue.get(0).doubleValue());
				// panel
				// .addPoint(
				// 2,
				// sourceId,
				// sample.getTimestamp().getTime(),
				// -0.1201
				// * (sampleValue.get(0).doubleValue() - lastSample154
				double mean = 0;
				double count = 0;
				for (int i = 0; i < lastSamples154.size(); i++) {
					mean += (i + 1) * lastSamples154.get(i);
					count += i + 1;
				}
				panel.addPoint(2, sourceId, sample.getTimestamp().getTime(),
						(mean / count));
				if (lastSamples154.size() > this.MAX_SAMPLES)
					lastSamples154.remove(0);
			}
		}
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureTower(FeatureTower.DEFORMATION, "Deformation");
		return feature;
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null) {
			panel = new MultipleChartsPanel(scenario, "Deformation",
					"Deformation");
			panel.addChart(1, new TimeSeriesChart(scenario,
					"Vertical Elongation", "Vertical Elongation", "Raw Value"));
			panel.addChart(2, new TimeSeriesChart(scenario,
					"Joint Deformation", "Joint Deformation", "Raw Value"));
		}
		return panel;
	}

	public static Vector<Double> convert(long rawValue, int numSamples) {
		Vector<Double> ret = new Vector<Double>();
		ret.add(new Double(((double) rawValue / numSamples)));
		ret.add(new Double(rawValue));
		ret.add(new Double(numSamples));
		return ret;
	}

}
