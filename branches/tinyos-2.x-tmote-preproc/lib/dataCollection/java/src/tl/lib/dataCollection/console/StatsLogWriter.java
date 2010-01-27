/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 688 $
 * * DATE
 * *    $LastChangedDate: 2008-10-02 03:32:26 -0500 (Thu, 02 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: StatsLogWriter.java 688 2008-10-02 08:32:26Z mceriotti $
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

package tl.lib.dataCollection.console;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionSamplesMsgListener;
import tl.lib.dataCollection._CollectionScenario;
import tl.lib.dataCollection._CollectionSourceDescriptor;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class StatsLogWriter implements _CollectionSamplesMsgListener {

	private _CollectionScenario scenario;
	private FileWriter writer;
	private String fileName;
	private boolean append;

	public StatsLogWriter(_CollectionScenario scenario, String dir,
			boolean append) {
		fileName = "";
		if (dir.length() > 0) {
			File directory = new File(dir);
			directory.mkdirs();
			this.fileName = dir + File.separator;
		}
		fileName += "Stats.txt";
		this.scenario = scenario;
		this.append = append;
	}

	public void receivedSampleMsg(SourceId id,
			Hashtable<_CollectionFeature, Sample> samples) {
		Vector<SourceId> sourcesId = SourcesManager.getAllSourcesId();
		Collections.sort(sourcesId);
		_CollectionSourceDescriptor logger = scenario.getSourceDescriptor();
		try {
			this.writer = new FileWriter(fileName, append);
			writer.write("\33[2J");
			writer.write("\33[H");
			int totalLost = 0;
			int totalCollected = 0;
			float er;
			writer.write("Statistics about the Tuple Collection\n");
			writer.write("-------------------------------------\n");
			writer.write(logger.getOneLineHeader());
			for (int i = 0; i < sourcesId.size(); i++) {
				Source source = SourcesManager.getSource(sourcesId.get(i));
				writer.write(logger.getOneLineDescription(sourcesId.get(i))
						+ "\n");
				totalCollected += source.numberOfCollectedSamples();
				totalLost += source.numberOfLostSamples();
			}
			writer.write("\nTUPLES COLLECTED -> " + totalCollected + "\n");
			writer.write("TUPLES LOST -> " + totalLost + "\n");
			er = (totalLost / (float) (totalCollected + totalLost)) * 100;
			writer.write("LOSS RATE -> " + er + "%\n");
			writer.write("\nTuples Lost Period\n");
			writer.write("-----------\n");
			writer.write("NODE\tPERIOD\n");
			writer.flush();
			for (int i = 0; i < sourcesId.size(); i++) {
				Source source = SourcesManager.getSource(sourcesId.get(i));
				Hashtable<_CollectionFeature, Vector<Integer>> lost_samples = source
						.getLostSamplesPeriods();
				Vector<Integer> allLost = new Vector<Integer>();
				Enumeration<_CollectionFeature> keys = lost_samples.keys();
				while (keys.hasMoreElements()) {
					_CollectionFeature key = keys.nextElement();
					Vector<Integer> lost = lost_samples.get(key);
					for (int j = 0; j < lost.size(); j++) {
						if (!allLost.contains(lost.get(j)))
							allLost.add(lost.get(j));
					}
				}
				writer.write(sourcesId.get(i).toString());
				for (int j = 0; j < allLost.size(); j++) {
					writer.write("\t" + allLost.get(j));
				}
				writer.write("\n");
				writer.flush();
			}
			writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
