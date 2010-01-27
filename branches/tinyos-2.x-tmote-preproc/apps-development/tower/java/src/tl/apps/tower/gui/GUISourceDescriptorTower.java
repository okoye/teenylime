/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 685 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:18:05 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUISourceDescriptorTower.java 685 2008-10-01 10:18:05Z mceriotti $
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

package tl.apps.tower.gui;

import java.awt.Color;
import java.awt.Point;
import java.util.Vector;

import tl.apps.tower.Properties;
import tl.apps.tower.SourceDescriptorTower;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;
import tl.lib.dataCollection.gui._CollectionGUISourceDescriptor;

public class GUISourceDescriptorTower extends SourceDescriptorTower implements
		_CollectionGUISourceDescriptor {

	public GUISourceDescriptorTower() {

	}

	public Color getColor(SourceId sourceId) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceTower source = (GUISourceTower) SourcesManager
					.getSource(sourceId);
			return source.getColor();
		} else {
			return Color.BLACK;
		}
	}

	public Vector<Point> getLocations(SourceId sourceId) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceTower source = (GUISourceTower) SourcesManager
					.getSource(sourceId);
			return source.getLocations();
		} else {
			return new Vector<Point>();
		}
	}

	public void setLocations(SourceId sourceId, Vector<Point> locations) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceTower source = (GUISourceTower) SourcesManager
					.getSource(sourceId);
			source.setLocations(locations);
		}
	}

	public int getMoteRadius(SourceId sourceId) {
		return Properties.MOTE_RADIUS;
	}

	public long getRefreshPeriod(SourceId sourceId) {
		return Properties.MAX_NOSEEN_INTERVAL;
	}

}
