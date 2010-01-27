/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1015 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:15:23 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Launcher.java 1015 2010-01-11 08:15:23Z mceriotti $
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

package tl.apps.tunnel;

import java.util.Enumeration;
import java.util.Vector;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;
import tl.apps.tunnel.console.ConsoleScenarioTunnel;
import tl.apps.tunnel.gui.GUIScenarioTunnel;
import tl.common.serial.SerialComm;
import tl.lib.dataCollection.DataDispenser;
import tl.lib.dataCollection._CollectionScenario;

public class Launcher {

	private static void printUsageAndExit() {
		System.err.println("help: java tl.apps.tunnel.Launcher "
				+ "[-comm <source>]+ -interface <console|gui>");
		System.exit(-1);
	}

	public static void main(String[] args) {
		int i = 0;
		String port = "sf@tikisola.dit.unitn.it:9999";
		String inte = "gui";
		Vector<String> ports = new Vector<String>();
		Vector<MoteIF> nodes = new Vector<MoteIF>();
		boolean def_comm = true;
		while (i < args.length && args[i].startsWith("-")) {
			String arg = args[i++];
			if (arg.equals("-comm")) {
				def_comm = false;
				if (i < args.length)
					ports.add(args[i++]);
				else
					printUsageAndExit();
			} else if (arg.equals("-interface")) {
				if (i < args.length)
					inte = args[i++];
				else
					printUsageAndExit();
			}
		}
		if (i != args.length) {
			printUsageAndExit();
		}

		if (def_comm)
			ports.add(port);

		Enumeration<String> el = ports.elements();
		while (el.hasMoreElements()) {
			PhoenixSource phoenix = BuildSource.makePhoenix(el.nextElement(),
					PrintStreamMessenger.err);
			nodes.add(new MoteIF(phoenix));
		}

		SerialComm serial = new SerialComm(nodes);

		_CollectionScenario scenario = null;

		if (inte.equals("console"))
			scenario = new ConsoleScenarioTunnel();
		else if (inte.equals("gui"))
			scenario = new GUIScenarioTunnel();
		else
			printUsageAndExit();

		DataDispenser manager = new DataDispenser(scenario);
		serial.addListener(manager);
		scenario.setSerial(serial);
		serial.activate();
		manager.activate();
		scenario.start();
	}
}
