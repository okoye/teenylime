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
 * *	$Id: Temperature.java 978 2009-12-03 07:01:27Z mceriotti $
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
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
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
	
	private String dirName = "";
	private boolean gui;
	private boolean console;

	public Temperature(boolean gui) {
		this.gui = gui;
		this.console = false;
	}

	public Temperature(String dir, boolean gui) {
		feature = new FeatureTower(FeatureTower.TEMPERATURE, "Temperature");
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.dirName = dir;
		}
		this.gui = gui;
		this.console = true;
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
				writer.write("\tTEMPERATURE: " + sampleValue.get(0));
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
			feature = new FeatureTower(FeatureTower.TEMPERATURE, "Temperature");
		return feature;
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null)
			panel = new TimeSeriesChart(scenario, "Temperature", "Temperature",
					"Degrees Celsius");
		return panel;
	}

	public static Vector<Double> convertTmote(int rawValue) {
		Vector<Double> ret = new Vector<Double>();
		double temperature = (double) (-39.60 + 0.01 * rawValue);
		ret.add(new Double(temperature));
		ret.add(new Double(rawValue));
		return ret;
	}

	public static Vector<Double> convert3Mate(int rawValue) {
		Vector<Double> ret = new Vector<Double>();
		double temperature = ((double) rawValue / 4096 * 150 - 50.00);
		ret.add(new Double(temperature));
		ret.add(new Double(rawValue));
		return ret;
	}

	public static Vector<Double> convert3Mate(long rawValue, int numSamples) {
		Vector<Double> ret = new Vector<Double>();
		double temperature = rawValue / numSamples;
		temperature = ((double) temperature / 4096 * 150 - 50.00);
		ret.add(new Double(temperature));
		ret.add(new Double(rawValue));
		return ret;
	}

}
