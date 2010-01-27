/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 973 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 00:49:06 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: ExportDataPanel.java 973 2009-12-03 06:49:06Z mceriotti $
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

/**
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

package tl.apps.tower.gui;

import javax.swing.*;

import java.awt.*;
import java.awt.event.*;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.swing.BorderFactory;

import com.jcraft.jsch.*;

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

class ExportDataPanel extends _GUIDisseminator {

	private JLabel label_p, label_f, label_n, label_n2;
	private JRadioButton radio_temp, radio_light, radio_def, radio_vibr;
	private ButtonGroup radio_group;
	private JButton selButton;
	private JProgressBar progressBar;
	private GUIScenarioTower scenario;
	private String command;
	private boolean vibr;

	public ExportDataPanel(GUIScenarioTower scenario) {
		super();
		this.scenario = scenario;
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
		label_p = new JLabel("Data Channel");
		taskPanel.add(label_p, c);

		c.gridx = 0;
		c.gridy = 1;
		c.gridwidth = 2;
		radio_temp = new JRadioButton("Temperature");
		radio_temp.setActionCommand("Temperature");
		radio_temp.setSelected(true);
		command = "scp -f ~/Temperature.txt";
		radio_temp.addActionListener(this);
		taskPanel.add(radio_temp, c);

		c.gridx = 0;
		c.gridy = 2;
		c.gridwidth = 2;
		radio_light = new JRadioButton("Light");
		radio_light.setActionCommand("Light");
		radio_light.addActionListener(this);
		taskPanel.add(radio_light, c);

		c.gridx = 0;
		c.gridy = 3;
		c.gridwidth = 2;
		radio_def = new JRadioButton("Deformation");
		radio_def.setActionCommand("Deformation");
		radio_def.addActionListener(this);
		taskPanel.add(radio_def, c);

		c.gridx = 0;
		c.gridy = 4;
		c.gridwidth = 2;
		radio_vibr = new JRadioButton("Vibration");
		radio_vibr.setActionCommand("Vibration");
		vibr = false;
		radio_vibr.addActionListener(this);
		taskPanel.add(radio_vibr, c);

		radio_group = new ButtonGroup();
		radio_group.add(radio_temp);
		radio_group.add(radio_light);
		radio_group.add(radio_def);
		radio_group.add(radio_vibr);

		c.gridx = 0;
		c.gridy = 5;
		c.gridwidth = 2;
		selButton = new JButton("Download Log");
		selButton.setActionCommand("download_log");
		selButton.setVerticalTextPosition(AbstractButton.CENTER);
		selButton.setHorizontalTextPosition(AbstractButton.LEADING);
		selButton.setEnabled(true);
		selButton.addActionListener(this);
		taskPanel.add(selButton, c);

		c.gridx = 0;
		c.gridy = 6;
		c.gridwidth = 2;
		progressBar = new JProgressBar(0, 100);
		progressBar.setValue(0);
		progressBar.setStringPainted(true);
		taskPanel.add(progressBar, c);

		taskPanel.setBorder(BorderFactory.createTitledBorder("Export Data"));

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
		if ("download_log".equals(e.getActionCommand())) {
			progressBar.setString("Downloading...");
			FileOutputStream fos = null;
			String prefix = null;
			String localLocation = ".";
			JFileChooser chooser;
			chooser = new JFileChooser();
			// chooser.setCurrentDirectory(new java.io.File("."));
			chooser.setDialogTitle("Choose a directory where to save the file");
			chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
			chooser.setAcceptAllFileFilterUsed(false);
			if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
				localLocation = chooser.getSelectedFile().getAbsolutePath()
						+ File.separator;
				if (vibr){
					localLocation += "vibr" + File.separator;
					File directory = new File(localLocation);
					directory.mkdirs();
				}
			} else {
				return;
			}
			try {
				JSch jsch = new JSch();
				java.util.Properties config = new java.util.Properties();
				config.put("StrictHostKeyChecking", "no");
				Session session = jsch.getSession("***", "localhost", 22);
				session.setConfig(config);
				session.setPassword("***");
				session.connect();
				Channel channel = session.openChannel("exec");
				System.out.println("Command: " + command);
				((ChannelExec) channel).setCommand(command);
				OutputStream out = channel.getOutputStream();
				InputStream in = channel.getInputStream();
				channel.connect();
				byte[] buf = new byte[1024];
				// send '\0'
				buf[0] = 0;
				out.write(buf, 0, 1);
				out.flush();
				while (true) {
					int c = checkAck(in);
					if (c != 'C') {
						break;
					}
					// read '0644 '
					in.read(buf, 0, 5);
					long filesize = 0L;
					while (true) {
						if (in.read(buf, 0, 1) < 0) {
							// error
							break;
						}
						if (buf[0] == ' ')
							break;
						filesize = filesize * 10L + (long) (buf[0] - '0');
					}
					String file = null;
					for (int i = 0;; i++) {
						in.read(buf, i, 1);
						if (buf[i] == (byte) 0x0a) {
							file = new String(buf, 0, i);
							break;
						}
					}
					progressBar.setValue(0);
					System.out.println("filesize=" + filesize + ", file="
							+ file);
					// send '\0'
					buf[0] = 0;
					out.write(buf, 0, 1);
					out.flush();
					long size_old = filesize;
					long progress = 0;
					// read a content of lfile
					fos = new FileOutputStream(localLocation + file);
					int foo;
					while (true) {
						if (buf.length < filesize)
							foo = buf.length;
						else
							foo = (int) filesize;
						foo = in.read(buf, 0, foo);
						if (foo < 0) {
							// error
							break;
						}
						fos.write(buf, 0, foo);
						filesize -= foo;
						progress += foo;
						if (filesize == 0L)
							break;
						progressBar.setValue((int) (progress / size_old));
					}
					progressBar.setValue(100);
					fos.close();
					fos = null;
					if (checkAck(in) != 0) {
						System.exit(0);
					}
					// send '\0'
					buf[0] = 0;
					out.write(buf, 0, 1);
					out.flush();
				}
				progressBar.setString("DONE!");
				session.disconnect();

			} catch (Exception e1) {
				System.out.println(e1);
				progressBar.setString("ERROR");
				try {
					if (fos != null)
						fos.close();
				} catch (Exception ee) {
				}
			}
		} else if ("Temperature".equals(e.getActionCommand())) {
			command = "scp -f ~/Temperature.txt";
			vibr = false;
		} else if ("Light".equals(e.getActionCommand())) {
			command = "scp -f ~/Light.txt";
			vibr = false;
		} else if ("Deformation".equals(e.getActionCommand())) {
			command = "scp -f ~/Deformation.txt";
			vibr = false;
		} else if ("Vibration".equals(e.getActionCommand())) {
			command = "scp -f ~/vibr/*";
			vibr = true;
		}
	}

	static int checkAck(InputStream in) throws IOException {
		int b = in.read();
		// b may be 0 for success,
		// 1 for error,
		// 2 for fatal error,
		// -1
		if (b == 0)
			return b;
		if (b == -1)
			return b;

		if (b == 1 || b == 2) {
			StringBuffer sb = new StringBuffer();
			int c;
			do {
				c = in.read();
				sb.append((char) c);
			} while (c != '\n');
			if (b == 1) { // error
				System.out.print(sb.toString());
			}
			if (b == 2) { // fatal error
				System.out.print(sb.toString());
			}
		}
		return b;
	}

	@Override
	public String description() {
		return "Export Data";
	}

	@Override
	public String label() {
		return "Export Data";
	}

	@Override
	public void setSerial(SerialComm serial) {
	}
}
