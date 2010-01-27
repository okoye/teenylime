/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 886 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:23:32 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUISourceTunnel.java 886 2009-07-15 16:23:32Z mceriotti $
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

package tl.apps.tunnel.gui;

import java.awt.Color;
import java.awt.Point;
import java.util.Vector;

import tl.apps.tunnel.Properties;
import tl.apps.tunnel.SourceTunnel;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection.data.SourceId;

public class GUISourceTunnel extends SourceTunnel {

	private Vector<Point> locations;
	private Color color;

	public GUISourceTunnel(SourceId identifier, boolean sink,
			_CollectionFeature battery, _CollectionFeature treeInfo,
			_CollectionFeature parent, _CollectionFeature parentQuality) {
		super(identifier, sink, battery, treeInfo, parent, parentQuality);
		locations = new Vector<Point>();
		locations.add(new Point(Properties.initialPrimaryXPosition(identifier),
				Properties.initialPrimaryYPosition(identifier)));
		color = Properties.initialColor(identifier);
	}

	public Vector<Point> getLocations() {
		return locations;
	}

	public void setLocations(Vector<Point> locations) {
		this.locations = locations;
	}

	public Color getColor() {
		return color;
	}
}
