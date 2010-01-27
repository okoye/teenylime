/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 262 $
 * * DATE
 * *    $LastChangedDate: 2008-02-02 05:00:33 -0600 (Sat, 02 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: LogReader.java 262 2008-02-02 11:00:33Z mceriotti $
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

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Timestamp;

/**
 * The Class LogReader.
 *
 * Reader of the log file where the received data are written.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

public class LogReader {

	private LogManager manager;
	private InputStreamReader fstream;
	private BufferedReader in;

	public LogReader(FileInputStream file, int line, LogManager manager) {
		this.manager = manager;
		this.fstream = new InputStreamReader(file);
		this.in = new BufferedReader(fstream);
		try {
			for (int i = 1; i < line; i++) {
				in.readLine();
			}
		} catch (IOException e) {
			System.err.println("Cannot move inside the log file");
			e.printStackTrace();
		}
		readData();
	}

	void readData() {
		while (true) {
			String line = "";
			try {
				line = in.readLine();
			} catch (IOException e) {
				e.printStackTrace();
			}
			if (line == null || line.length() == 0) {
				synchronized (this) {
					try {
            manager.flushData();	    
						this.wait(Properties.TEMP_PERIOD);
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
			} else {
				short type = 0;
				int node_identifier = 0;
				int period = 0;
				float temperature = 0;
				Timestamp time = null;
        
				if (line.indexOf("SENSOR") != -1
						&& line.indexOf("PERIOD") != -1) {
					String s = line.split("SENSOR:")[1];
					s = s.split("\\b")[1];
					node_identifier = Integer.parseInt(s);
				} else {
          continue;
        }
        
				if (line.indexOf("PERIOD") != -1
						&& line.indexOf("TEMPERATURE") != -1) {
					String s = line.split("PERIOD:")[1];
					s = s.split("TEMPERATURE")[0];
					s = s.split("\\b")[1];
					period = Integer.parseInt(s);
				} else {
          continue;
        }
        
				if (line.indexOf("TEMPERATURE") != -1
						&& line.indexOf("TIMESTAMP") != -1) {
					String s = line.split("TEMPERATURE:")[1];
					s = s.split("TIMESTAMP")[0];
					temperature = Float.parseFloat(s);
					type = Properties.TEMP_DEFORM_TYPE;
				} else {
          continue;
        }
        
				if (line.indexOf("TIMESTAMP") != -1) {
					String s = line.split("TIMESTAMP:")[1];
					s = s.split("\\*")[0];
					time = Timestamp.valueOf(s);
				} else {
          continue;
        }
        
				DataRecord record = new DataRecord(type, node_identifier,
                                           period, temperature, time);

        if (Properties.isDue(record)){
          manager.bufferData(record);
        }
        
			}

			if (manager.bufferSize() >
          Properties.NUM_TEMP_NODES * Properties.NUM_BUF_SAMPLES) {
				manager.flushData();
			}
      
		}
	}

	private static void man() {
		System.err
      .println("help: LogReader -t <log_mode> -f <source_file> -l <line>");
		System.err.println("-t <log_mode> options: sapdb, mysql");
	}

	public static void main(String[] args) throws Exception {
		String source = null;
		LogManager manager = null;
		int line = 0;
		if (args.length >= 4) {
			if (args[0].equals("-t")) {
				if (args[1].equals("sapdb")) {
					manager = new LogSapDBManager();
				} else if (args[1].equals("mysql")) {
					manager = new LogMySqlManager();
				} else {
					man();
					System.exit(1);
				}
			} else {
				man();
				System.exit(1);
			}
			if (args[2].equals("-f")) {
				source = args[3];
			} else {
				man();
				System.exit(1);
			}
			if (args.length > 4) {
				if (args[4].equals("-l")) {
					line = Integer.parseInt(args[5]);
				} else {
					man();
					System.exit(1);
				}
			}
		} else {
			man();
			System.exit(1);
		}
		FileInputStream file = new FileInputStream(source);
		LogReader serial = new LogReader(file, line, manager);
	}

}
