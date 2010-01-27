/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 997 $
 * * DATE
 * *    $LastChangedDate: 2009-12-07 16:19:22 -0600 (Mon, 07 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TaskPanelV.java 997 2009-12-07 22:19:22Z mceriotti $
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

package tl.apps.tower.gui;

import javax.swing.*;

import java.awt.*;
import java.awt.event.*;
import javax.swing.BorderFactory;

import tl.apps.tower.Constants;
import tl.apps.tower.Properties;
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.common.utils.Serializer;
import tl.lib.dataDissemination.gui._GUIDisseminator;

class TaskPanelV extends _GUIDisseminator {

	private JLabel label_r, label_s, label_n, label_n2;
	private JTextField r, s, n;
	private JButton taskButton;
	private SerialComm serial;

	public TaskPanelV() {
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
		label_r = new JLabel("Sampling frequency (F) in Hz");
		taskPanel.add(label_r, c);
		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 2;
		r = new JTextField();
		taskPanel.add(r, c);
		c.gridx = 0;
		c.gridy = 2;
		c.gridwidth = 2;
		label_s = new JLabel("Sampling duration (D) in seconds");
		taskPanel.add(label_s, c);
		c.gridx = 0;
		c.gridy = 3;
		c.gridwidth = 2;
		s = new JTextField();
		taskPanel.add(s, c);
		c.gridx = 0;
		c.gridy = 4;
		c.gridwidth = 2;
		label_n = new JLabel("Sampling sessions (N), -1 for infinite");
		taskPanel.add(label_n, c);
		c.gridx = 0;
		c.gridy = 5;
		c.gridwidth = 2;
		n = new JTextField();
		taskPanel.add(n, c);
		c.gridx = 0;
		c.gridy = 6;
		c.gridwidth = 2;
		taskButton = new JButton("Submit task");
		taskButton.setActionCommand("submit_vibr_task");
		taskButton.setVerticalTextPosition(AbstractButton.CENTER);
		taskButton.setHorizontalTextPosition(AbstractButton.LEADING);
		taskButton.setEnabled(true);
		taskButton.addActionListener(this);
		taskPanel.add(taskButton, c);
		taskPanel.setBorder(BorderFactory.createTitledBorder("Vibration"));

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
		if ("submit_vibr_task".equals(e.getActionCommand())) {
			int value_r, value_s, value_n;
			Tuple content = new Tuple();
			Tuple envelope = new Tuple();
			try {
				value_r = Integer.parseInt(r.getText());
				value_s = Integer.parseInt(s.getText());
				value_n = Integer.parseInt(n.getText());
				if (value_n == -1)
					value_n = Constants.INFINITE_OP_TIME;
				r.setText("");
				s.setText("");
				n.setText("");
				content.add(new Field().actualField(new Uint8(
						Constants.TASK_TYPE)));
				content.add(new Field().actualField(new Uint8(
						Constants.VIBRATION_TASK)));
				content.add(new Field().actualField(new Uint16(value_r)));
				content.add(new Field().actualField(new Uint16(value_s)));
				content.add(new Field().actualField(new Uint16(value_n)));

				envelope.add(new Field().actualField(new Uint8(
						Constants.DISSEMINATION_TYPE)));
				envelope.add(new Field().actualField(new Uint16(
						Constants.DISSEMINATE_A_NEW_TUPLE)));
				envelope.add(new Field().actualField(new Uint16(
						Constants.VIBRATION_TASK)));
				envelope.add(new Field().actualField(new Uint8Array(
						Properties.TUPLE_DISS_PAYLOAD_SIZE).setValue(Serializer
						.toSerial(content))));
			} catch (NumberFormatException err) {
				JOptionPane.showMessageDialog(this, "Invalid value inserted.",
						"Error", JOptionPane.ERROR_MESSAGE);
				return;
			}
			if (serial != null) {
				Tuple synch = new Tuple();
				synch.add(new Field().actualField(new Uint8(
						Constants.SYNCHRONIZATION_TYPE)));
				synch.add(new Field().actualField(new Uint16(0)));
				synch.add(new Field().actualField(new Uint16(0)));
				synch.add(new Field().actualField(new Uint16(0)));
				serial.sendToOne(synch);
				serial.sendToOne(envelope);
			}
		}
	}

	@Override
	public String description() {
		return "Send vibration sampling task";
	}

	@Override
	public String label() {
		return "Vibration";
	}

	@Override
	public void setSerial(SerialComm serial) {
		this.serial = serial;
	}
}
