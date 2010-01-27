/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TaskerCO.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office.console;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import tl.apps.office.Constants;
import tl.apps.office.Properties;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerCO implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerCO() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public String description() {
		return "CO";
	}

	public Tuple getTuple() throws IllegalArgumentException {
		int r = 0;
		int t = 0;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("CO TASK DEFINITION");
		System.out.println("Insert the reporting period in SECONDS (= "
				+ Constants.SECOND + " ms)");
		try {
			r = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the total number of reporting periods (-1 for an infinite task)");
		try {
			t = Integer.parseInt(reader.readLine());
			if (t == -1) {
				t = Constants.INFINITE_OP_TIME;
			}
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.CO)));
		content.add(new Field().actualField(new Uint16(r)));
		content.add(new Field().actualField(new Uint16(t)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field().actualField(new Uint16(Constants.CO)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		return envelope;
	}

}
