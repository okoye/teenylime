/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 785 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 05:50:15 -0500 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TreeInfo.java 785 2009-04-29 10:50:15Z mceriotti $
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

package tl.apps.routingTest;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TreeInfo implements _CollectionFeatureListener {

	private static _CollectionFeature feature = null;

	private String fileName;

	public TreeInfo(String dir) {
		feature = new FeatureTest(FeatureTest.TREE_INFO, "TreeInfo");
		this.fileName = "";
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.fileName = dir + File.separator;
		}
		this.fileName += feature.id() + ".txt";
	}

	public void receivedSample(SourceId sourceId, Sample sample) {
		Vector<Integer> sampleValue = (Vector<Integer>) sample.getValue();
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

	public static _CollectionFeature getFeature() {
		if (feature == null)
			feature = new FeatureTest(FeatureTest.TREE_INFO, "TreeInfo");
		return feature;
	}

	public static Vector<Integer> convert(int parent, int pathCost) {
		Vector<Integer> ret = new Vector<Integer>();
		ret.add(new Integer(parent));
		ret.add(new Integer(pathCost));
		return ret;
	}

}
