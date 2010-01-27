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
 * *	$Id: TaskerTree.java 838 2009-05-17 08:52:51Z mceriotti $
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
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerTree implements _ConsoleDisseminator {

	private BufferedReader reader;

	public TaskerTree() {
		this.reader = new BufferedReader(new InputStreamReader(System.in));
	}

	public void setSerialComm(SerialComm serial) {}

	public String description() {
		return "Refresh the collection tree";
	}

	public Tuple getTuple() throws IllegalArgumentException {
		System.out.println("FORCE TREE REFRESH");
		System.out.println("Insert the id of the tree that you want to build ("
				+ Constants.BUILD_A_NEW_TREE
				+ " for building a new tree wihtout a specific id)");
		int round = Constants.BUILD_A_NEW_TREE;
		try {
			round = Integer.parseInt(reader.readLine());
		} catch (Exception e) {
			throw new IllegalArgumentException(e);
		}
		Tuple tree = new Tuple();
		tree.add(new Field().actualField(new Uint8(
				Constants.DATA_COLLECT_CTRL_TYPE)));
		tree.add(new Field().actualField(new Uint16(0)));
		tree.add(new Field().actualField(new Uint16(round)));
		tree.add(new Field().actualField(new Uint16(0)));
		return tree;
	}
}
