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
 * *	$Id: SourceDrawer.java 845 2009-05-20 13:51:51Z mceriotti $
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

/*
 * Copyright (c) 2007 University College Dublin.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL UNIVERSITY COLLEGE DUBLIN BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
 * UNIVERSITY COLLEGE DUBLIN HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * UNIVERSITY COLLEGE DUBLIN SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND UNIVERSITY COLLEGE DUBLIN HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Raja Jurdak, Antonio Ruzzelli, and Samuel Boivineau
 * Date created: 2007/09/07
 *
 */

/**
 * @author Raja Jurdak, Antonio Ruzzelli, and Samuel Boivineau
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

package tl.lib.dataCollection.gui;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.geom.Ellipse2D;
import java.awt.geom.QuadCurve2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Vector;

import javax.imageio.ImageIO;

import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class SourceDrawer {

	private MapPanel mapPanel;
	private Source sourceSelected = null;
	private Vector<Boolean> moving = null;
	private _CollectionGUISourceDescriptor sourceDescriptor;
	private BufferedImage moteImage;

	public SourceDrawer(_CollectionGUIScenario scenario, MapPanel mapPanel) {
		this.mapPanel = mapPanel;
		this.sourceDescriptor = scenario.getSourceDescriptor();
		try {
			ClassLoader cl = this.getClass().getClassLoader();
			moteImage = ImageIO
					.read(cl
							.getResource("tl/lib/dataCollection/gui/images/lost.png"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void drawSource(SourceId sourceId, Graphics2D g2) {
		Source source = SourcesManager.getSource(sourceId);
		if (source.isSink()) {
			Vector<Point> locations = sourceDescriptor.getLocations(sourceId);
			for (int i = 0; i < locations.size(); i++) {
				Color color = sourceDescriptor.getColor(sourceId);
				g2.setPaint(new Color(color.getRed(), color.getGreen(), color
						.getBlue(), 100));
				Point point = mapPanel.toActualPoint(locations.get(i));
				point.x -= 1.5 * sourceDescriptor.getMoteRadius(sourceId);
				point.y -= 1.5 * sourceDescriptor.getMoteRadius(sourceId);
				g2.fill(new Ellipse2D.Double(point.getX(), point.getY(),
						3 * sourceDescriptor.getMoteRadius(sourceId),
						3 * sourceDescriptor.getMoteRadius(sourceId)));
				g2.setPaint(color);
				point = mapPanel.toActualPoint(locations.get(i));
				point.x -= sourceDescriptor.getMoteRadius(sourceId);
				point.y -= sourceDescriptor.getMoteRadius(sourceId);
				g2.fill(new Ellipse2D.Double(point.getX(), point.getY(),
						2 * sourceDescriptor.getMoteRadius(sourceId),
						2 * sourceDescriptor.getMoteRadius(sourceId)));
			}
		} else {
			Vector<Point> locations = sourceDescriptor.getLocations(sourceId);
			for (int i = 0; i < locations.size(); i++) {
				if (source.getLastTimeSeen().getTime() < System
						.currentTimeMillis()
						- sourceDescriptor.getRefreshPeriod(sourceId)) {
					Point point = mapPanel.toActualPoint(locations.get(i));
					point.x -= sourceDescriptor.getMoteRadius(sourceId);
					point.y -= sourceDescriptor.getMoteRadius(sourceId);
					g2.setPaint(new Color(Color.red.getRed(), Color.red
							.getGreen(), Color.red.getBlue(), 150));
					g2.fill(new Ellipse2D.Double(point.getX(), point.getY(),
							2 * sourceDescriptor.getMoteRadius(sourceId),
							2 * sourceDescriptor.getMoteRadius(sourceId)));
					g2.drawImage(moteImage, (int) point.getX()
							- sourceDescriptor.getMoteRadius(sourceId),
							(int) point.getY()
									- sourceDescriptor.getMoteRadius(sourceId),
							4 * sourceDescriptor.getMoteRadius(sourceId),
							4 * sourceDescriptor.getMoteRadius(sourceId), null);
					g2.setPaint(new Color(Color.red.getRed(), Color.red
							.getGreen(), Color.red.getBlue(), 100));
				} else {
					g2.setPaint(sourceDescriptor.getColor(sourceId));
					Point point = mapPanel.toActualPoint(locations.get(i));
					point.x -= sourceDescriptor.getMoteRadius(sourceId);
					point.y -= sourceDescriptor.getMoteRadius(sourceId);
					g2.fill(new Ellipse2D.Double(point.getX(), point.getY(),
							2 * sourceDescriptor.getMoteRadius(sourceId),
							2 * sourceDescriptor.getMoteRadius(sourceId)));
					BasicStroke stroke = new BasicStroke(1.0f);
					g2.setStroke(stroke);
					if (sourceSelected != null && sourceSelected.equals(source))
						g2.setPaint(Color.black);
					else
						g2.setPaint(Color.white);
					g2.draw(new Ellipse2D.Double(point.getX(), point.getY(),
							2 * sourceDescriptor.getMoteRadius(sourceId),
							2 * sourceDescriptor.getMoteRadius(sourceId)));
				}
			}
		}
	}

	public Point getTextAnchor(SourceId sourceId) {
		return new Point(sourceDescriptor.getLocations(sourceId).get(0));
	}

	public boolean selectSource(SourceId sourceId, Point selection) {
		Source source = SourcesManager.getSource(sourceId);
		Vector<Point> locations = sourceDescriptor.getLocations(sourceId);
		for (int i = 0; i < locations.size(); i++) {
			if ((Math.abs(locations.get(i).x - selection.getX()) <= 2 * sourceDescriptor
					.getMoteRadius(sourceId))
					&& (Math.abs(locations.get(i).y - selection.getY()) <= 2 * sourceDescriptor
							.getMoteRadius(sourceId))) {
				sourceSelected = source;
				moving = new Vector<Boolean>();
				for (int j = 0; j < locations.size(); j++) {
					moving.add(new Boolean(false));
				}
				moving.set(i, new Boolean(true));
				return true;
			}
		}
		sourceSelected = null;
		moving = null;
		return false;
	}

	public void moveSelectedSource(Point location) {
		if (sourceSelected != null) {
			Vector<Point> locations = sourceDescriptor
					.getLocations(sourceSelected.identifier());
			for (int i = 0; i < locations.size(); i++) {
				if (moving.get(i)) {
					locations.set(i, location);
					sourceDescriptor.setLocations(sourceSelected.identifier(),
							locations);
					return;
				}
			}
		}
	}

	public void drawPath(SourceId sourceId, Graphics2D g2) {
		Source source = SourcesManager.getSource(sourceId);
		if (sourceDescriptor.getParent(sourceId).equals(sourceId)
				|| source.isSink())
			return;
		Source parent = SourcesManager.getSource(sourceDescriptor
				.getParent(sourceId));
		if (parent == null)
			return;
		SourceId parentId = parent.identifier();
		// if ((source.getLastTimeSeen().getTime() < System.currentTimeMillis()
		// - sourceDescriptor.getRefreshPeriod(sourceId))
		// || (!parent.isSink() && parent.getLastTimeSeen().getTime() < System
		// .currentTimeMillis()
		// - sourceDescriptor.getRefreshPeriod(sourceId))) {
		// // g2.setPaint(Color.RED);
		// return;
		// } else {
		g2.setPaint(sourceDescriptor.getColor(source.identifier()));
		// }

		BasicStroke stroke = new BasicStroke(2f);
		g2.setStroke(stroke);

		QuadCurve2D q = new QuadCurve2D.Float();
		Vector<Point> sourceLocations = sourceDescriptor.getLocations(sourceId);
		Vector<Point> parentLocations = sourceDescriptor.getLocations(parentId);
		for (int i = 0; i < sourceLocations.size(); i++) {
			Point sourceP = mapPanel.toActualPoint(sourceLocations.get(i));
			Point parentP = mapPanel.toActualPoint(parentLocations.get(i));
			float ctrlX = sourceP.x;
			float ctrlY = sourceP.y;
			if (sourceP.x - sourceP.y < parentP.x - parentP.y) {
				ctrlX = (float) (sourceP.x + (parentP.x - sourceP.x) * 0.65);
				ctrlY = (float) (parentP.y + (sourceP.y - parentP.y) * 0.65);
			} else {
				ctrlX = (float) (parentP.x + (sourceP.x - parentP.x) * 0.65);
				ctrlY = (float) (sourceP.y + (parentP.y - sourceP.y) * 0.65);
			}
			q
					.setCurve(sourceP.x, sourceP.y, ctrlX, ctrlY, parentP.x,
							parentP.y);
			g2.draw(q);
		}
	}

}
