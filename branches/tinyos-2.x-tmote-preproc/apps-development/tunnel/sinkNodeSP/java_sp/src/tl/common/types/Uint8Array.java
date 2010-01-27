/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1018 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:36:37 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Uint8Array.java 1018 2010-01-11 08:36:37Z mceriotti $
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

package tl.common.types;

import java.util.Vector;

/**
 * The Class Uint8Array.
 * 
 * This class represents an array of values of uint8_t type.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

public class Uint8Array implements IValue {

	private Vector<Uint8> current_value;
	private int size;
	private boolean value_assigned;

	public Uint8Array(int size) {
		this.current_value = new Vector<Uint8>();
		this.value_assigned = false;
		this.size = size;
		for (int i = 0; i < size; i++)
			this.current_value.add(new Uint8((short) 0));
	}

	public Uint8Array(Uint8[] value) throws IllegalArgumentException {
		this.current_value = new Vector<Uint8>();
		for (int i = 0; i < value.length; i++) {
			this.current_value.add(value[i]);
		}
		this.size = value.length;
		this.value_assigned = true;
	}

	public int getSize() {
		return this.size;
	}

	public boolean isDifferent(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isDifferent(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public boolean isEqual(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isEqual(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public boolean isGreater(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isGreater(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public boolean isGreaterEqual(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isGreaterEqual(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public boolean isLower(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isLower(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public boolean isLowerEqual(IValue value) {
		if (value_assigned && value instanceof Uint8Array) {
			Uint8Array comp = (Uint8Array) value;
			boolean matching = current_value.size() == comp.current_value
					.size();
			for (int i = 0; i < current_value.size() && matching; i++)
				matching = this.current_value.get(i).isLowerEqual(
						comp.current_value.get(i));
			return matching;
		}
		return false;
	}

	public short[] serializeValue() {
		short[] result = new short[size];
		if (!value_assigned) {
			for (int i = 0; i < size; i++)
				result[i] = 0;
		} else {
			for (int i = 0; i < current_value.size(); i++)
				result[i] = current_value.get(i).serializeValue()[0];
		}
		return result;
	}

	public IValue setValue(short[] value) throws IllegalArgumentException {
		if (value.length == 0)
			throw new IllegalArgumentException("Unknown serialized value");
		this.current_value = new Vector<Uint8>();
		for (int i = 0; i < value.length; i++)
			this.current_value.add(new Uint8(value[i]));
		for (int i = value.length; i < size; i++)
			this.current_value.add(new Uint8((short) 0));
		this.value_assigned = true;
		return this;
	}

	public String toString() {
		String result = null;
		if (!value_assigned)
			result = "Uint8Array";
		else {
			result = "(Uint8Array)";
			for (int i = 0; i < current_value.size(); i++)
				result += " " + current_value.get(i).toString();
		}
		return result;
	}

}
