/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 299 $
 * * DATE
 * *    $LastChangedDate: 2008-02-26 12:43:52 -0600 (Tue, 26 Feb 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Properties.java 299 2008-02-26 18:43:52Z mceriotti $
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
 * The Class Properties.
 * 
 * This class contains the properties required to write data inside the
 * database.
 *
 * @author Matteo Ceriotti
 *         <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a> 
 */
class Properties {

	final static String USER = "********";
	final static String PASSWORD = "********";
	final static String HOST = "********";
	final static String PORT = "********";
	final static String DATABASE = "********";

	final static short ROUND_TYPE = 1;
	final static short TASK_TYPE = 2;
	final static short TEMP_DEFORM_TYPE = 3;
	final static short DATA_COLLECT_CTRL_TYPE = 4;
  final static short VIBRATION_TYPE = 5;
	final static short NODE_INFO_TYPE = 6;
	
  final static short TYPE_FORMAL = 128;
  final static short TYPE_EMPTY = 1;
  final static short TYPE_UINT8 = 2;
  final static short TYPE_UINT16 = 3;
  
  final static short INSTANT = 0;
  final static int INFINITE_OP_TIME = (int) (0xFFFF);
  
	final static long TEMP_PERIOD = 1*30*1000;

  final static int TEMP_NODE1 = 3;
  final static int TEMP_NODE2 = 5;
  
  final static int NUM_TEMP_NODES = 2;
  
  final static int NUM_BUF_SAMPLES = 6;
	
	final static int NUM_NODES = 8;

	static String getSensorId(int node_identifier) {
		return new Integer(node_identifier).toString();
	}
	
	static String getTempChannelId(int node_identifier) {
		return new Integer(node_identifier).toString();
	}

  static boolean isDue(DataRecord record){
    if (record.getType() == Properties.TEMP_DEFORM_TYPE){
      if (record.getNode_identifier() == TEMP_NODE1 || 
          record.getNode_identifier() == TEMP_NODE2){
        if ((record.getPeriod()%20)==0){
          return true;
        }
      }
    }
    return false;
  }

}
