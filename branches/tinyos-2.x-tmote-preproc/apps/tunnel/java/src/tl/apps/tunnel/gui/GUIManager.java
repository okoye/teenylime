/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 895 $
 * * DATE
 * *    $LastChangedDate: 2009-09-10 04:13:45 -0500 (Thu, 10 Sep 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUIManager.java 895 2009-09-10 09:13:45Z mceriotti $
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

package tl.apps.tunnel.gui;

import javax.swing.*;

import tl.apps.tunnel.Parent;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionSamplesMsgListener;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.gui.LegendPanel;
import tl.lib.dataCollection.gui.MapPanel;
import tl.lib.dataCollection.gui.SourceDrawer;
import tl.lib.dataCollection.gui.StatusPanel;
import tl.lib.dataCollection.gui._ChartPanel;

import java.awt.*;
import java.awt.event.*;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

public class GUIManager extends JFrame implements WindowListener,
		_CollectionSamplesMsgListener {
	private StatusPanel requestPanel;
	private MapPanel mapPanel;
	private Vector<_ChartPanel> charts;
	private LegendPanel legendPanel;
	private GUIScenarioTunnel scenario;
	private SourceDrawer sourceDrawer;
	private Timer repaintTimer;

	public GUIManager(GUIScenarioTunnel scenario) {
		super("GUI Interface");
		this.scenario = scenario;
		this.repaintTimer = new Timer("Paint Timer");
	}

	public void activate() {
		javax.swing.SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				createAndShowGUI();
			}
		});
	}

	public void deactivate() {
		System.out.println("Closing ...");
		this.dispose();
		System.exit(0);
	}

	private void createAndShowGUI() {
		requestPanel = new StatusPanel(scenario);
		mapPanel = new MapPanel(scenario, requestPanel);
		sourceDrawer = new SourceDrawer(scenario, mapPanel);
		mapPanel.setSourceDrawer(sourceDrawer);
		legendPanel = new LegendPanel(mapPanel);

		charts = scenario.getChartPanels();

		JTabbedPane rightTabbedPanel = new JTabbedPane();
		rightTabbedPanel.addTab("Requests", null, requestPanel,
				"Send requests over the network");
		rightTabbedPanel.addTab("Legend", null, legendPanel,
				"Choose how to display the network");
		JTabbedPane leftTabbedPanel = new JTabbedPane();
		leftTabbedPanel.addTab("Network Map", null, mapPanel,
				"Display a map of the network");
		for (int i = 0; i < charts.size(); i++) {
			leftTabbedPanel.addTab(charts.get(i).label(), null,
					(Component) charts.get(i), charts.get(i).description());
		}

		this.getContentPane().setLayout(new GridBagLayout());
		GridBagConstraints c = new GridBagConstraints();
		c.insets = new Insets(5, 5, 5, 5);
		c.fill = GridBagConstraints.BOTH;
		c.weighty = 1;
		c.weightx = 1;
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 1;
		c.gridheight = 1;
		c.anchor = GridBagConstraints.FIRST_LINE_START;
		this.getContentPane().add(leftTabbedPanel, c);
		// leftTabbedPanel.setPreferredSize(new Dimension(600, 500));

		c.fill = GridBagConstraints.VERTICAL;
		c.weighty = 1;
		c.weightx = 0;
		c.gridx = 1;
		c.gridy = 0;
		c.gridheight = 2;
		c.anchor = GridBagConstraints.LINE_END;
		this.getContentPane().add(rightTabbedPanel, c);
		// rightTabbedPanel.setPreferredSize(new Dimension(300, 500));

		// Display the window.
		try { // Set System L&F
			UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); // System
			// Theme
			// UIManager.setLookAndFeel(UIManager.
			// getCrossPlatformLookAndFeelClassName());
			// // Metal Theme
			// UIManager.setLookAndFeel(
			// "com.sun.java.swing.plaf.motif.MotifLookAndFeel");
		} catch (Exception e) {
			e.printStackTrace();
		}
		this.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
		SwingUtilities.updateComponentTreeUI(this);
		this.pack();
		this.setVisible(true);
		this.addWindowListener(this);
	}

	public void windowOpened(WindowEvent e) {
	}

	public void windowClosing(WindowEvent e) {
		System.out.println("Closing...");
		this.dispose();
		System.exit(0);
	}

	public void windowClosed(WindowEvent e) {
	}

	public void windowIconified(WindowEvent e) {
	}

	public void windowDeiconified(WindowEvent e) {
	}

	public void windowActivated(WindowEvent e) {
	}

	public void windowDeactivated(WindowEvent e) {
	}

	public void receivedSampleMsg(SourceId id,
			Hashtable<_CollectionFeature, Sample> sampleMsg) {
		if (mapPanel != null && mapPanel.isVisible()) {
			repaintTimer.cancel();
			repaintTimer = new Timer("Paint Timer");
			repaintTimer.schedule(new RepaintTask(), 100);
		}
		if (requestPanel != null && requestPanel.isVisible()) {
			requestPanel.sourceUpdatedEvent(id);
		}
	}

	private void paint() {
		this.repaint();
	}

	private class RepaintTask extends TimerTask {
		public void run() {
			paint();
		}
	}
}
