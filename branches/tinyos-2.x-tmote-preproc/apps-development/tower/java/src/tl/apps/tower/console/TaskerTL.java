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
 * *	$Id: TaskerTL.java 980 2009-12-03 07:11:16Z mceriotti $
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

package tl.apps.tower.console;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Vector;

import tl.apps.tower.Constants;
import tl.apps.tower.Properties;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerTL implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerTL() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public String description() {
		return "Temperature/Light";
	}

	public Vector<Tuple> getTuples() throws IllegalArgumentException {
		int t = 0;
		int n = 0;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("TEMPERATURE/LIGHT TASK DEFINITION");
		System.out.println("Insert the sampling period (SP) in minutes");
		try {
			t = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the total number (N) of samples (-1 for an infinite task)");
		try {
			n = Integer.parseInt(reader.readLine());
			if (n == -1) {
				n = Constants.INFINITE_OP_TIME;
			}
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.TL_TASK)));
		content.add(new Field().actualField(new Uint16(t)));
		content.add(new Field().actualField(new Uint16(n)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field().actualField(new Uint16(Constants.TL_TASK)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		Vector<Tuple> ret = new Vector<Tuple>();
		ret.add(envelope);
		return ret;
	}

}
