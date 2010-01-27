/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 918 $
 * * DATE
 * *    $LastChangedDate: 2009-10-20 10:31:11 -0500 (Tue, 20 Oct 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderClass2.java 918 2009-10-20 15:31:11Z mceriotti $
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
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;
import java.util.Hashtable;
import java.util.Vector;

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderClass2 implements _CollectionTupleReader {
	private FileWriter writer;
	private String fileName = "class2.txt";
	private boolean log;

	public TupleReaderClass2() {
		this.log = false;
	}

	public void setLog(boolean log) {
		this.log = log;
	}

	public void setDir(String dirName) {
		if (dirName.length() > 0) {
			File directory = new File(dirName);
			directory.mkdirs();
			if (dirName.length() > 0)
				fileName = dirName + File.separator + fileName;
		}
	}

	public Hashtable<_CollectionFeature, Sample> read(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		boolean ending = false;
		if (((data[0] << 8) + data[1]) == Constants.CLASS_2_END_SESSION) {
			ending = true;
		}
		int node_identifier = (data[2] << 8) + data[3];
		int period = (data[4] << 8) + data[5];
		Vector<Integer> sample = new Vector<Integer>();
		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		ret.put(Class2Traffic.getFeature(), new Sample(sample, period,
				new Date(System.currentTimeMillis()), ending));
		if (log) {
			try {
				Timestamp ts = new Timestamp(new Date().getTime());
				writer = new FileWriter(fileName, true);
				writer.write("SENSOR\t" + node_identifier + "\tPERIOD\t"
						+ period + "\tTIMESTAMP\t" + ts);
				if (ending)
					writer.write("\t*");
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
		int node_identifier = (data[2] << 8) + data[3];
		return new SourceId(node_identifier);
	}

}
