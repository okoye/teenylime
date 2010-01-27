/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 989 $
 * * DATE
 * *    $LastChangedDate: 2009-12-07 04:00:55 -0600 (Mon, 07 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TreeInfo.java 989 2009-12-07 10:00:55Z mceriotti $
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

public class TreeInfo implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;

	private String dirName = "";
	private boolean gui;
	private boolean console;

	public TreeInfo(boolean gui) {
		this.gui = gui;
		this.console = false;
	}

	public TreeInfo(String dir, boolean gui) {
		feature = new FeatureTower(FeatureTower.TREE_INFO, "TreeInfo");
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.dirName = dir;
		}
		this.gui = gui;
		this.console = true;
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Integer> sampleValue = (Vector<Integer>) sample.getValue();
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
				writer.write("\tPARENT: " + sampleValue.get(0));
				writer.write("\tPATHCOST: " + sampleValue.get(1));
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
		// if (gui && panel != null) {
		// panel.addPoint(sourceId, sample.getTimestamp().getTime(),
		// sampleValue.get(0).doubleValue());
		// }
	}

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureTower(FeatureTower.TREE_INFO, "TreeInfo");
		return feature;
	}

	public static Vector<Integer> convert(int parent, int pathCost) {
		Vector<Integer> ret = new Vector<Integer>();
		ret.add(new Integer(parent));
		ret.add(new Integer(pathCost));
		return ret;
	}

}
