/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 997 $
 * * DATE
 * *    $LastChangedDate: 2009-12-07 16:19:22 -0600 (Mon, 07 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TaskerSynch.java 997 2009-12-07 22:19:22Z mceriotti $
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

import java.util.Vector;

import tl.apps.tower.Constants;
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.lib.dataDissemination.console._ConsoleDisseminator;

public class TaskerSynch implements _ConsoleDisseminator {

	public TaskerSynch() {
	}

	public void setSerialComm(SerialComm serial) {
	}

	public String description() {
		return "Synchronize the network";
	}

	public Vector<Tuple> getTuples() throws IllegalArgumentException {
		System.out.println("FORCE SYNCHRONIZATION");
		Tuple synch = new Tuple();
		synch.add(new Field().actualField(new Uint8(
				Constants.SYNCHRONIZATION_TYPE)));
		synch.add(new Field().actualField(new Uint16(0)));
		synch.add(new Field().actualField(new Uint16(0)));
		synch.add(new Field().actualField(new Uint16(0)));
		Vector<Tuple> ret = new Vector<Tuple>();
		ret.add(synch);
		return ret;
	}
}
