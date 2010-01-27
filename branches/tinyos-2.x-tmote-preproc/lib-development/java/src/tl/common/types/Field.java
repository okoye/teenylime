/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 684 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:07:49 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Field.java 684 2008-10-01 10:07:49Z mceriotti $
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
 * The Class Field.
 * 
 * This class represents one single field in a tuple.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 * 
 * see also lighTS - An extensible and lightweight Linda-like tuplespace
 * Copyright (C) 2001, Gian Pietro Picco
 */

public class Field {

	protected final static short MATCH_EQUAL = 0;
	protected final static short MATCH_ACTUAL = 0; // i.e. equal
	protected final static short MATCH_DONT_CARE = 1;
	protected final static short MATCH_GREATER = 2;
	protected final static short MATCH_GREATER_EQUAL = 3;
	protected final static short MATCH_LOWER = 4;
	protected final static short MATCH_LOWER_EQUAL = 5;
	protected final static short MATCH_DIFFERENT = 6;

	private short match_type = Field.MATCH_ACTUAL;
	private IValue value;

	public Field() {
		super();
	}

	public IValue getValue() {
		return value;
	}

	public short getMatchType() {
		return match_type;
	}

	public Field setField(short match_type, IValue value) {
		this.match_type = match_type;
		this.value = value;
		return this;
	}

	public boolean matches(Field field) {
		if (this.match_type == Field.MATCH_DONT_CARE
				|| field.match_type == Field.MATCH_DONT_CARE) {
			return true;
		}
		if (this.match_type != Field.MATCH_ACTUAL
				&& field.match_type != Field.MATCH_ACTUAL) {
			return false;
		}
		if (this.match_type == Field.MATCH_GREATER
				|| field.match_type == Field.MATCH_LOWER) {
			return this.value.isLower(field.value);
		}
		if (this.match_type == Field.MATCH_LOWER
				|| field.match_type == Field.MATCH_GREATER) {
			return this.value.isGreater(field.value);
		}
		if (this.match_type == Field.MATCH_GREATER_EQUAL
				|| field.match_type == Field.MATCH_LOWER_EQUAL) {
			return this.value.isLowerEqual(field.value);
		}
		if (this.match_type == Field.MATCH_LOWER_EQUAL
				|| field.match_type == Field.MATCH_GREATER_EQUAL) {
			return this.value.isGreaterEqual(field.value);
		}
		if (this.match_type == Field.MATCH_DIFFERENT
				|| field.match_type == Field.MATCH_DIFFERENT) {
			return this.value.isDifferent(field.value);
		}
		return this.value.isEqual(field.value);
	}

	public Field actualField(IValue value) {
		this.match_type = Field.MATCH_ACTUAL;
		this.value = value;
		return this;
	}

	public Field equalField(IValue value) {
		this.match_type = Field.MATCH_EQUAL;
		this.value = value;
		return this;
	}

	public Field dontCareField(IValue value) {
		this.match_type = Field.MATCH_DONT_CARE;
		this.value = value;
		return this;
	}

	public Field greaterField(IValue value) {
		this.match_type = Field.MATCH_GREATER;
		this.value = value;
		return this;
	}

	public Field greaterEqualField(IValue value) {
		this.match_type = Field.MATCH_GREATER_EQUAL;
		this.value = value;
		return this;
	}

	public Field lowerField(IValue value) {
		this.match_type = Field.MATCH_LOWER;
		this.value = value;
		return this;
	}

	public Field lowerEqualField(IValue value) {
		this.match_type = Field.MATCH_LOWER_EQUAL;
		this.value = value;
		return this;
	}

	public Field differentField(IValue value) {
		this.match_type = Field.MATCH_DIFFERENT;
		this.value = value;
		return this;
	}

	public String toString() {
		String result = null;
		result = "[match_type = " + match_type + ", value = "
				+ value.toString() + "]";
		return result;
	}
}