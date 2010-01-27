/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 757 $
 * * DATE
 * *    $LastChangedDate: 2009-03-28 07:25:35 -0500 (Sat, 28 Mar 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: StatusPanel.java 757 2009-03-28 12:25:35Z mceriotti $
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

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.BorderFactory;

import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.Vector;

public class StatusPanel extends JPanel implements ActionListener {
	private JLabel moteLabel;
	private JTextArea sourceState;

	private JButton toChartButton, allToChartButton, removeAllChartButton,
			removeChartButton;
	private _CollectionGUIScenario scenario;
	private LinkedList<SourceId> selectedMotesList;

	public StatusPanel(_CollectionGUIScenario scenario) {
		super(new GridBagLayout());
		GridBagConstraints c = new GridBagConstraints();

		this.scenario = scenario;

		// Sensor
		moteLabel = new JLabel("No mote selected");
		sourceState = new JTextArea();
		sourceState.setEditable(false);
		sourceState.setEnabled(false);
		sourceState.setWrapStyleWord(true);
		sourceState.setLineWrap(true);
		sourceState.setOpaque(false);
		sourceState.setDisabledTextColor(Color.BLACK);

		// sensor layout
		JPanel tmpSensorPanel = new JPanel(new GridBagLayout());
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.insets = new Insets(2, 2, 2, 2);
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 2;
		tmpSensorPanel.add(moteLabel, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 10;
		tmpSensorPanel.add(sourceState, c);
		tmpSensorPanel.setBorder(BorderFactory.createTitledBorder("Sensor"));

		// Chart
		toChartButton = new JButton("Add Selected");
		toChartButton.setActionCommand("add");
		toChartButton.setVerticalTextPosition(AbstractButton.CENTER);
		toChartButton.setHorizontalTextPosition(AbstractButton.LEADING);
		toChartButton.setEnabled(true);
		toChartButton.addActionListener(this);
		allToChartButton = new JButton("Add All");
		allToChartButton.setActionCommand("addall");
		allToChartButton.setVerticalTextPosition(AbstractButton.CENTER);
		allToChartButton.setHorizontalTextPosition(AbstractButton.LEADING);
		allToChartButton.setEnabled(true);
		allToChartButton.addActionListener(this);
		removeChartButton = new JButton("Remove Selected");
		removeChartButton.setActionCommand("remove");
		removeChartButton.setVerticalTextPosition(AbstractButton.CENTER);
		removeChartButton.setHorizontalTextPosition(AbstractButton.LEADING);
		removeChartButton.setEnabled(true);
		removeChartButton.addActionListener(this);
		removeAllChartButton = new JButton("Remove All");
		removeAllChartButton.setActionCommand("removeall");
		removeAllChartButton.setVerticalTextPosition(AbstractButton.CENTER);
		removeAllChartButton.setHorizontalTextPosition(AbstractButton.LEADING);
		removeAllChartButton.setEnabled(true);
		removeAllChartButton.addActionListener(this);

		// chart layout
		JPanel tmpChartPanel = new JPanel(new GridBagLayout());
		c = new GridBagConstraints();
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.insets = new Insets(2, 2, 2, 2);
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 1;
		tmpChartPanel.add(toChartButton, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 1;
		tmpChartPanel.add(allToChartButton, c);
		c.gridx = 0;
		c.gridy = 2;
		c.gridwidth = 1;
		tmpChartPanel.add(removeChartButton, c);
		c.gridx = 0;
		c.gridy = 3;
		c.gridwidth = 1;
		tmpChartPanel.add(removeAllChartButton, c);
		tmpChartPanel.setBorder(BorderFactory
				.createTitledBorder("Motes displayed in charts"));

		// layout
		c = new GridBagConstraints();
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 3;
		add(tmpSensorPanel, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 3;
		add(tmpChartPanel, c);
		// network
		selectedMotesList = new LinkedList<SourceId>();

		displaySourceState();
	}

	/*
	 * Function called when a button is pressed. We don't have any
	 * acknowledgement so we have to assume the request is well executed, so we
	 * have to update the database.
	 */

	public void actionPerformed(ActionEvent e) {
		SourceId localSourceId;
		if ("add".equals(e.getActionCommand())) {
			// the list of motes selected by requestPanel is added to the
			// chartPanel
			for (Iterator<SourceId> it = selectedMotesList.listIterator(0); it
					.hasNext();) {
				localSourceId = (SourceId) it.next();
				Vector<_ChartPanel> charts = scenario.getChartPanels();
				for (int i = 0; i < charts.size(); i++) {
					charts.get(i).addSource(localSourceId);
				}
			}
		} else if ("addall".equals(e.getActionCommand())) {
			// all the motes are added to the chartPanel
			Vector<SourceId> sourcesId = SourcesManager.getAllSourcesId();
			for (int i = 0; i < sourcesId.size(); i++) {
				localSourceId = sourcesId.get(i);
				Vector<_ChartPanel> charts = scenario.getChartPanels();
				for (int j = 0; j < charts.size(); j++) {
					charts.get(j).addSource(localSourceId);
				}
			}
		} else if ("remove".equals(e.getActionCommand())) {
			// the list of motes selected by requestPanel is removed from the
			// chartPanel
			for (Iterator<SourceId> it = selectedMotesList.listIterator(0); it
					.hasNext();) {
				localSourceId = (SourceId) it.next();
				Vector<_ChartPanel> charts = scenario.getChartPanels();
				for (int i = 0; i < charts.size(); i++) {
					charts.get(i).deleteSource(localSourceId);
				}
			}
		} else if ("removeall".equals(e.getActionCommand())) {
			// all the motes are removed from the chartPanel
			Vector<_ChartPanel> charts = scenario.getChartPanels();
			for (int i = 0; i < charts.size(); i++) {
				charts.get(i).deleteSources();
			}
		}

	}

	/*
	 * Function used to display the state of the current mote selected. If the
	 * checkbox for broadcast is checked, all the buttons are enabled. If more
	 * than one mote is selected, all the buttons are enabled.
	 */

	public void displaySourceState() {
		if (selectedMotesList.size() > 1) {
			moteLabel.setText("Many Motes selected");
		} else {
			if (selectedMotesList.size() == 1)
				displaySourceState(selectedMotesList.getFirst(), scenario
						.getSourceDescriptor());
			else
				displaySourceState(null, null);
		}
	}

	/*
	 * Function used to display the state of the current mote selected. If mote
	 * equals null, the buttons are disabled.
	 */

	public void displaySourceState(SourceId sourceId,
			_CollectionGUISourceDescriptor sourceDescriptor) {
		if (sourceDescriptor != null) {
			moteLabel.setText("Mote " + sourceId.toString() + " selected");
			sourceState.setText(sourceDescriptor
					.getMultiLineDescription(sourceId));
		} else {
			moteLabel.setText("No specific mote selected");
			sourceState.setText("");
		}
	}

	/*
	 * The functions below are used to add or remove a mote to the list of
	 * selected motes.
	 */

	public void selectSource(SourceId sourceId) {
		if (sourceId != null)
			selectedMotesList.add(sourceId);
		displaySourceState();
	}

	public void unselectSource(SourceId sourceId) {
		if (sourceId != null)
			selectedMotesList.remove(sourceId);
		displaySourceState();
	}

	public void unselectSources() {
		selectedMotesList.clear();
		displaySourceState();
	}

	public boolean sourceIsSelected(SourceId sourceId) {
		if (sourceId != null)
			return selectedMotesList.contains(sourceId);
		else
			return false;
	}

	public Iterator<SourceId> getSelectedMotesListIterator() {
		return selectedMotesList.listIterator(0);
	}

	public int getNumberOfSelectedMotes() {
		return selectedMotesList.size();
	}

	/*
	 * Function called by any process or thread which has updated a mote. The
	 * RequestPanel checks if the mote was displayed and if so, its parameters
	 * are updated.
	 */

	public void sourceUpdatedEvent(SourceId sourceId) {
		if (sourceIsSelected(sourceId))
			displaySourceState();
	}
}
