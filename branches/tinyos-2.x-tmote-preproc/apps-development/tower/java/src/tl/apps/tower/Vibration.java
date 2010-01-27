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
 * *	$Id: Vibration.java 978 2009-12-03 07:01:27Z mceriotti $
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
import java.util.Date;
import java.util.Hashtable;
import java.util.Locale;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.CompressedSampleBuffer;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.MultipleChartsPanel;
import tl.lib.dataCollection.gui.NumXYChart;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;

public class Vibration implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;

	private String dirName = "";
	private boolean gui;
	private boolean console;
	private static MultipleChartsPanel panel = null;
	private Hashtable<SourceId, CompressedSampleBuffer> buffers;
	private Hashtable<SourceId, Date> timestamps;
	private Hashtable<SourceId, Boolean> closedSession;

	public Vibration(boolean gui) {
		this.gui = gui;
		this.console = false;
		buffers = new Hashtable<SourceId, CompressedSampleBuffer>();
		timestamps = new Hashtable<SourceId, Date>();
		closedSession = new Hashtable<SourceId, Boolean>();
	}

	public Vibration(String dir, boolean gui) {
		feature = new FeatureTower(FeatureTower.VIBRATION, "Vibration");
		if (dir.length() > 0) {
			File directory = new File(dir + File.separator
					+ Properties.RAW_VIBR_DIR_NAME);
			directory.mkdirs();
			this.dirName = dir;
		}
		this.gui = gui;
		this.console = true;
		buffers = new Hashtable<SourceId, CompressedSampleBuffer>();
		timestamps = new Hashtable<SourceId, Date>();
		closedSession = new Hashtable<SourceId, Boolean>();
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Integer> sampleValue = (Vector<Integer>) sample.getValue();
		if (!buffers.containsKey(sourceId)) {
			buffers.put(sourceId, new Compressed12bVibrationBuffer(
					Properties.CACHE_SIZE));
			closedSession.put(sourceId, new Boolean(true));
		}
		buffers.get(sourceId).addSample(sample);
		Vector<Sample> dec = buffers.get(sourceId).decompress();
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
				writer.write("\tTIMESTAMP:" + sample.getTimestamp());
				writer.write("\tAXIS:" + sampleValue.get(0));
				for (int i = 1; i < sampleValue.size(); i++)
					writer.write("\t" + sampleValue.get(i));
				if (sample.isEndingSession())
					writer.write("\tCLOSING SESSION");
				writer.write("\n");
				writer.flush();
				writer.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			for (int i = 0; i < dec.size(); i++) {
				if (closedSession.get(sourceId)
						&& !dec.get(i).isEndingSession()) {
					timestamps.put(sourceId, dec.get(i).getTimestamp());
					closedSession.put(sourceId, new Boolean(false));
				}
				Vector<Integer> value = (Vector<Integer>) dec.get(i).getValue();
				cal = Calendar.getInstance();
				cal.setTime(timestamps.get(sourceId));
				if (value.get(1) != -1) {
					String vibr_file = dirName + File.separator
							+ Properties.RAW_VIBR_DIR_NAME + File.separator
							+ "Vibration_" + sourceId.toString() + "_"
							+ value.get(0) + "_" + cal.get(Calendar.YEAR) + "_"
							+ (1 + cal.get(Calendar.MONTH)) + "_"
							+ cal.get(Calendar.DAY_OF_MONTH) + "_"
							+ cal.get(Calendar.HOUR_OF_DAY) + "_"
							+ cal.get(Calendar.MINUTE) + ".txt";
					try {
						writer = new FileWriter(vibr_file, true);
						writer.write(value.get(1).toString());
						writer.write("\n");
						writer.flush();
						writer.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				} else {
					String vibr_file = dirName + File.separator
							+ Properties.RAW_VIBR_DIR_NAME + File.separator
							+ "Vibration_" + sourceId.toString() + "_"
							+ value.get(0) + "_" + cal.get(Calendar.YEAR) + "_"
							+ (1 + cal.get(Calendar.MONTH)) + "_"
							+ cal.get(Calendar.DAY_OF_MONTH) + "_"
							+ cal.get(Calendar.HOUR_OF_DAY) + "_"
							+ cal.get(Calendar.MINUTE) + "_incomplete.txt";
					try {
						File f = new File(dirName + File.separator
								+ Properties.RAW_VIBR_DIR_NAME + File.separator
								+ "Vibration_" + sourceId.toString() + "_"
								+ value.get(0) + "_" + cal.get(Calendar.YEAR)
								+ "_" + (1 + cal.get(Calendar.MONTH)) + "_"
								+ cal.get(Calendar.DAY_OF_MONTH) + "_"
								+ cal.get(Calendar.HOUR_OF_DAY) + "_"
								+ cal.get(Calendar.MINUTE) + ".txt");
						if (f.exists()) {
							File dest = new File(vibr_file);
							f.renameTo(dest);
						}
						writer = new FileWriter(vibr_file, true);
						writer.write("*");
						writer.write("\n");
						writer.flush();
						writer.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
				if (dec.get(i).isEndingSession())
					closedSession.put(sourceId, new Boolean(true));
			}
		} else if (gui && panel != null) {
			for (int i = 0; i < dec.size(); i++) {
				if (closedSession.get(sourceId)
						&& !dec.get(i).isEndingSession()) {
					panel.clearChart(sourceId);
					closedSession.put(sourceId, new Boolean(false));
				}
				Vector<Integer> value = (Vector<Integer>) dec.get(i).getValue();
				if (value.get(1) != -1) {
					panel.addPoint(value.get(0), sourceId, dec.get(i)
							.getSamplingPeriod(), value.get(1));
				}
				if (dec.get(i).isEndingSession())
					closedSession.put(sourceId, new Boolean(true));
			}
		}
	}

	public static _ChartPanel getChartPanel(_CollectionGUIScenario scenario) {
		if (panel == null) {
			panel = new MultipleChartsPanel(scenario, "Vibration", "Vibration");
			panel.addChart(1, new NumXYChart(scenario, "X Axis", "X Axis",
					"Raw Value"));
			panel.addChart(2, new NumXYChart(scenario, "Y Axis", "Y Axis",
					"Raw Value"));
			panel.addChart(3, new NumXYChart(scenario, "Z Axis", "Z Axis",
					"Raw Value"));
		}
		return panel;
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureTower(FeatureTower.VIBRATION, "Vibration");
		return feature;
	}
}
