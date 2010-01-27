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
 * *	$Id: GUISourceDescriptorOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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
import tl.apps.office.SourceDescriptorOffice;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;
import tl.lib.dataCollection.gui._CollectionGUISourceDescriptor;

public class GUISourceDescriptorOffice extends SourceDescriptorOffice implements
		_CollectionGUISourceDescriptor {

	public GUISourceDescriptorOffice() {

	}

	public Color getColor(SourceId sourceId) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceOffice source = (GUISourceOffice) SourcesManager
					.getSource(sourceId);
			return source.getColor();
		} else {
			return Color.BLACK;
		}
	}

	public Vector<Point> getLocations(SourceId sourceId) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceOffice source = (GUISourceOffice) SourcesManager
					.getSource(sourceId);
			return source.getLocations();
		} else {
			return new Vector<Point>();
		}
	}

	public void setLocations(SourceId sourceId, Vector<Point> locations) {
		if (SourcesManager.exists(sourceId)) {
			GUISourceOffice source = (GUISourceOffice) SourcesManager
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
