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
 * *	$Id: TaskPanel.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office.gui;

import javax.swing.*;

import java.awt.*;
import java.awt.event.*;
import javax.swing.BorderFactory;

import tl.apps.office.Constants;
import tl.apps.office.Properties;
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.gui._GUIDisseminator;

class TaskPanel extends _GUIDisseminator {

	private JLabel label_p, label_r, label_t;
	private JTextField r, t;
	private JList sensor_list;
	private JButton taskButton;
	private SerialComm serial;

	public TaskPanel() {
		super();
		GridBagConstraints c = new GridBagConstraints();

		// task
		JPanel taskPanel = new JPanel(new GridBagLayout());
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.insets = new Insets(2, 2, 2, 2);
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 2;
		label_p = new JLabel("Type of Sensor");
		taskPanel.add(label_p, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 2;
		sensor_list = new JList(
				new String[] { "ACCELERATION", "BUZZER", "CO", "CO2", "DUST",
						"HUMIDITY", "MAGNETIC", "MICROPHONE", "PRESENCE",
						"PRESSURE", "SOLAR_LIGHT", "SYNTH_LIGHT",
						"TEMPERATURE", "TILT" });
		sensor_list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		sensor_list.setLayoutOrientation(JList.VERTICAL);
		sensor_list.setVisibleRowCount(10);
		sensor_list.setSelectedValue("TEMPERATURE", true);
		taskPanel.add(sensor_list, c);
		c.gridx = 0;
		c.gridy = 2;
		c.gridwidth = 2;
		label_r = new JLabel("Reporting Period in SECONDS (= "
				+ Constants.SECOND + " ms)/Buzzing Frequency in Hz");
		taskPanel.add(label_r, c);
		c.gridx = 0;
		c.gridy = 3;
		c.gridwidth = 2;
		r = new JTextField();
		taskPanel.add(r, c);
		c.gridx = 0;
		c.gridy = 4;
		c.gridwidth = 2;
		label_t = new JLabel("# of Reporting Periods, -1 for infinite");
		taskPanel.add(label_t, c);
		c.gridx = 0;
		c.gridy = 5;
		c.gridwidth = 2;
		t = new JTextField();
		taskPanel.add(t, c);
		c.gridx = 0;
		c.gridy = 6;
		c.gridwidth = 2;
		taskButton = new JButton("Submit task");
		taskButton.setActionCommand("submit_dt_task");
		taskButton.setVerticalTextPosition(AbstractButton.CENTER);
		taskButton.setHorizontalTextPosition(AbstractButton.LEADING);
		taskButton.setEnabled(true);
		taskButton.addActionListener(this);
		taskPanel.add(taskButton, c);
		taskPanel.setBorder(BorderFactory
				.createTitledBorder("Deformation/Temperature"));

		// layout
		c = new GridBagConstraints();
		c.weighty = 1;
		c.weightx = 1;
		c.anchor = GridBagConstraints.PAGE_START;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.gridx = 0;
		c.gridy = 0;
		c.gridwidth = 3;
		add(taskPanel, c);
	}

	/*
	 * Function called when a button is pressed. We don't have any
	 * acknowledgement so we have to assume the request is well executed, so we
	 * have to update the database.
	 */

	public void actionPerformed(ActionEvent e) {
		if ("submit_dt_task".equals(e.getActionCommand())) {
			int value_r, value_t;
			Tuple envelope = new Tuple();
			try {
				value_r = Integer.parseInt(r.getText());
				value_t = Integer.parseInt(t.getText());
				if (value_t == -1)
					value_t = Constants.INFINITE_OP_TIME;
				r.setText("");
				t.setText("");
				Tuple content = new Tuple();
				content.add(new Field().actualField(new Uint8(
						Constants.TASK_TYPE)));
				String p = (String) sensor_list.getSelectedValue();
				sensor_list.setSelectedValue("TEMPERATURE", true);
				Uint8 type = null;
				if (p.compareTo("ACCELERATION") == 0)
					type = new Uint8(Constants.ACCELERATION);
				else if (p.compareTo("BUZZER") == 0)
					type = new Uint8(Constants.BUZZER);
				else if (p.compareTo("CO") == 0)
					type = new Uint8(Constants.CO);
				else if (p.compareTo("CO2") == 0)
					type = new Uint8(Constants.CO2);
				else if (p.compareTo("DUST") == 0)
					type = new Uint8(Constants.DUST);
				else if (p.compareTo("HUMIDITY") == 0)
					type = new Uint8(Constants.HUMIDITY);
				else if (p.compareTo("MAGNETIC") == 0)
					type = new Uint8(Constants.MAGNETIC);
				else if (p.compareTo("MICROPHONE") == 0)
					type = new Uint8(Constants.MICROPHONE);
				else if (p.compareTo("PRESENCE") == 0)
					type = new Uint8(Constants.PRESENCE);
				else if (p.compareTo("PRESSURE") == 0)
					type = new Uint8(Constants.PRESSURE);
				else if (p.compareTo("SOLAR_LIGHT") == 0)
					type = new Uint8(Constants.SOLAR_LIGHT);
				else if (p.compareTo("SYNTH_LIGHT") == 0)
					type = new Uint8(Constants.SYNTH_LIGHT);
				else if (p.compareTo("TEMPERATURE") == 0)
					type = new Uint8(Constants.TEMPERATURE);
				else if (p.compareTo("TILT") == 0)
					type = new Uint8(Constants.TILT);
				else
					return;
				content.add(new Field().actualField(type));
				content.add(new Field().actualField(new Uint16(value_r)));
				content.add(new Field().actualField(new Uint16(value_t)));
				envelope.add(new Field().actualField(new Uint8(
						Constants.DISSEMINATION_TYPE)));
				envelope.add(new Field().actualField(new Uint16(
						Constants.DISSEMINATE_A_NEW_TUPLE)));
				envelope.add(new Field()
						.actualField(new Uint16(type.getValue())));
				envelope.add(new Field().actualField(new Uint8Array(
						Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
						.toSerial(content))));
			} catch (NumberFormatException err) {
				JOptionPane.showMessageDialog(this, "Invalid value inserted.",
						"Error", JOptionPane.ERROR_MESSAGE);
				return;
			}
			if (serial != null)
				serial.send(envelope);
		}
	}

	@Override
	public String description() {
		return "Send deformation/temperature sampling task";
	}

	@Override
	public String label() {
		return "Deformation/Temperature";
	}

	@Override
	public void setSerial(SerialComm serial) {
		this.serial = serial;
	}
}
