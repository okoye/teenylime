/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUISourceOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office.gui;

import java.awt.Color;
import java.awt.Point;
import java.util.Vector;

import tl.apps.office.Properties;
import tl.apps.office.SourceOffice;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection.data.SourceId;

public class GUISourceOffice extends SourceOffice {

	private Vector<Point> locations;
	private Color color;

	public GUISourceOffice(SourceId identifier, boolean sink,
			_CollectionFeature battery, _CollectionFeature treeInfo) {
		super(identifier, sink, battery, treeInfo);
		locations = new Vector<Point>();
		locations.add(new Point(Properties.initialPrimaryXPosition(identifier),
				Properties.initialPrimaryYPosition(identifier)));
		color = Properties.initialColor(identifier);
	}

	public Color getColor() {
		return color;
	}

	public Vector<Point> getLocations() {
		return locations;
	}

	public void setLocations(Vector<Point> locations) {
		this.locations = locations;
	}
}
