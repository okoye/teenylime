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
 * *	$Id: TupleReaderRoutingInfo.java 785 2009-04-29 10:50:15Z mceriotti $
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
import java.util.Date;
import java.util.Hashtable;

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderRoutingInfo implements _CollectionTupleReader {
	private FileWriter writer;
	private String fileName = "routing_info.txt";
	private boolean log;

	public TupleReaderRoutingInfo() {
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
		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		if (data[0] == Constants.ROUTING_INFO_TYPE_I) {
			int seq_no = (data[1] << 8) + data[2];
			int node_identifier = (data[3] << 8) + data[4];
			int bat = (data[5] << 8) + data[6];
			int parent = (data[7] << 8) + data[8];
			int cost = (data[9] << 8) + data[10];
			int parent_changes = (data[11] << 8) + data[12];
			int root_congestions = (data[13] << 8) + data[14];
			int subtree_congestions = (data[15] << 8) + data[16];
			int msg_deleted_buffer_overflow = (data[17] << 8) + data[18];
			int successful_recoveries = (data[19] << 8) + data[20];
			int failed_recoveries = (data[21] << 8) + data[22];
			int rd_retries = (data[23] << 8) + data[24];
			ret.put(Battery.getFeature(), new Sample(Battery.convert(bat),
					new Date(System.currentTimeMillis())));
			ret.put(TreeInfo.getFeature(), new Sample(TreeInfo.convert(parent,
					cost), new Date(System.currentTimeMillis())));
			if (log) {
				try {
					Timestamp ts = new Timestamp(new Date().getTime());
					writer = new FileWriter(fileName, true);
					writer.write("ID\t" + node_identifier + "\tSEQ_NO\t"
							+ seq_no + "\tBAT\t" + bat + "\tPAR\t" + parent
							+ "\tP_COST\t" + cost + "\tNUM_P\t"
							+ parent_changes + "\tCONG_RS\t" + root_congestions
							+ "\t" + subtree_congestions + "\tDEL_OW\t"
							+ msg_deleted_buffer_overflow + "\tREC_SF\t"
							+ successful_recoveries + "\t" + failed_recoveries
							+ "\tRD_RET\t" + rd_retries + "\t" + ts);
					writer.write("\n");
					writer.flush();
					writer.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		} else if (data[0] == Constants.ROUTING_INFO_TYPE_II) {
			int seq_no = (data[1] << 8) + data[2];
			int node_identifier = (data[3] << 8) + data[4];
			int packets_forwarded_0 = (data[5] << 8) + data[6];
			int packets_forwarded_1 = (data[7] << 8) + data[8];
			int packets_forwarded_2 = (data[9] << 8) + data[10];
			int retries_0 = (data[11] << 8) + data[12];
			int retries_1 = (data[13] << 8) + data[14];
			int retries_2 = (data[15] << 8) + data[16];
			int dropped_duplicates = (data[17] << 8) + data[18];
			int out_retries = (data[19] << 8) + data[20];
			int total_send = (data[21] << 8) + data[22];
			int total_retxmit = (data[23] << 8) + data[24];
			ret.put(new FeatureTest(FeatureTest.NULL, "Null"), new Sample(null, new Date(
					System.currentTimeMillis())));
			if (log) {
				try {
					Timestamp ts = new Timestamp(new Date().getTime());
					writer = new FileWriter(fileName, true);
					writer.write("ID\t" + node_identifier + "\tSEQ_NO\t"
							+ seq_no + "\tPACK_FW\t" + packets_forwarded_0
							+ "\t" + packets_forwarded_1 + "\t"
							+ packets_forwarded_2 + "\tRETRIES\t" + retries_0
							+ "\t" + retries_1 + "\t" + retries_2
							+ "\tDROPPED_DUP\t" + dropped_duplicates
							+ "\tOUT_RET\t" + out_retries + "\tTOT_SR\t"
							+ total_send + "\t" + total_retxmit + "\t" + ts);
					writer.write("\n");
					writer.flush();
					writer.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
		return ret;
	}

	public SourceId getSource(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[3] << 8) + data[4];
		return new SourceId(node_identifier);
	}

}
