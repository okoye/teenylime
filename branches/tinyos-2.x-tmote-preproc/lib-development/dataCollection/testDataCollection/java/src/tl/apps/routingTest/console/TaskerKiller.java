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
 * *	$Id: TaskerKiller.java 980 2009-12-03 07:11:16Z mceriotti $
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

package tl.apps.routingTest.console;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Vector;

import tl.apps.routingTest.Constants;
import tl.apps.routingTest.Properties;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerKiller implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerKiller() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public String description() {
		return "Kill a node";
	}

	public Vector<Tuple> getTuples() throws IllegalArgumentException {
		int id_1 = 0;
		int id_2 = 0;
		int id_3 = 0;
		int kill_timeout = 0;
		int reborn_timeout = 0;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("KILL A NODE");
		System.out
				.println("Insert the id of the first node to kill");
		try {
			id_1 = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the id of the second node to kill");
		try {
			id_2 = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the id of the third node to kill");
		try {
			id_3 = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the time interval before turning off the radio (in application MINUTES)");
		try {
			kill_timeout = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the time interval before turning on the radio (in real MINUTES)");
		try {
			reborn_timeout = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.KILLING_TASK)));
		content.add(new Field().actualField(new Uint16(id_1)));
		content.add(new Field().actualField(new Uint16(id_2)));
		content.add(new Field().actualField(new Uint16(id_3)));
		content.add(new Field().actualField(new Uint16(kill_timeout)));
		content.add(new Field().actualField(new Uint16(reborn_timeout)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field()
				.actualField(new Uint16(Constants.CLASS_2_TASK)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		Vector<Tuple> ret = new Vector<Tuple>();
		ret.add(envelope);
		return ret;
	}

}
