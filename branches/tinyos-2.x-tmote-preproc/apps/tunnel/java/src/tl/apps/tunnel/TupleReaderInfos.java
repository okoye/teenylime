/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:08:41 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderInfos.java 885 2009-07-15 16:08:41Z mceriotti $
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

package tl.apps.tunnel;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Hashtable;
import java.util.Vector;

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderInfos implements _CollectionTupleReader {
	private FileWriter writer;
	private String fileName = "infos.txt";
	private boolean log;

	public TupleReaderInfos() {
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
		int target_gw = (data[2] << 8) + data[3];
		int node_identifier = (data[4] << 8) + data[5];
		int period = (data[6] << 8) + data[7];
		int info_id = (data[8] << 8) + data[9];
		int value = (data[10] << 8) + data[11];

		if (log) {
			try {
				Timestamp ts = new Timestamp(new Date().getTime());
				writer = new FileWriter(fileName, true);
				writer.write("GW\t" + target_gw + "\tID\t" + node_identifier
						+ "\tSEQ_NO\t" + period + "\tINFO_ID\t" + info_id
						+ "\tVALUE\t" + value + "\t" + ts);
				writer.write("\n");
				writer.flush();
				writer.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		Vector<Integer> v = new Vector<Integer>();
		switch (info_id) {
		case Constants.ROUTING_PARENT:
			v.add(value);
			ret.put(Parent.getFeature(), new Sample(v, new Date(System
					.currentTimeMillis())));
			break;
		case Constants.ROUTING_PARENT_LQI:
			v.add(value);
			ret.put(ParentQuality.getFeature(), new Sample(v, new Date(System
					.currentTimeMillis())));
			break;
		case Constants.BATTERY:
			ret.put(Battery.getFeature(),
					new Sample(Battery.convert((int) value), new Date(System
							.currentTimeMillis())));
			break;
		case Constants.TEMPERATURE:
			ret.put(Temperature.getFeature(),
					new Sample(Temperature.convert((int) value), new Date(
							System.currentTimeMillis())));
			break;

		}
		return ret;
	}

	public SourceId getSource(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[4] << 8) + data[5];
		return new SourceId(node_identifier);
	}

}
