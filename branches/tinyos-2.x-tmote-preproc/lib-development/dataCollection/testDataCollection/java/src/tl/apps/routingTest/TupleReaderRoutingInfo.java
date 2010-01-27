/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 955 $
 * * DATE
 * *    $LastChangedDate: 2009-11-28 16:07:05 -0600 (Sat, 28 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderRoutingInfo.java 955 2009-11-28 22:07:05Z mceriotti $
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
		if (((data[0] << 8) + data[1]) == Constants.ROUTING_INFO_TYPE) {
			int seq_no = (data[2] << 8) + data[3];
			int node_identifier = (data[4] << 8) + data[5];
			int gateway = (data[6] << 8) + data[7];
			int gateway_changes = (data[8] << 8) + data[9];
			int parent = (data[10] << 8) + data[11];
			int cost = (data[12] << 8) + data[13];
			int parent_changes = (data[14] << 8) + data[15];
			int root_congestions = (data[16] << 8) + data[17];
			int subtree_congestions = (data[18] << 8) + data[19];
			int msg_deleted_buffer_overflow = (data[20] << 8) + data[21];
			int successful_recoveries = (data[22] << 8) + data[23];
			int failed_recoveries = (data[24] << 8) + data[25];
			int rd_retries = (data[26] << 8) + data[27];
			int packets_forwarded_0 = (data[28] << 8) + data[29];
			int packets_forwarded_1 = (data[30] << 8) + data[31];
			int packets_forwarded_2 = (data[32] << 8) + data[33];
			int retries_0 = (data[34] << 8) + data[35];
			int retries_1 = (data[36] << 8) + data[37];
			int retries_2 = (data[38] << 8) + data[39];
			int dropped_duplicates = (data[40] << 8) + data[41];
			int out_retries = (data[42] << 8) + data[43];
			int total_send = (data[44] << 8) + data[45];
			int total_retxmit = (data[46] << 8) + data[47];
			int bat = (data[48] << 8) + data[49];
			ret.put(TreeInfo.getFeature(), new Sample(TreeInfo.convert(gateway,
					parent, cost), new Date(System.currentTimeMillis())));
			ret.put(Battery.getFeature(), new Sample(Battery.convert(bat),
					new Date(System.currentTimeMillis())));
			if (log) {
				try {
					Timestamp ts = new Timestamp(new Date().getTime());
					writer = new FileWriter(fileName, true);
					writer.write("ID\t" + node_identifier + "\tSEQ_NO\t"
							+ seq_no + "\tGW\t" + gateway + "\tPAR\t" + parent
							+ "\tGW_CH\t" + gateway_changes + "\tP_COST\t"
							+ cost + "\tPAR_CH\t" + parent_changes
							+ "\tCONG_RS\t" + root_congestions + "\t"
							+ subtree_congestions + "\tDEL_OW\t"
							+ msg_deleted_buffer_overflow + "\tREC_SF\t"
							+ successful_recoveries + "\t" + failed_recoveries
							+ "\tRD_RET\t" + rd_retries + "\tPACK_FW\t"
							+ packets_forwarded_0 + "\t" + packets_forwarded_1
							+ "\t" + packets_forwarded_2 + "\tRETRIES\t"
							+ retries_0 + "\t" + retries_1 + "\t" + retries_2
							+ "\tDROPPED_DUP\t" + dropped_duplicates
							+ "\tOUT_RET\t" + out_retries + "\tTOT_SR\t"
							+ total_send + "\t" + total_retxmit + "\tBAT\t"
							+ bat + "\t" + ts);
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
		int node_identifier = (data[4] << 8) + data[5];
		return new SourceId(node_identifier);
	}

}
