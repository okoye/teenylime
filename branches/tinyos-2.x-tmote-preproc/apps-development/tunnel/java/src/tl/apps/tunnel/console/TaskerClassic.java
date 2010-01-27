/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 980 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 01:11:16 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TaskerClassic.java 980 2009-12-03 07:11:16Z mceriotti $
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

package tl.apps.tunnel.console;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Vector;

import tl.apps.tunnel.Properties;
import tl.apps.tunnel.Constants;
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerClassic implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerClassic() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public void setSerialComm(SerialComm serial) {
	}

	public String description() {
		return "Normal Operating Behavior";
	}

	public Vector<Tuple> getTuples() throws IllegalArgumentException {
		int s = 0;
		int n = 0;
		int o = 0;
		int a = 1;
		int lpl = 0;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("OPERATING PARAMETERS");
		System.out.println("Insert the sampling period (SP) in milliseconds");
		try {
			s = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the number of samples (N) in the aggregation (the reporting period is N * SP seconds)");
		try {
			n = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the low power listening interval");
		try {
			lpl = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.TUNING)));
		content.add(new Field().actualField(new Uint16(s)));
		content.add(new Field().actualField(new Uint16(n)));
		content.add(new Field().actualField(new Uint16(o)));
		content.add(new Field().actualField(new Uint16(a)));
		content.add(new Field().actualField(new Uint16(lpl)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field().actualField(new Uint16(Constants.TUNING)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		Vector<Tuple> ret = new Vector<Tuple>();
		ret.add(envelope);
		return ret;
	}
}
