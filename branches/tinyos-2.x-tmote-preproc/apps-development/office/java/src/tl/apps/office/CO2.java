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
 * *	$Id: CO2.java 883 2009-07-14 12:51:17Z mceriotti $
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
import java.util.Date;
import java.util.Enumeration;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.TimeSeriesChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class CO2 implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;
	private static _ChartPanel panel = null;

	private String fileName;
	private boolean gui;
	private boolean console;

	public CO2(boolean gui) {
		this.gui = gui;
		this.console = false;
	}

	public CO2(String dir, boolean gui) {
		feature = new FeatureOffice(FeatureOffice.CO2, "CO2");
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
		Vector sampleValue = (Vector) sample.getValue();
		if (console) {
			FileWriter writer;
			try {
				writer = new FileWriter(fileName, true);
				writer.write("SENSOR: " + sourceId.toString());
				writer.write("\tPERIOD: " + sample.getSamplingPeriod());
				writer.write("\tTIMESTAMP: " + sample.getTimestamp());
				Enumeration en = sampleValue.elements();
				while (en.hasMoreElements()) {
					Vector<Double> values = (Vector<Double>) en.nextElement();
					writer.write("\n\tCO2: " + values.get(0));
					writer.write("(" + values.get(1) + "," + en.nextElement()
							+ ")");
				}
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
			Enumeration en = sampleValue.elements();
			while (en.hasMoreElements()) {
				double value = ((Vector<Double>) en.nextElement()).get(0);
				long time = ((Date) en.nextElement()).getTime();
				panel.addPoint(sourceId, time, value);
			}
		}
	}
	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureOffice(FeatureOffice.CO2, "CO2");
		return feature;
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null)
			panel = new TimeSeriesChart(scenario, "CO2", "CO2", "Raw Value");
		return panel;
	}

	public static Vector<Double> convert(int rawValue) {
		Vector<Double> ret = new Vector<Double>();
		ret.add(new Double(rawValue));
		ret.add(new Double(rawValue));
		return ret;
	}

}
