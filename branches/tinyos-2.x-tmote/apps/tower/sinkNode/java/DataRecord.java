/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 253 $
 * * DATE
 * *    $LastChangedDate: 2008-01-23 02:10:36 -0600 (Wed, 23 Jan 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: DataRecord.java 253 2008-01-23 08:10:36Z mceriotti $
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

import java.sql.Timestamp;

/**
 * The Class DataRecord.
 *
 * Data structure that contains the data read from the log.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

class DataRecord {

	private short type;
	private int node_identifier;
	private int period;
	private float temperature;
	private Timestamp time;
	
	DataRecord(short type, int node_identifier, int period, float temperature, Timestamp time){
		this.type = type;
		this.node_identifier = node_identifier;
		this.period = period;
		this.temperature = temperature;
		this.time = time;
	}

	protected short getType() {
		return type;
	}

	protected void setType(short type) {
		this.type = type;
	}

	protected int getNode_identifier() {
		return node_identifier;
	}

	protected void setNode_identifier(int node_identifier) {
		this.node_identifier = node_identifier;
	}

	protected int getPeriod() {
		return period;
	}

	protected void setPeriod(int period) {
		this.period = period;
	}

	protected float getTemperature() {
		return temperature;
	}

	protected void setTemperature(float temperature) {
		this.temperature = temperature;
	}

	protected Timestamp getTime() {
		return time;
	}

	protected void setTime(Timestamp time) {
		this.time = time;
	}
}
