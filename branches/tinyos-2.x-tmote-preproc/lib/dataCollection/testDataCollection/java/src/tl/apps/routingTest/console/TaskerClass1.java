/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 838 $
 * * DATE
 * *    $LastChangedDate: 2009-05-17 03:52:51 -0500 (Sun, 17 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TaskerClass1.java 838 2009-05-17 08:52:51Z mceriotti $
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

import tl.apps.routingTest.Constants;
import tl.apps.routingTest.Properties;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerClass1 implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerClass1() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public String description() {
		return "Class 1";
	}

	public Tuple getTuple() throws IllegalArgumentException {
		int burst_msgs = 0;
		int period = 0;
		int num_sessions = 0;
		int min_report_interval = 1000;
		int ratio_cl = Constants.INFINITE_OP_TIME;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("CLASS 1 TASK DEFINITION");
		System.out.println("Insert the number of messages in a burst");
		try {
			burst_msgs = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the period between bursts in seconds");
		try {
			period = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the total number of sessions (-1 for an infinite task)");
		try {
			num_sessions = Integer.parseInt(reader.readLine());
			if (num_sessions == -1) {
				num_sessions = Constants.INFINITE_OP_TIME;
			}
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the minimum reporting interval between messages (in ms)");
		try {
			min_report_interval = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out
				.println("Insert the ratio of class1 nodes (1 for all, >= #nodes for none)");
		try {
			ratio_cl = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.CLASS_1_TASK)));
		content.add(new Field().actualField(new Uint16(burst_msgs)));
		content.add(new Field().actualField(new Uint16(period)));
		content.add(new Field().actualField(new Uint16(num_sessions)));
		content.add(new Field().actualField(new Uint16(min_report_interval)));
		content.add(new Field().actualField(new Uint16(ratio_cl)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field()
				.actualField(new Uint16(Constants.CLASS_1_TASK)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		return envelope;
	}

}
