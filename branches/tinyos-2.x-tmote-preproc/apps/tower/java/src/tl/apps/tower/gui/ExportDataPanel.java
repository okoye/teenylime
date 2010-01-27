/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1011 $
 * * DATE
 * *    $LastChangedDate: 2010-01-08 03:06:38 -0600 (Fri, 08 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: ExportDataPanel.java 1011 2010-01-08 09:06:38Z mceriotti $
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
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.StringTokenizer;

import javax.swing.BorderFactory;

import com.jcraft.jsch.*;
import com.toedter.calendar.JDateChooser;

import tl.common.serial.SerialComm;
import tl.lib.dataDissemination.gui._GUIDisseminator;

class ExportDataPanel extends _GUIDisseminator {

	private JLabel label_p;
	private JRadioButton radio_temp, radio_light, radio_def, radio_vibr;
	private ButtonGroup radio_group;
	private JButton selButton, chartButton;
	private JProgressBar progressBar;
	private JDateChooser fromDateChooser;
	private JDateChooser toDateChooser;
	private GUIScenarioTower scenario;
	private String command;
	
	private String USER = "***";
	private String PWD = "***";
	private String HOST = "***";

	private String ORIGIN_DATE = "2008/10/01";

	public ExportDataPanel(GUIScenarioTower scenario) {
		super();
		this.scenario = scenario;
		GridBagConstraints c = new GridBagConstraints();

		SimpleDateFormat formatter = new SimpleDateFormat("yyyy/MM/dd");
		Date min_date = new Date(0);
		try {
			min_date = formatter.parse(ORIGIN_DATE);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		// download data
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
		command = "Temperature";
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
		radio_vibr = new JRadioButton("Vibration (multiple files)");
		radio_vibr.setActionCommand("Vibration");
		radio_vibr.addActionListener(this);
		taskPanel.add(radio_vibr, c);

		radio_group = new ButtonGroup();
		radio_group.add(radio_temp);
		radio_group.add(radio_light);
		radio_group.add(radio_def);
		radio_group.add(radio_vibr);

		JLabel label = new JLabel("Time Interval", null, JLabel.LEFT);
		c.gridx = 0;
		c.gridy = 5;
		c.gridwidth = 2;
		taskPanel.add(label, c);

		fromDateChooser = new JDateChooser("yyyy/MM/dd", "####/##/##", '_');
		fromDateChooser.setDate(min_date);
		fromDateChooser.setMinSelectableDate(min_date);
		fromDateChooser.setMaxSelectableDate(new Date());
		label = new JLabel("From : ", null, JLabel.CENTER);
		c.gridx = 0;
		c.gridy = 6;
		c.gridwidth = 1;
		taskPanel.add(label, c);
		c.gridx = 1;
		c.gridy = 6;
		c.gridwidth = GridBagConstraints.REMAINDER;
		taskPanel.add(fromDateChooser, c);

		toDateChooser = new JDateChooser("yyyy/MM/dd", "####/##/##", '_');
		toDateChooser.setDate(new Date());
		toDateChooser.setMinSelectableDate(min_date);
		toDateChooser.setMaxSelectableDate(new Date());
		label = new JLabel("To : ", null, JLabel.CENTER);
		c.gridx = 0;
		c.gridy = 7;
		c.gridwidth = 1;
		taskPanel.add(label, c);
		c.gridx = 1;
		c.gridy = 7;
		c.gridwidth = GridBagConstraints.REMAINDER;
		taskPanel.add(toDateChooser, c);

		c.gridx = 0;
		c.gridy = 8;
		c.gridwidth = 2;
		selButton = new JButton("Download Log");
		selButton.setActionCommand("download_log");
		selButton.setVerticalTextPosition(AbstractButton.CENTER);
		selButton.setHorizontalTextPosition(AbstractButton.LEADING);
		selButton.setEnabled(true);
		selButton.addActionListener(this);
		taskPanel.add(selButton, c);

		c.gridx = 0;
		c.gridy = 9;
		c.gridwidth = 2;
		progressBar = new JProgressBar(0, 100);
		progressBar.setValue(0);
		progressBar.setStringPainted(true);
		taskPanel.add(progressBar, c);

		taskPanel.setBorder(BorderFactory.createTitledBorder("Download Data"));

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
			String localLocation = ".";
			JFileChooser chooser;
			Date from = fromDateChooser.getDate();
			Date to = toDateChooser.getDate();
			if (from.after(to)) {
				JOptionPane.showMessageDialog(this, "Wrong dates order",
						"Error", JOptionPane.ERROR_MESSAGE);
				return;
			}
			chooser = new JFileChooser();
			chooser.setDialogTitle("Choose a directory where to save the file");
			chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
			chooser.setAcceptAllFileFilterUsed(false);
			if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
				localLocation = chooser.getSelectedFile().getAbsolutePath()
						+ File.separator;
				if ("Vibration".equals(command)) {
					localLocation += "vibr" + File.separator;
					File directory = new File(localLocation);
					directory.mkdirs();
				}
			} else {
				return;
			}
			selButton.setEnabled(false);
			new Thread(new Scp(this, localLocation, from, to, "Vibration"
					.equals(command))).start();
		} else if ("Temperature".equals(e.getActionCommand())) {
			command = "Temperature";
		} else if ("Light".equals(e.getActionCommand())) {
			command = "Light";
		} else if ("Deformation".equals(e.getActionCommand())) {
			command = "Deformation";
		} else if ("Vibration".equals(e.getActionCommand())) {
			command = "Vibration";
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

	private class Scp extends Thread {
		private String localLocation;
		private Calendar from;
		private Calendar to;
		private JPanel parent;
		private boolean vibration;

		private int MILLIS_IN_DAY = 1000 * 60 * 60 * 24;

		private Scp(JPanel parent, String localLocation, Date from, Date to,
				boolean vibration) {
			this.localLocation = localLocation;
			this.from = Calendar.getInstance();
			this.from.setTime(from);
			this.to = Calendar.getInstance();
			this.to.setTime(to);
			this.parent = parent;
			this.vibration = vibration;
		}

		public void run() {
			progressBar.setString("Downloading...");
			JSch jsch = new JSch();
			java.util.Properties config = new java.util.Properties();
			config.put("StrictHostKeyChecking", "no");
			Session session;
			try {
				session = jsch.getSession(USER, HOST, 22);
				session.setConfig(config);
				session.setPassword(PWD);
				session.connect();
			} catch (JSchException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				return;
			}
			if (!vibration) {
				int deltaProgress = (int) ((to.getTime().getTime() - from
						.getTime().getTime()) / (MILLIS_IN_DAY)) + 1;
				deltaProgress = 50 / deltaProgress;
				downloadNonVibrData(session, deltaProgress);
				processNonVibrData(deltaProgress);
			} else {
				int deltaProgress = (int) ((to.getTime().getTime() - from
						.getTime().getTime()) / (MILLIS_IN_DAY)) + 1;
				deltaProgress = 100 / deltaProgress;
				downloadVibrData(session, deltaProgress);
			}

		}

		private void downloadNonVibrData(Session session, int deltaProgress) {
			Calendar temp = (Calendar) from.clone();
			progressBar.setValue(0);
			FileOutputStream fos = null;
			try {
				fos = new FileOutputStream(localLocation + command + "_"
						+ from.get(Calendar.YEAR) + "-"
						+ ((from.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (from.get(Calendar.MONTH) + 1) + "-"
						+ ((from.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ from.get(Calendar.DAY_OF_MONTH) + "_"
						+ to.get(Calendar.YEAR) + "-"
						+ ((to.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (to.get(Calendar.MONTH) + 1) + "-"
						+ ((to.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ to.get(Calendar.DAY_OF_MONTH) + ".dat");
				do {
					String cmd = "scp -f /home/log/tower_synched/"
							+ command
							+ "_"
							+ temp.get(Calendar.YEAR)
							+ "-"
							+ ((temp.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
							+ (temp.get(Calendar.MONTH) + 1)
							+ "-"
							+ ((temp.get(Calendar.DAY_OF_MONTH) >= 10) ? ""
									: "0") + temp.get(Calendar.DAY_OF_MONTH)
							+ ".txt";
					Channel channel = session.openChannel("exec");
					((ChannelExec) channel).setCommand(cmd);
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
						// System.out.println("filesize=" + filesize +
						// ", file="
						// + file);
						// send '\0'
						buf[0] = 0;
						out.write(buf, 0, 1);
						out.flush();
						long size_old = filesize;
						long progress = 0;
						// read a content of lfile
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
							fos.flush();
							filesize -= foo;
							progress += foo;
							if (filesize == 0L)
								break;
						}
						if (checkAck(in) != 0) {
							System.exit(0);
						}
						// send '\0'
						buf[0] = 0;
						out.write(buf, 0, 1);
						out.flush();
					}
					progressBar
							.setValue(progressBar.getValue() + deltaProgress);
					channel.disconnect();
					temp.add(Calendar.DAY_OF_YEAR, 1);
				} while (temp.before(to) || temp.equals(to));
				fos.close();
				fos = null;
				session.disconnect();
			} catch (Exception e1) {
				System.err.println(e1);
				progressBar.setString("ERROR");
				selButton.setEnabled(true);
				try {
					if (fos != null)
						fos.close();
				} catch (Exception ee) {
				}
			}
		}

		private void downloadVibrData(Session session, int deltaProgress) {
			Calendar temp = (Calendar) from.clone();
			progressBar.setValue(0);
			FileOutputStream fos = null;
			try {
				do {
					String cmd = "scp -f /home/log/tower_synched/vibr/"
							+ command
							+ "_"
							+ temp.get(Calendar.YEAR)
							+ "-"
							+ ((temp.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
							+ (temp.get(Calendar.MONTH) + 1)
							+ "-"
							+ ((temp.get(Calendar.DAY_OF_MONTH) >= 10) ? ""
									: "0") + temp.get(Calendar.DAY_OF_MONTH)
							+ "*.txt";
					Channel channel = session.openChannel("exec");
					((ChannelExec) channel).setCommand(cmd);
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
						// System.out.println("filesize=" + filesize +
						// ", file="
						// + file);
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
							fos.flush();
							filesize -= foo;
							progress += foo;
							if (filesize == 0L)
								break;
						}
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
					progressBar
							.setValue(progressBar.getValue() + deltaProgress);
					channel.disconnect();
					temp.add(Calendar.DAY_OF_YEAR, 1);
				} while (temp.before(to) || temp.equals(to));
				session.disconnect();
				progressBar.setValue(100);
				progressBar.setString("DONE!");
				selButton.setEnabled(true);
			} catch (Exception e1) {
				System.err.println(e1);
				progressBar.setString("ERROR");
				selButton.setEnabled(true);
				try {
					if (fos != null)
						fos.close();
				} catch (Exception ee) {
				}
			}
		}

		private void processNonVibrData(int deltaProgress) {
			BufferedReader input = null;
			FileWriter output = null;
			// PROCESSING THE FILE
			progressBar.setString("Processing...");
			try {
				input = new BufferedReader(new FileReader(localLocation
						+ command + "_" + from.get(Calendar.YEAR) + "-"
						+ ((from.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (from.get(Calendar.MONTH) + 1) + "-"
						+ ((from.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ from.get(Calendar.DAY_OF_MONTH) + "_"
						+ to.get(Calendar.YEAR) + "-"
						+ ((to.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (to.get(Calendar.MONTH) + 1) + "-"
						+ ((to.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ to.get(Calendar.DAY_OF_MONTH) + ".dat"));
				File f = new File(localLocation + command + "_"
						+ from.get(Calendar.YEAR) + "-"
						+ ((from.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (from.get(Calendar.MONTH) + 1) + "-"
						+ ((from.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ from.get(Calendar.DAY_OF_MONTH) + "_"
						+ to.get(Calendar.YEAR) + "-"
						+ ((to.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (to.get(Calendar.MONTH) + 1) + "-"
						+ ((to.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ to.get(Calendar.DAY_OF_MONTH) + ".txt");
				if (f.exists()) {
					JOptionPane
							.showMessageDialog(
									parent,
									"An output file with the same time interval is already present.\n"
											+ "Please move such a file to another directory and re-run the download command",
									"Error", JOptionPane.ERROR_MESSAGE);
					progressBar.setString("ERROR");
					selButton.setEnabled(true);
					try {
						if (input != null)
							input.close();
						if (output != null)
							output.close();
					} catch (Exception ee) {
					}
					return;
				} else {
					output = new FileWriter(
							localLocation
									+ command
									+ "_"
									+ from.get(Calendar.YEAR)
									+ "-"
									+ ((from.get(Calendar.MONTH) + 1 >= 10) ? ""
											: "0")
									+ (from.get(Calendar.MONTH) + 1)
									+ "-"
									+ ((from.get(Calendar.DAY_OF_MONTH) >= 10) ? ""
											: "0")
									+ from.get(Calendar.DAY_OF_MONTH)
									+ "_"
									+ to.get(Calendar.YEAR)
									+ "-"
									+ ((to.get(Calendar.MONTH) + 1 >= 10) ? ""
											: "0")
									+ (to.get(Calendar.MONTH) + 1)
									+ "-"
									+ ((to.get(Calendar.DAY_OF_MONTH) >= 10) ? ""
											: "0")
									+ to.get(Calendar.DAY_OF_MONTH) + ".txt");
				}
				String s0;
				String sensor = "";
				String raw_value = "";
				String converted = "";
				String ts = "";
				Calendar c = Calendar.getInstance();
				SimpleDateFormat sdf = new SimpleDateFormat(
						"EEE MMM dd HH:mm:ss zzzz yyyy");
				int lastDay = from.get(Calendar.DAY_OF_MONTH);
				while ((s0 = input.readLine()) != null && s0 != "EOF") {
					StringTokenizer stk = new StringTokenizer(s0, " ");
					stk.nextToken(); // SENSOR:
					sensor = stk.nextToken("\t"); // node
					sensor = sensor.replace(" ", "");
					stk.nextToken(" "); // PERIOD:
					stk.nextToken("\t"); // period
					stk.nextToken(" "); // TEMPERATURE/DEFORMATION/LIGHT
					converted = stk.nextToken(" "); // converted
					raw_value = stk.nextToken("\t"); // raw
					raw_value = raw_value.substring(2, raw_value.length() - 1);
					ts = stk.nextToken(); // day of the week
					Date d = sdf.parse(ts);
					c.setTime(d);
					output.append(sensor + " " + raw_value + " " + converted
							+ " " + c.get(Calendar.YEAR) + "-"
							+ ((c.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
							+ (c.get(Calendar.MONTH) + 1) + "-"
							+ ((c.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
							+ c.get(Calendar.DAY_OF_MONTH) + " "
							+ ((c.get(Calendar.HOUR_OF_DAY) >= 10) ? "" : "0")
							+ c.get(Calendar.HOUR_OF_DAY) + ":"
							+ ((c.get(Calendar.MINUTE) >= 10) ? "" : "0")
							+ c.get(Calendar.MINUTE) + ":"
							+ ((c.get(Calendar.SECOND) >= 10) ? "" : "0")
							+ c.get(Calendar.SECOND) + "\n");
					output.flush();
					if (c.get(Calendar.DAY_OF_MONTH) != lastDay) {
						lastDay = c.get(Calendar.DAY_OF_MONTH);
						progressBar.setValue(progressBar.getValue()
								+ deltaProgress);
					}
				}
				input.close();
				f = new File(localLocation + command + "_"
						+ from.get(Calendar.YEAR) + "-"
						+ ((from.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (from.get(Calendar.MONTH) + 1) + "-"
						+ ((from.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ from.get(Calendar.DAY_OF_MONTH) + "_"
						+ to.get(Calendar.YEAR) + "-"
						+ ((to.get(Calendar.MONTH) + 1 >= 10) ? "" : "0")
						+ (to.get(Calendar.MONTH) + 1) + "-"
						+ ((to.get(Calendar.DAY_OF_MONTH) >= 10) ? "" : "0")
						+ to.get(Calendar.DAY_OF_MONTH) + ".dat");
				f.delete();
				output.close();
				progressBar.setValue(100);
				progressBar.setString("DONE!");
				selButton.setEnabled(true);
			} catch (Exception e1) {
				System.err.println(e1);
				progressBar.setString("ERROR");
				selButton.setEnabled(true);
				try {
					if (input != null)
						input.close();
					if (output != null)
						output.close();
				} catch (Exception ee) {
				}
			}
		}
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
