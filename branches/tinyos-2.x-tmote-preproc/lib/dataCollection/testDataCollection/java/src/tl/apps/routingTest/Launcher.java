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
 * *	$Id: Launcher.java 785 2009-04-29 10:50:15Z mceriotti $
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

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;
import tl.apps.routingTest.console.ConsoleScenarioTests;
import tl.common.serial.SerialComm;
import tl.lib.dataCollection.DataDispenser;
import tl.lib.dataCollection._CollectionScenario;

public class Launcher {

	private static void printUsageAndExit() {
		System.err.println("help: java tl.apps.routingTests.Launcher "
				+ "-comm <source>");
		System.exit(-1);
	}

	public static void main(String[] args) {
		int i = 0;
		String port = "sf@localhost:10001";
		String inte = "console";
		while (i < args.length && args[i].startsWith("-")) {
			String arg = args[i++];
			if (arg.equals("-comm")) {
				if (i < args.length)
					port = args[i++];
				else
					printUsageAndExit();
			}
		}
		if (i != args.length) {
			printUsageAndExit();
		}

		PhoenixSource phoenix = BuildSource.makePhoenix(port,
				PrintStreamMessenger.err);
		MoteIF mif = new MoteIF(phoenix);

		SerialComm serial = new SerialComm(mif);

		_CollectionScenario scenario = null;

		scenario = new ConsoleScenarioTests();
		DataDispenser manager = new DataDispenser(scenario);
		serial.addListener(manager);
		scenario.setSerial(serial);
		serial.activate();
		manager.activate();
		scenario.start();
	}
}
