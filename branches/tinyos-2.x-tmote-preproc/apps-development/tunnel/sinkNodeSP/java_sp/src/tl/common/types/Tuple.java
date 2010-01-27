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
 * *	$Id: Tuple.java 1018 2010-01-11 08:36:37Z mceriotti $
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
 * The Class Tuple.
 * 
 * This class represents one single tuple.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 * see also lighTS - An extensible and lightweight Linda-like tuplespace
 * Copyright (C) 2001, Gian Pietro Picco
 */

public class Tuple {
	private Vector<Field> fields = null;
	private int logicalTime = 0;
	private int expireIn = 0;
	private boolean capabilityT = false;

	public Tuple() {
		fields = new Vector<Field>();
	}

	public Tuple add(Field field) {
		fields.addElement(field);
		return this;
	}

	public Field get(int index) {
		return ((Field) fields.elementAt(index));
	}

	public int length() {
		return fields.size();
	}
	
	public boolean matches(Tuple tuple) {
		if (fields.size() == 0)
			return true;
		boolean matching = (fields.size() == tuple.length());
		int i = 0;
		while (matching && i < fields.size()) {
			matching = matching
					&& ((Field) fields.elementAt(i)).matches(tuple.get(i));
			i++;
		}
		return matching;
	}

	public int getLogicalTime() {
		return logicalTime;
	}

	public void setLogicalTime(int logicalTime) {
		this.logicalTime = logicalTime;
	}

	public int getExpireIn() {
		return expireIn;
	}

	public void setExpireIn(int expireIn) {
		this.expireIn = expireIn;
	}

	public boolean isCapabilityT() {
		return capabilityT;
	}

	public void setCapabilityT(boolean capabilityT) {
		this.capabilityT = capabilityT;
	}
	
	public String toString() {
		String result = null;
		for (int i = 0; i < length(); i++)
			result = (result == null) ? (get(i).toString())
					: (result + ", " + get(i).toString());
		return "<" + result + ">";
	}
}