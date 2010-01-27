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
 * *	$Id: Uint16.java 1018 2010-01-11 08:36:37Z mceriotti $
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

/**
 * The Class Uint16.
 * 
 * This class represents one value of uint16_t type.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

public class Uint16 implements IValue {

	private int current_value;
	private boolean value_assigned;

	public Uint16() {
		this.value_assigned = false;
		this.current_value = 0;
	}

	public Uint16(int value) throws IllegalArgumentException {
		if (value > 0xFFFF || value < 0)
			throw new IllegalArgumentException("Unaccepted value");
		this.current_value = value;
		this.value_assigned = true;
	}

	public int getValue() {
		return this.current_value;
	}

	public boolean isDifferent(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value != ((Uint16) value).current_value;
		}
		return false;
	}

	public boolean isEqual(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value == ((Uint16) value).current_value;
		}
		return false;
	}

	public boolean isGreater(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value > ((Uint16) value).current_value;
		}
		return false;
	}

	public boolean isGreaterEqual(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value >= ((Uint16) value).current_value;
		}
		return false;
	}

	public boolean isLower(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value < ((Uint16) value).current_value;
		}
		return false;
	}

	public boolean isLowerEqual(IValue value) {
		if (value_assigned && value instanceof Uint16) {
			return this.current_value <= ((Uint16) value).current_value;
		}
		return false;
	}

	public short[] serializeValue() {
		short[] result = new short[2];
		if (!value_assigned) {
			result[0] = 0;
			result[1] = 0;
		} else {
			result[0] = (short) (current_value >> 8);
			result[1] = (short) (current_value & 0xFF);
		}
		return result;
	}

	public IValue setValue(short[] value) throws IllegalArgumentException {
		if (value.length != 2)
			throw new IllegalArgumentException("Unknown serialized value");
		this.current_value = (value[0] << 8) + value[1];
		this.value_assigned = true;
		return this;
	}

	public String toString() {
		String result = null;
		if (!value_assigned)
			result = "Uint16";
		else
			result = "(Uint16) " + current_value;
		return result;
	}
}
