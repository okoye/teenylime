/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 684 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:07:49 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: LegendPanel.java 684 2008-10-01 10:07:49Z mceriotti $
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
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;

public class LegendPanel extends JPanel implements ActionListener, ChangeListener,
		ItemListener {
	private MapPanel mapPanel;

	public LegendChooserPanel moteChooser, moteIdChooser, lostChooser,
			parentIdChooser, countChooser, pathCostChooser, routeChooser;

	public LegendPanel(MapPanel mapPanel) {
		super(new GridBagLayout());

		String[] list2 = new String[2];
		list2[0] = "none";
		list2[1] = "circle";
		moteChooser = new LegendChooserPanel("Mote : ", list2);
		list2[0] = "text";
		list2[1] = "none";
		moteIdChooser = new LegendChooserPanel("Mote Id : ", list2);
		list2[0] = "none";
		list2[1] = "text";
		countChooser = new LegendChooserPanel("Collected : ", list2);
		lostChooser = new LegendChooserPanel("Lost : ", list2);
		pathCostChooser = new LegendChooserPanel("Path Cost : ", list2);
		parentIdChooser = new LegendChooserPanel("Parent Id : ", list2);
		list2[0] = "none";
		list2[1] = "line";
		routeChooser = new LegendChooserPanel("Route : ", list2);

		moteChooser.addActionListener(this);
		moteIdChooser.addActionListener(this);
		lostChooser.addActionListener(this);
		parentIdChooser.addActionListener(this);
		countChooser.addActionListener(this);
		pathCostChooser.addActionListener(this);
		routeChooser.addActionListener(this);

		// layout
		GridBagConstraints c = new GridBagConstraints();
		c.insets = new Insets(2, 10, 2, 10);
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.FIRST_LINE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.gridy = 0;
		add(moteChooser, c);
		c.gridy = 1;
		add(moteIdChooser, c);
		c.gridy = 2;
		add(parentIdChooser, c);
		c.gridy = 3;
		add(countChooser, c);
		c.gridy = 4;
		add(lostChooser, c);
		c.gridy = 5;
		add(pathCostChooser, c);
		c.gridy = 6;
		add(routeChooser, c);

		this.mapPanel = mapPanel;
		moteChooser.setSelectedIndex(1);
		routeChooser.setSelectedIndex(1);
	}

	/*
	 * Function called when a checkBox is selected or unselected
	 */

	public void itemStateChanged(ItemEvent e) {

	}

	public void actionPerformed(ActionEvent e) {
		JComboBox comboBox = (JComboBox) e.getSource();
		if (comboBox == moteChooser.comboBox)
			mapPanel.setMoteLegend((String) comboBox.getSelectedItem());
		else if (comboBox == moteIdChooser.comboBox)
			mapPanel.setMoteIdLegend((String) comboBox.getSelectedItem());
		if (comboBox == parentIdChooser.comboBox)
			mapPanel.setParentIdLegend((String) comboBox.getSelectedItem());
		else if (comboBox == countChooser.comboBox)
			mapPanel.setCountLegend((String) comboBox.getSelectedItem());
		else if (comboBox == lostChooser.comboBox)
			mapPanel.setLostLegend((String) comboBox.getSelectedItem());
		else if (comboBox == pathCostChooser.comboBox)
			mapPanel.setPathCostLegend((String) comboBox.getSelectedItem());
		else if (comboBox == routeChooser.comboBox)
			mapPanel.setRouteLegend((String) comboBox.getSelectedItem());
		mapPanel.repaint();
	}

	/*
	 * Function called when a slider is moved.
	 */

	public void stateChanged(ChangeEvent e) {

	}

}

class LegendChooserPanel extends JPanel {
	private JLabel title;
	public JComboBox comboBox;

	public LegendChooserPanel(String title, String[] list) {
		super(new GridLayout(1, 2));
		this.title = new JLabel(title);
		comboBox = new JComboBox(list);
		comboBox.setSelectedIndex(0);
		add(this.title);
		add(this.comboBox);
	}

	public void addActionListener(ActionListener a) {
		comboBox.addActionListener(a);
	}

	public void setSelectedIndex(int i) {
		comboBox.setSelectedIndex(i);
	}

	public String getSelectedItem() {
		return (String) comboBox.getSelectedItem();
	}
}