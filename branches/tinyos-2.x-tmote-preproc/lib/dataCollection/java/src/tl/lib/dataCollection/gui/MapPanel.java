/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 720 $
 * * DATE
 * *    $LastChangedDate: 2008-12-18 05:15:40 -0600 (Thu, 18 Dec 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: MapPanel.java 720 2008-12-18 11:15:40Z mceriotti $
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

import javax.imageio.ImageIO;
import javax.swing.*;

import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.lang.Math;
import java.util.Vector;

/*
 * This class is used to display a map of the network for the user. The gateway
 * appears in red, and the regular motes in blue.
 */

public class MapPanel extends JPanel implements MouseListener,
		MouseMotionListener {
	private StatusPanel requestPanel;

	private String moteLegend, parentIdLegend, moteIdLegend, countLegend,
			routeLegend, pathCostLegend, lostLegend;

	private boolean moteDragged = false;
	private SourceId moteMoving = null;

	private _CollectionGUIScenario scenario;

	private BufferedImage backgroundImage;

	private double scaleX, scaleY;
	
	private static final int X_MAX = 1000;
	private static final int Y_MAX = 1000;
	
	private SourceDrawer sourceDrawer;
	private _CollectionGUISourceDescriptor sourceDescriptor;

	public MapPanel(_CollectionGUIScenario scenario, StatusPanel requestPanel) {
		this.requestPanel = requestPanel;
		this.scenario = scenario;
		this.sourceDescriptor = scenario.getSourceDescriptor();
		// The Strings are initialized at "none" for most of them
		moteLegend = "circle";
		moteIdLegend = "text";
		lostLegend = "none";
		countLegend = "none";
		pathCostLegend = "none";
		parentIdLegend = "none";
		routeLegend = "line";
		scaleX = 1;
		scaleY = 1;
		addMouseListener(this);
		addMouseMotionListener(this);
		backgroundImage = scenario.getBackgroundImage();
		if (backgroundImage == null) {
			try {
				ClassLoader cl = this.getClass().getClassLoader();
				backgroundImage = ImageIO
						.read(cl
								.getResource("tl/lib/dataCollection/gui/images/default.jpg"));
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	public void setSourceDrawer(SourceDrawer sourceDrawer) {
		this.sourceDrawer = sourceDrawer;
	}

	public void paint(Graphics g) {
		Graphics2D g2 = (Graphics2D) g;
		// we draw first a white area with a border
		Dimension d = getSize();
		g2.setPaint(Color.black);
		g2.fill(new Rectangle2D.Double(0, 0, d.width, d.height));
		g2.setPaint(Color.white);
		g2.fill(new Rectangle2D.Double(sourceDescriptor.getMoteRadius(null),
				sourceDescriptor.getMoteRadius(null), d.width - 2
						* sourceDescriptor.getMoteRadius(null), d.height - 2
						* sourceDescriptor.getMoteRadius(null)));
		if (!"none".equals(scenario)) {
			scaleX = (d.width - 2 * sourceDescriptor.getMoteRadius(null))
					/ (double) backgroundImage.getWidth(null);
			scaleY = (d.height - 2 * sourceDescriptor.getMoteRadius(null))
					/ (double) backgroundImage.getHeight(null);
			if (scaleX < scaleY) {
				scaleY = scaleX;
			} else {
				scaleX = scaleY;
			}
			// AffineTransform xform = AffineTransform.getScaleInstance(scaleX,
			// scaleY);
			// g2.drawImage(backgroundImage, xform, this);

			g2.drawImage(backgroundImage, sourceDescriptor.getMoteRadius(null),
					sourceDescriptor.getMoteRadius(null), (int) Math
							.round(backgroundImage.getWidth(null) * scaleX),
					(int) Math.round(backgroundImage.getHeight(null) * scaleY),
					this);

		}
		_CollectionGUISourceDescriptor sourceDescriptor;
		Source source;
		Vector<SourceId> sourcesId = SourcesManager.getAllSourcesId();

		// we run through the available legends, to know which one is selected
		// and we launch the corresponding functions

		if ("line".equals(routeLegend)) {
			for (int i = 0; i < sourcesId.size(); i++) {
				sourceDescriptor = (_CollectionGUISourceDescriptor) scenario
						.getSourceDescriptor();
				if (!sourceDescriptor.getParent(sourcesId.get(i)).equals(
						sourcesId.get(i))) {
					drawParentRoute(sourcesId.get(i), g2);
				}
			}
		}

		if ("circle".equals(moteLegend)) {
			for (int i = 0; i < sourcesId.size(); i++) {
				sourceDrawer.drawSource(sourcesId.get(i), g2);
			}
		}

		// If the mote is displayed and one of the text legend is choosen
		if ("circle".equals(moteLegend)
				&& ("text".equals(parentIdLegend)
						|| "text".equals(moteIdLegend) || "text"
						.equals(countLegend)) || "text".equals(pathCostLegend)) {
			// then we run through the database
			for (int i = 0; i < sourcesId.size(); i++) {
				source = SourcesManager.getSource(sourcesId.get(i));
				sourceDescriptor = (_CollectionGUISourceDescriptor) scenario
						.getSourceDescriptor();
				String str = "";
				Vector<String> msg = new Vector<String>();
				if ("text".equals(moteIdLegend)) {
					str = "Id = " + sourcesId.get(i).toString() + "\n";
//					str += sourceDescriptor.getLocations(sourcesId.get(i)).get(
//							0).x
//							+ " "
//							+ sourceDescriptor.getLocations(sourcesId.get(i))
//									.get(0).y
//							+ " "
//							+ sourceDescriptor.getLocations(sourcesId.get(i))
//									.get(1).x
//							+ " "
//							+ sourceDescriptor.getLocations(sourcesId.get(i))
//									.get(1).y + "\n";
					msg.add(str);

				}
				if ("text".equals(parentIdLegend) && !source.isSink()) {
					str = "Parent Id = "
							+ sourceDescriptor.getParent(sourcesId.get(i))
							+ "\n";
					msg.add(str);
				}
				if ("text".equals(pathCostLegend) && !source.isSink()) {
					str = "Path Cost = "
							+ sourceDescriptor.getPathCost(sourcesId.get(i))
							+ "\n";
					msg.add(str);
				}
				if ("text".equals(countLegend) && !source.isSink()) {
					str = "Collected = " + source.numberOfCollectedSamples()
							+ "\n";
					msg.add(str);
				}
				if ("text".equals(lostLegend) && !source.isSink()) {
					str = "Lost = " + source.numberOfLostSamples() + "\n";
					msg.add(str);
				}
				String[] array = new String[msg.size()];
				for (int j = 0; j < msg.size(); j++)
					array[j] = msg.get(j);
				drawSourceText(toActualPoint(sourceDrawer
						.getTextAnchor(sourcesId.get(i))), array, g2);
			}
		}
	}

	/*
	 * This functions are called by legendPanel and store the value selected by
	 * the user.
	 */

	public void setMoteLegend(String s) {
		moteLegend = s;
	}

	public void setMoteIdLegend(String s) {
		moteIdLegend = s;
	}

	public void setParentIdLegend(String s) {
		parentIdLegend = s;
	}

	public void setCountLegend(String s) {
		countLegend = s;
	}

	public void setLostLegend(String s) {
		lostLegend = s;
	}

	public void setPathCostLegend(String s) {
		pathCostLegend = s;
	}

	public void setRouteLegend(String s) {
		routeLegend = s;
	}

	/*
	 * This function draws some text near of a mote. It takes in parameter a
	 * string representing the text to print. The character "\n" means a new
	 * line. Mote.getX() gives the center of the mote, so we have to get the top
	 * left corner for the functions fill and draw
	 */

	private void drawSourceText(Point textAnchor, String[] text, Graphics2D g2) {
		if (textAnchor != null && text.length > 0) {
			Font font = new Font("Serif", Font.PLAIN, 12);
			FontMetrics metric = g2.getFontMetrics();
			int width = 0;
			for (int i = 0; i < text.length; i++) {
				if (metric.stringWidth(text[i]) > width)
					width = metric.stringWidth(text[i]);
			}
			g2.setPaint(new Color(Color.WHITE.getRed(), Color.WHITE.getGreen(),
					Color.WHITE.getBlue(), 120));
			g2.fill(new Rectangle2D.Double((int) textAnchor.getX() + 2
					* sourceDescriptor.getMoteRadius(null), (int) textAnchor
					.getY(), width, font.getSize() * text.length
					+ metric.getDescent()));
			g2.setPaint(Color.black);
			BasicStroke stroke = new BasicStroke(1.0f);
			g2.setStroke(stroke);
			g2.setFont(font);
			for (int i = 0; i < text.length; i++) {
				g2.drawString(text[i], (int) textAnchor.getX() + 2
						* sourceDescriptor.getMoteRadius(null),
						(int) textAnchor.getY() + font.getSize() * (i + 1));
			}
		}
	}

	/*
	 * This function draws a route from the mote to its parent if it exists, and
	 * deals with the quality and lastTimeSeen variables.
	 */

	private void drawParentRoute(SourceId source, Graphics2D g2) {
		sourceDrawer.drawPath(source, g2);
	}

	/*
	 * These both functions translate the x and y values of the mote to values
	 * for the screen.
	 */

	private int toVirtualX(int x) {
		// Dimension d = getSize();
		// int tmp = d.width * x / Util.X_MAX;
		int width = (int) (backgroundImage.getWidth(null) * scaleX);
		int tmp = (x * width) / X_MAX;
		if (tmp < sourceDescriptor.getMoteRadius(null)) // we prevent x to
			// go past the panel
			return sourceDescriptor.getMoteRadius(null);
		else if (tmp > width - sourceDescriptor.getMoteRadius(null))
			return width - sourceDescriptor.getMoteRadius(null);
		else
			return tmp;
	}

	private int toVirtualY(int y) {
		// Dimension d = getSize();
		// int tmp = d.height * y / Util.Y_MAX;
		int height = (int) (backgroundImage.getHeight(null) * scaleY);
		int tmp = (y * height) / Y_MAX;
		if (tmp < sourceDescriptor.getMoteRadius(null)) // we prevent y to
			// go past the panel
			return sourceDescriptor.getMoteRadius(null);
		else if (tmp > height - sourceDescriptor.getMoteRadius(null))
			return height - sourceDescriptor.getMoteRadius(null);
		else
			return tmp;
	}

	/*
	 * These both functions translate the x and y values of the screen to real
	 * values for the mote.
	 */

	private int toRealX(int x) {
		// Dimension d = getSize();
		int width = (int) (backgroundImage.getWidth(null) * scaleX);
		if (x < sourceDescriptor.getMoteRadius(null))
			x = sourceDescriptor.getMoteRadius(null);
		else if (x > width - sourceDescriptor.getMoteRadius(null))
			x = width - sourceDescriptor.getMoteRadius(null);
		return  X_MAX * x / width;
	}

	private int toRealY(int y) {
		// Dimension d = getSize();
		int height = (int) (backgroundImage.getHeight(null) * scaleY);
		if (y < sourceDescriptor.getMoteRadius(null))
			y = sourceDescriptor.getMoteRadius(null);
		else if (y > height - sourceDescriptor.getMoteRadius(null))
			y = height - sourceDescriptor.getMoteRadius(null);
		return Y_MAX * y / height;
	}

	public void mouseEntered(MouseEvent e) {
	}

	public void mouseExited(MouseEvent e) {
	}

	/*
	 * Function called when a user clicks in the JPanel, either he clicks one or
	 * more time. We check if a mote is in this area and if so, this mote
	 * becomes selected. Else all the motes of the database are unselected. The
	 * control key lets the user select many motes in the same time.
	 */

	public void mouseClicked(MouseEvent e) {
		SourceId localSource = null;
		Point selection = toRealPoint(e.getPoint());
		boolean moteClicked = false;
		Vector<SourceId> sourcesId = SourcesManager.getAllSourcesId();
		for (int i = 0; i < sourcesId.size(); i++) {
			localSource = sourcesId.get(i);
			if (sourceDrawer.selectSource(sourcesId.get(i), selection)) {
				localSource = sourcesId.get(i);
				moteClicked = true;
				break;
			}
		}
		if (localSource != null) {
			if (moteClicked) {
				if (!e.isControlDown())
					requestPanel.unselectSources();
				requestPanel.selectSource(localSource);
				// Util.debug("clik on mote id = "+localMote.getMoteId());
			} else
				requestPanel.unselectSources();
		} else
			requestPanel.unselectSources();
		repaint();
	}

	public void mouseMoved(MouseEvent e) {
	}

	/*
	 * These three functions are used to move a mote. moteMoving is a Mote
	 * Object, it's the mote that is dragged by the user, through the mouse.
	 * moteDragged is a flag to know if the user is still moving the mote.
	 */

	public void mousePressed(MouseEvent e) {
	}

	public void mouseReleased(MouseEvent e) {
		moteDragged = false;
		moteMoving = null;
	}

	public void mouseDragged(MouseEvent e) {
		SourceId localSource = null;
		Point location = toRealPoint(e.getPoint());
		if (!moteDragged) {
			Vector<SourceId> sourcesId = SourcesManager.getAllSourcesId();
			for (int i = 0; i < sourcesId.size(); i++) {
				localSource = sourcesId.get(i);
				if (sourceDrawer.selectSource(localSource, location)) {
					moteMoving = localSource;
					moteDragged = true;
					break;
				}
			}
		}
		if (moteMoving != null) {
			if (moteDragged) {
				sourceDrawer.moveSelectedSource(location);
			} else
				requestPanel.unselectSources();
			repaint();
		}
	}

	public Point toActualPoint(Point point) {
		return new Point(toVirtualX(point.x), toVirtualY(point.y));
	}

	public Point toRealPoint(Point point) {
		return new Point(toRealX(point.x), toRealY(point.y));
	}
}
