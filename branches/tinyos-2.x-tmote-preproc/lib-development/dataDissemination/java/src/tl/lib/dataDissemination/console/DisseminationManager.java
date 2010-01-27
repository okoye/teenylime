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
 * *	$Id: DisseminationManager.java 980 2009-12-03 07:11:16Z mceriotti $
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

package tl.lib.dataDissemination.console;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Vector;

import net.tinyos.message.*;

import tl.common.serial.SerialComm;
import tl.common.types.Tuple;

public class DisseminationManager extends Thread {

	private SerialComm serial;
	private Vector<_ConsoleDisseminator> taskers;
	private _DisseminationConsoleScenario scenario;
	private BufferedReader reader;
	private boolean active;

	public DisseminationManager(_DisseminationConsoleScenario scenario) {
		this.serial = null;
		this.active = false;
		this.reader = new BufferedReader(new InputStreamReader(System.in));
		this.scenario = scenario;
	}

	public void setSerialComm(SerialComm serial) {
		this.serial = serial;
	}

	public void activate() {
		active = true;
		new Thread(this).start();
	}

	public void run() {
		while (active) {
			int type = 0;
			if (serial == null)
				System.err.println("NO SENDER");
			taskers = scenario.getDisseminators();
			if (scenario.isResettable())
				System.out.println("0) Reset the network");
			for (int i = 0; i < taskers.size(); i++) {
				System.out.println((i + 1) + ") "
						+ taskers.get(i).description());
			}
			try {
				type = Integer.parseInt(reader.readLine());
				if (scenario.isResettable() && type == 0) {
					Message reset = scenario.getResetMessage();
					if (serial != null) {
						System.out.print("CHOOSE A SERIAL\n"
								+ "1) One serial connection\n"
								+ "2) All serial connections\n"
								+ "3) A specific serial connection\n");
						int s_type = Integer.parseInt(reader.readLine());
						switch (s_type) {
						case 1:
							serial.sendToOne(reset);
							break;
						case 2:
							serial.sendToAll(reset);
							break;
						case 3:
							Vector<MoteIF> motes = serial.getSerials();
							System.out.println("Available serial connections");
							for (int i = 0; i < motes.size(); i++) {
								System.out.println((i + 1)
										+ ") "
										+ motes.get(i).getSource()
												.getPacketSource().getName());
							}
							int specified_s = Integer.parseInt(reader
									.readLine());
							if (specified_s > motes.size() || specified_s <= 0) {
								System.err.println("WRONG INPUT");
							} else {
								serial
										.sendTo(reset, motes
												.get(specified_s - 1));
							}
							break;
						default:
						}
					} else {
						System.err.println("NO AVAILABLE SERIAL CONNECTION");
					}
				}
				if (type > 0 && type <= taskers.size()) {
					Vector<Tuple> tuples = taskers.get(type - 1).getTuples();
					if (serial != null) {
						System.out.print("CHOOSE A SERIAL\n"
								+ "1) One serial connection\n"
								+ "2) All serial connections\n"
								+ "3) A specific serial connection\n");
						int s_type = Integer.parseInt(reader.readLine());
						switch (s_type) {
						case 1:
							for (int i = 0; i < tuples.size(); i++)
								serial.sendToOne(tuples.get(i));
							break;
						case 2:
							for (int i = 0; i < tuples.size(); i++)
								serial.sendToAll(tuples.get(i));
							break;
						case 3:
							Vector<MoteIF> motes = serial.getSerials();
							System.out.println("Available serial connections");
							for (int i = 0; i < motes.size(); i++) {
								System.out.println((i + 1)
										+ ") "
										+ motes.get(i).getSource()
												.getPacketSource().getName());
							}
							int specified_s = Integer.parseInt(reader
									.readLine());
							if (specified_s > motes.size() || specified_s <= 0) {
								System.err.println("WRONG INPUT");
							} else {
								for (int i = 0; i < tuples.size(); i++)
									serial.sendTo(tuples.get(i), motes
											.get(specified_s - 1));
							}
							break;
						default:
						}
					} else {
						System.err.println("NO AVAILABLE SERIAL CONNECTION");
					}
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	public void deactivate() {
		active = false;
	}
}
