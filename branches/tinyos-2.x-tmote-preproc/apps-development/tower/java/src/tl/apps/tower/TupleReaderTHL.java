/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 976 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 00:57:54 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderTHL.java 976 2009-12-03 06:57:54Z mceriotti $
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

public class TupleReaderTHL implements _CollectionTupleReader {
	private FileWriter writer;
	private String dirName = "";
	private boolean log;
	private boolean newSession = true;
	private String currentSessionBeginTimestamp = "";

	public TupleReaderTHL() {
		this.log = false;
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
		boolean ending = false;
		if ((data[0] << 8 + data[1]) == Constants.TEMP_HUM_LIGHT_END_SESSION) {
			ending = true;
		}
		int node_identifier = (data[2] << 8) + data[3];
		int period = (data[4] << 8) + data[5];
		int temperature = (data[6] << 8) + data[7];
		int humidity = (data[8] << 8) + data[9];
		int solarLight = (data[10] << 8) + data[11];
		int synthLight = (data[12] << 8) + data[13];
		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		ret.put(Temperature.getFeature(), new Sample(Temperature
				.convertTmote(temperature), period, new Date(System
				.currentTimeMillis()), ending));
		ret.put(Humidity.getFeature(), new Sample(Humidity.convert(humidity,
				Temperature.convertTmote(temperature).get(0)), period,
				new Date(System.currentTimeMillis()), ending));
		ret.put(SolarLight.getFeature(), new Sample(SolarLight
				.convert(solarLight), period, new Date(System
				.currentTimeMillis()), ending));
		ret.put(SynthLight.getFeature(), new Sample(SynthLight
				.convert(synthLight), period, new Date(System
				.currentTimeMillis()), ending));
		if (log) {
			String fileName = "";
			if (dirName.length() > 0)
				fileName += dirName + File.separator;
			Calendar cal = Calendar.getInstance(Locale.ITALY);

			// session type
			String currentSessionType = "thl";

			if (newSession) {
				// session begin timestamp
				newSession = false;
				currentSessionBeginTimestamp = cal.get(Calendar.YEAR) + "-"
						+ (1 + cal.get(Calendar.MONTH)) + "-"
						+ cal.get(Calendar.DAY_OF_MONTH) + "-"
						+ cal.get(Calendar.HOUR_OF_DAY) + "-"
						+ cal.get(Calendar.MINUTE);
			}
			if (ending) {
				/* TODO: handle change of session */
			}

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
				writer.write("SENSOR\t"
						+ node_identifier
						+ "\tPERIOD\t"
						+ period
						+ "\tTEMPERATURE\t"
						+ temperature
						+ ""
						+ "\t"
						+ Temperature.convertTmote(temperature).get(0)
						+ "\tHUMIDITY\t"
						+ humidity
						+ "\t"
						+ Humidity.convert(humidity,
								Temperature.convertTmote(temperature).get(0))
								.get(0) + "\tSOLAR_LIGHT\t" + solarLight + "\t"
						+ SolarLight.convert(solarLight).get(0)
						+ "\tSYNTH_LIGHT\t" + synthLight + "\t"
						+ SynthLight.convert(synthLight).get(0)
						+ "\tTIMESTAMP\t" + ts);
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
