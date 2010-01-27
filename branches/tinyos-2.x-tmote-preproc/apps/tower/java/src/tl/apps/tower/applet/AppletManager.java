/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 996 $
 * * DATE
 * *    $LastChangedDate: 2009-12-07 16:10:32 -0600 (Mon, 07 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: AppletManager.java 996 2009-12-07 22:10:32Z mceriotti $
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

import javax.imageio.ImageIO;
import javax.swing.*;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;

import tl.common.serial.SerialComm;
import tl.lib.dataCollection.DataDispenser;
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
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.Socket;
import java.net.URL;
import java.util.Hashtable;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

public class AppletManager extends JApplet implements
		_CollectionSamplesMsgListener, MouseListener {
	private StatusPanel requestPanel;
	private MapPanel mapPanel;
	private Vector<_ChartPanel> charts;
	private LegendPanel legendPanel;
	private SourceDrawer sourceDrawer;
	private Timer repaintTimer;

	private JLabel group;
	private JLabel toWebPage;

	private SerialComm serial;
	private DataDispenser manager;
	private AppletScenarioTower scenario;
	private boolean connection_ok;

	public void init() {
		String host = "tikisola.disi.unitn.it";
		int port = 9001;
		String remote_port = "sf@" + host + ":" + port;
		connection_ok = false;

		try {
			Socket socket;
			socket = new Socket(host, port);
			socket.close();
		} catch (Exception e) {
			getContentPane().setBackground(Color.WHITE);
			JOptionPane.showMessageDialog(null,
					"Impossible to connect to tikisola.disi.unitn.it:9001",
					"Connection Error", JOptionPane.ERROR_MESSAGE);
			return;
		}

		PhoenixSource phoenix = BuildSource.makePhoenix(remote_port, null);
		
		Vector<MoteIF> nodes = new Vector<MoteIF>();
		nodes.add(new MoteIF(phoenix));
		serial = new SerialComm(nodes);

		scenario = new AppletScenarioTower(this);

		manager = new DataDispenser(scenario);
		serial.addListener(manager);
		scenario.setSerial(serial);
		serial.activate();
		manager.activate();
		scenario.start();

		connection_ok = true;

		javax.swing.SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				createAndShowGUI();
			}
		});
	}

	private void createAndShowGUI() {

		repaintTimer = new Timer("Paint Timer");
		requestPanel = new StatusPanel(scenario);
		mapPanel = new MapPanel(scenario, requestPanel);
		sourceDrawer = new SourceDrawer(scenario, mapPanel);
		mapPanel.setSourceDrawer(sourceDrawer);
		legendPanel = new LegendPanel(mapPanel);

		charts = scenario.getChartPanels();

		JTabbedPane rightTabbedPanel = new JTabbedPane();
		rightTabbedPanel.addTab("Status", null, requestPanel,
				"Control the status of the nodes");
		rightTabbedPanel.addTab("Legend", null, legendPanel,
				"Choose how to display the network");
		JTabbedPane leftTabbedPanel = new JTabbedPane();
		leftTabbedPanel.addTab("Network Map", null, mapPanel,
				"Display a map of the network");
		for (int i = 0; i < charts.size(); i++) {
			leftTabbedPanel.addTab(charts.get(i).label(), null,
					(Component) charts.get(i), charts.get(i).description());
		}

		// Image logo = null;
		//
		// try {
		// ClassLoader cl = this.getClass().getClassLoader();
		// logo = ImageIO.read(cl
		// .getResource("tl/apps/tower/applet/images/logo.jpg"));
		// } catch (IOException e) {
		// e.printStackTrace();
		// }
		
		toWebPage = new JLabel("<html><u><a href=\"http://d3s.disi.unitn.it\">http://d3s.disi.unitn.it</a></u><html>", JLabel.CENTER);
		toWebPage.setVerticalTextPosition(AbstractButton.CENTER);
		toWebPage.setHorizontalTextPosition(AbstractButton.CENTER);
		toWebPage.setEnabled(true);

		group = new JLabel("D3S Research Group", JLabel.CENTER);
		// group.setIcon(new ImageIcon(logo));
		group.setVerticalTextPosition(AbstractButton.CENTER);
		group.setHorizontalTextPosition(AbstractButton.CENTER);
		group.setEnabled(true);
		
		GridBagConstraints c = new GridBagConstraints();

		JPanel advert = new JPanel(new GridBagLayout());
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.insets = new Insets(2, 2, 2, 2);
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 1;
		advert.add(group, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 1;
		advert.add(toWebPage, c);
		advert.setBorder(BorderFactory.createTitledBorder("Developed by"));
		advert.addMouseListener(this);
		
		getContentPane().setLayout(new GridBagLayout());
		
		c = new GridBagConstraints();
		c.insets = new Insets(5, 5, 5, 5);
		c.fill = GridBagConstraints.BOTH;
		c.weighty = 1;
		c.weightx = 1;
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 1;
		c.gridheight = 2;
		c.anchor = GridBagConstraints.FIRST_LINE_START;
		getContentPane().add(leftTabbedPanel, c);

		c.weighty = 1;
		c.weightx = 0;
		c.gridx = 1;
		c.gridy = 0;
		c.gridheight = 1;
		c.gridwidth = 1;
		getContentPane().add(rightTabbedPanel, c);
		c.weighty = 0;
		c.weightx = 0;
		c.gridx = 1;
		c.gridy = 1;
		c.gridheight = 1;
		c.gridwidth = 1;
		getContentPane().add(advert, c);

		getContentPane().setBackground(Color.WHITE);
		try { // Set System L&F
			UIManager.setLookAndFeel(UIManager
					.getCrossPlatformLookAndFeelClassName());
		} catch (Exception e) {
			e.printStackTrace();
		}
		SwingUtilities.updateComponentTreeUI(this);
	}

	public void destroy() {
		if (connection_ok) {
			serial.deactivate();
			manager.deactivate();
			scenario.stop();
		}
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

	public void mouseClicked(MouseEvent e) {
		try {
			this.getAppletContext().showDocument(
					new URL("http://d3s.disi.unitn.it/"), "_blank");
		} catch (MalformedURLException e1) {
		}
	}

	public void mouseEntered(MouseEvent e) {
	}

	public void mouseExited(MouseEvent e) {
	}

	public void mousePressed(MouseEvent e) {
	}

	public void mouseReleased(MouseEvent e) {
	}
}
