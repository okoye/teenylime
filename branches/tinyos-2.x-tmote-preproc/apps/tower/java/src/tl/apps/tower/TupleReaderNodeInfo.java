/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 990 $
 * * DATE
 * *    $LastChangedDate: 2009-12-07 04:05:11 -0600 (Mon, 07 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderNodeInfo.java 990 2009-12-07 10:05:11Z mceriotti $
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
import java.util.Calendar;
import java.util.Date;
import java.util.Hashtable;
import java.util.Locale;

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderNodeInfo implements _CollectionTupleReader {
	private FileWriter writer;
	private String dirName = "";
	private boolean log;
	private String currentSessionBeginTimestamp = "";

	public TupleReaderNodeInfo() {
		Calendar cal = Calendar.getInstance(Locale.ITALY);
		this.log = false;
		currentSessionBeginTimestamp = cal.get(Calendar.YEAR) + "-"
				+ (1 + cal.get(Calendar.MONTH)) + "-"
				+ cal.get(Calendar.DAY_OF_MONTH) + "-"
				+ cal.get(Calendar.HOUR_OF_DAY) + "-"
				+ cal.get(Calendar.MINUTE);
	}

	public void setLog(boolean log) {
		this.log = log;
	}

	public void setDir(String dirName) {
		if (dirName.length() > 0) {
			File directory = new File(dirName);
			directory.mkdirs();
			this.dirName = dirName;
		}
	}

	public Hashtable<_CollectionFeature, Sample> read(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[1] << 8) + data[2];
		int parent = (data[3] << 8) + data[4];
		int cost = (data[5] << 8) + data[6];
		int bat = (data[7] << 8) + data[8];
		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		ret.put(Battery.getFeature(), new Sample(Battery.convert(bat),
				new Date(System.currentTimeMillis())));
		ret.put(TreeInfo.getFeature(), new Sample(TreeInfo
				.convert(parent, cost), new Date(System.currentTimeMillis())));
		if (log) {
			String fileName = "";
			if (dirName.length() > 0)
				fileName += dirName + File.separator;
			Calendar cal = Calendar.getInstance(Locale.ITALY);

			// session type
			String currentSessionType = "node_info";

			// re-create fileName with current date
			fileName = "";
			fileName += dirName + File.separator;
			fileName += currentSessionType + "_" + currentSessionBeginTimestamp
					+ "_"
					/* day YYYY-MM-DD-hh */
					+ cal.get(Calendar.YEAR) + "-"
					+ (1 + cal.get(Calendar.MONTH)) + "-"
					+ cal.get(Calendar.DAY_OF_MONTH) + "-"
					+ cal.get(Calendar.HOUR_OF_DAY) + ".txt";

			//
			// end date check
			//

			Timestamp ts = new Timestamp(new Date().getTime());
			try {
				writer = new FileWriter(fileName, true);
				writer.write("SENSOR\t" + node_identifier + "\tPARENT\t"
						+ parent + "\tPATH COST\t" + cost + "\tBATTERY\t"
						+ "\t" + bat + "\t" + Battery.convert(bat).get(0)
						+ "\tTIMESTAMP\t" + ts);
				writer.write("\n");
				writer.flush();
				writer.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return ret;
	}

	public SourceId getSource(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[1] << 8) + data[2];
		return new SourceId(node_identifier);
	}

}
