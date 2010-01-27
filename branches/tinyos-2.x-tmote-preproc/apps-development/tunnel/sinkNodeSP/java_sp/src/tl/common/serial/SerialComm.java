/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1021 $
 * * DATE
 * *    $LastChangedDate: 2010-01-13 04:55:46 -0600 (Wed, 13 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SerialComm.java 1021 2010-01-13 10:55:46Z mceriotti $
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

/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

package tl.common.serial;

import net.tinyos.message.*;

import java.io.FileWriter;
import java.io.IOException;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.common.types.Tuple;
import tl.common.types.TupleSerialMsg;
import tl.common.serial.SerialControlMsg;
import tl.common.utils.Serializer;

public class SerialComm {

	private Hashtable<MoteIF, SerialHandler> serials;
	private Vector<_ITupleHandler> listeners;
	private String FILE_NAME = "serial_protocol.log";

	public SerialComm(Vector<MoteIF> nodes) {
		this.serials = new Hashtable<MoteIF, SerialHandler>();
		for (int i = 0; i < nodes.size(); i++) {
			if (nodes.get(i) != null)
				serials.put(nodes.get(i), new SerialHandler(nodes.get(i)));
		}
		this.listeners = new Vector<_ITupleHandler>();
	}

	public Vector<MoteIF> getSerials() {
		Vector<MoteIF> ret = new Vector<MoteIF>();
		Enumeration<MoteIF> en = serials.keys();
		while (en.hasMoreElements()) {
			ret.add(en.nextElement());
		}
		return ret;
	}

	public void activate() {
		Enumeration<SerialHandler> en = serials.elements();
		while (en.hasMoreElements()) {
			en.nextElement().activate();
		}
	}

	public void deactivate() {
		listeners.clear();
		Enumeration<SerialHandler> en = serials.elements();
		while (en.hasMoreElements()) {
			en.nextElement().activate();
		}
	}

	public void addListener(_ITupleHandler listener) {
		listeners.add(listener);
	}

	public void removeListener(_ITupleHandler listener) {
		listeners.remove(listener);
	}

	public void sendToAll(Tuple tuple) {
		TupleSerialMsg m = new TupleSerialMsg();
		m.set_data(Serializer.toSerial(tuple));
		sendToAll(m);
	}

	public void sendToOne(Tuple tuple) {
		TupleSerialMsg m = new TupleSerialMsg();
		m.set_data(Serializer.toSerial(tuple));
		sendToOne(m);
	}

	public void sendTo(Tuple tuple, MoteIF mote) {
		TupleSerialMsg m = new TupleSerialMsg();
		m.set_data(Serializer.toSerial(tuple));
		sendTo(m, mote);
	}

	public void sendToAll(Message msg) {
		Enumeration<SerialHandler> en = serials.elements();
		while (en.hasMoreElements()) {
			en.nextElement().send(msg);
		}
	}

	public void sendToOne(Message msg) {
		Enumeration<SerialHandler> en = serials.elements();
		if (en.hasMoreElements()) {
			en.nextElement().send(msg);
		}
	}

	public void sendTo(Message msg, MoteIF mote) {

		if (mote != null) {
			SerialHandler sh = null;
			if ((sh = serials.get(mote)) != null) {
				sh.send(msg);
			} else {
				try {
					mote.send(MoteIF.TOS_BCAST_ADDR, msg);
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
	}

	private class SerialHandler extends Thread implements MessageListener {
		private int counter;
		private int in;
		private int out;
		private int prein;
		private int preout;
		private int booting;
		private boolean active;
		private MoteIF mote;
		private Vector<Message> tuple_msgs;

		private SerialHandler(MoteIF mote) {
			super();
			this.counter = 0;
			this.in = 0;
			this.out = 0;
			this.prein = 0;
			this.preout = 0;
			this.booting = 2;
			this.mote = mote;
			tuple_msgs = new Vector<Message>();
		}

		public void activate() {
			active = true;
			mote.registerListener(new TupleSerialMsg(), this);
			mote.registerListener(new SerialControlMsg(), this);
			new Thread(this).start();
		}

		public void deactivate() {
			active = false;
			mote.deregisterListener(new TupleSerialMsg(), this);
			mote.deregisterListener(new SerialControlMsg(), this);
			synchronized (tuple_msgs) {
				tuple_msgs.notifyAll();
			}
			mote.getSource().shutdown();
		}

		public void messageReceived(int to, Message message) {
			if (message instanceof TupleSerialMsg
					|| message instanceof SerialControlMsg) {
				synchronized (tuple_msgs) {
					tuple_msgs.add(message);
					tuple_msgs.notifyAll();
				}
			}
		}

		public void send(Message msg) {
			try {
				out++;
				if (msg instanceof SerialControlMsg) {
					if (((SerialControlMsg) msg).get_booting() == 2) {
						FileWriter writer;
						try {
							writer = new FileWriter(FILE_NAME, true);
							writer.write("[Serial Protocol "
									+ new Date(System.currentTimeMillis())
									+ "] Sent < "
									+ ((SerialControlMsg) msg).get_booting()
									+ " , " + ((SerialControlMsg) msg).get_in()
									+ " , "
									+ ((SerialControlMsg) msg).get_out()
									+ " >\n");
							writer.flush();
							writer.close();
						} catch (IOException e1) {
							// TODO Auto-generated catch block
							e1.printStackTrace();
						}
					}
					if (out == 2 && booting == 2) {
						booting = 1;
						prein = 1;
						preout = 1;
						in = 0;
						out = 0;
					} else if (booting == 1) {
						preout = out;
						out = 0;
					}
				}
				mote.send(MoteIF.TOS_BCAST_ADDR, msg);
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		public void run() {
			while (this.active) {
				Message message = null;
				synchronized (tuple_msgs) {
					if (!tuple_msgs.isEmpty()) {
						message = tuple_msgs.remove(0);
					} else {
						try {
							tuple_msgs.wait();
						} catch (InterruptedException e) {
							e.printStackTrace();
						}
					}
				}
				if (message != null) {
					if (message instanceof SerialControlMsg
							&& message.dataGet()[17] == 3) {
						SerialControlMsg scm = (SerialControlMsg) message;
						if (scm.get_booting() == 2) {
							FileWriter writer;
							try {
								writer = new FileWriter(FILE_NAME, true);
								writer.write("[Serial Protocol "
										+ new Date(System.currentTimeMillis())
										+ "] Received < " + scm.get_booting()
										+ " , " + scm.get_in() + " , "
										+ scm.get_out() + " >\n");
								writer.flush();
								writer.close();
							} catch (IOException e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
							if (scm.get_out() == 0 && scm.get_in() == 0) {
								in = 0;
								out = 0;
								booting = 2;
							}
							if (out == scm.get_in()) {
								in++;
								scm.set_in(in);
								scm.set_out(out);
								try {
									new ReplyThread(scm, this).start();
								} catch (Exception e) {
									e.printStackTrace();
								}
							} else {
								try {
									writer = new FileWriter(FILE_NAME, true);
									writer.write("[Serial Protocol "
											+ new Date(System
													.currentTimeMillis())
											+ "] BOOTING CONTROL FAILED "
											+ out + "!=" + scm.get_in()
											+ "\n");
									writer.flush();
									writer.close();
								} catch (IOException e1) {
									// TODO Auto-generated catch block
									e1.printStackTrace();
								}
							}
						} else if (scm.get_booting() == 1 && booting == 1) {
							if (preout == scm.get_in()) {
								scm.set_in(prein);
								scm.set_out(out);
								prein = in + 1;
								in = 0;
								try {
									new ReplyThread(scm, this).start();
								} catch (Exception e) {
									e.printStackTrace();
								}
							} else {
								booting = 2;
								FileWriter writer;
								try {
									writer = new FileWriter(FILE_NAME, true);
									writer.write("[Serial Protocol "
											+ new Date(System
													.currentTimeMillis())
											+ "] CONTROL FAILED " + preout
											+ "!=" + scm.get_in() + "\n");
									writer.flush();
									writer.close();
								} catch (IOException e1) {
									// TODO Auto-generated catch block
									e1.printStackTrace();
								}
							}
						}
					} else if (message instanceof TupleSerialMsg
							&& message.dataGet()[17] != 3) {
						in++;
						Tuple tuple = Serializer
								.toTuple(((TupleSerialMsg) message).get_data());
						for (int i = 0; i < listeners.size(); i++)
							listeners.get(i).handleTuple(tuple);
					}
				}
			}
		}
	}

	private class ReplyThread extends Thread {

		private Message msg;
		private SerialHandler sh;

		private ReplyThread(Message msg, SerialHandler sh) {
			this.msg = msg;
			this.sh = sh;
		}

		public void run() {
			try {
				this.sleep(100);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			sh.send(msg);
		}
	}

}
