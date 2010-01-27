/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 845 $
 * * DATE
 * *    $LastChangedDate: 2009-05-20 08:51:51 -0500 (Wed, 20 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: AppletSourceTower.java 845 2009-05-20 13:51:51Z mceriotti $
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

package tl.apps.tower.applet;

import java.awt.Color;
import java.awt.Point;
import java.util.Vector;

import tl.apps.tower.Properties;
import tl.apps.tower.SourceTower;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection.data.SourceId;

public class AppletSourceTower extends SourceTower {

	private Vector<Point> locations;
	private Color color;

	public AppletSourceTower(SourceId identifier, boolean sink, _CollectionFeature battery,
			_CollectionFeature treeInfo) {
		super(identifier, sink, battery, treeInfo);
		locations = new Vector<Point>();
		locations.add(new Point(Properties.initialPrimaryXPosition(identifier),
				Properties.initialPrimaryYPosition(identifier)));
		locations.add(new Point(Properties
				.initialSecondaryXPosition(identifier), Properties
				.initialSecondaryYPosition(identifier)));
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
