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
 * *	$Id: TaskerTune.java 838 2009-05-17 08:52:51Z mceriotti $
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

public class TaskerTune implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerTune() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public String description() {
		return "Tuning test parameters";
	}

	public Tuple getTuple() throws IllegalArgumentException {
		int lpl = 0;
		int cache_size = 0;
		int recovery_retries = 0;
		int reliable_lpl = 0;
    	int rebuilding_frequency = 180;
		Tuple content = new Tuple();
		Tuple envelope = new Tuple();
		System.out.println("TUNING TEST PARAMETERS");
		System.out.println("Insert the remote LPL interval");
		try {
			lpl = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the size of the message cache");
		try {
			cache_size = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the number of recovery retries");
		try {
			recovery_retries = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the local LPL interval for reliable paths");
		try {
			reliable_lpl = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		System.out.println("Insert the tree rebuilding frequency (in application MINUTES)");
		try {
			rebuilding_frequency = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		content.add(new Field().actualField(new Uint8(Constants.TASK_TYPE)));
		content.add(new Field().actualField(new Uint8(Constants.TUNING_TASK)));
		content.add(new Field().actualField(new Uint16(lpl)));
		content.add(new Field().actualField(new Uint16(cache_size)));
		content.add(new Field().actualField(new Uint16(recovery_retries)));
		content.add(new Field().actualField(new Uint16(reliable_lpl)));
		content.add(new Field().actualField(new Uint16(rebuilding_frequency)));
		envelope.add(new Field().actualField(new Uint8(
				Constants.DISSEMINATION_TYPE)));
		envelope.add(new Field().actualField(new Uint16(
				Constants.DISSEMINATE_A_NEW_TUPLE)));
		envelope.add(new Field()
				.actualField(new Uint16(Constants.CLASS_2_TASK)));
		envelope.add(new Field().actualField(new Uint8Array(
				Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
				.toSerial(content))));
		return envelope;
	}

}
