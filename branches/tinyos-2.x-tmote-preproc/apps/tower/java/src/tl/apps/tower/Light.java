/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1010 $
 * * DATE
 * *    $LastChangedDate: 2010-01-08 02:58:17 -0600 (Fri, 08 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Light.java 1010 2010-01-08 08:58:17Z mceriotti $
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
import tl.lib.dataCollection.gui.TimeSeriesChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class Light implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;
	private static _ChartPanel panel = null;

	private String dirName = "";
	private boolean gui;
	private boolean console;

	public Light(boolean gui) {
		this.gui = gui;
		this.console = false;
	}

	public Light(String dir, boolean gui) {
		feature = new FeatureTower(FeatureTower.LIGHT, "Light");
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.dirName = dir;
		}
		this.gui = gui;
		this.console = true;
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Long> sampleValue = (Vector<Long>) sample.getValue();
		// 144 is not sampling light
		if (sourceId.address() == 144) {
			return;
		}
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
				writer.write("\tLIGHT: " + sampleValue.get(0));
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
					sampleValue.get(0).longValue());
		}
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureTower(FeatureTower.LIGHT, "Light");
		return feature;
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null)
			panel = new TimeSeriesChart(scenario, "Light", "Light", "Lux");
		return panel;
	}

	public static Vector<Long> convert(int rawValue) {
		Vector<Long> ret = new Vector<Long>();
		ret.add(new Long(10 * rawValue));
		ret.add(new Long(rawValue));
		return ret;
	}
}
