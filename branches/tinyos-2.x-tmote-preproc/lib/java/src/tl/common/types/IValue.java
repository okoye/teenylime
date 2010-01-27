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
 * *	$Id: IValue.java 684 2008-10-01 10:07:49Z mceriotti $
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
 * The Interface IValue.
 * 
 * The interface of one single value, which can be assigned to one single field.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 * 
 * see also lighTS - An extensible and lightweight Linda-like tuplespace
 * Copyright (C) 2001, Gian Pietro Picco
 */

public interface IValue {

	IValue setValue(short[] value) throws IllegalArgumentException;

	boolean isEqual(IValue value);

	boolean isGreater(IValue value);

	boolean isGreaterEqual(IValue value);

	boolean isLower(IValue value);

	boolean isLowerEqual(IValue value);

	boolean isDifferent(IValue value);

	short[] serializeValue();
}
