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
 * *	$Id: FeatureOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office;

import tl.lib.dataCollection._CollectionFeature;

public class FeatureOffice implements _CollectionFeature {

	final static String ACCELERATION = "Acceleration";
	final static String BATTERY = "Battery";
	final static String CO = "CO";
	final static String CO2 = "CO2";
	final static String DUST = "DUST";
	final static String HUMIDITY = "Humidity";
	final static String MAGNETIC = "Magnetic";
	final static String MICROPHONE = "Microphone";
	final static String PRESENCE = "Presence";
	final static String PRESSURE = "Pressure";
	final static String SOLAR_LIGHT = "SolarLight";
	final static String SYNTH_LIGHT = "SynthLight";
	final static String TEMPERATURE = "Temperature";
	final static String TILT = "Tilt";
	final static String TREE_INFO = "TreeInfo";
	final static String NULL = "Null";

	private String id;
	private String label;

	public FeatureOffice(String id, String label) {
		this.id = id;
		this.label = label;
	}

	public String id() {
		return id;
	}

	public boolean isReliable() {
		return false;
	}

	public String label() {
		return label;
	}

	public boolean equals(Object obj) {
		if (obj instanceof FeatureOffice) {
			return ((FeatureOffice) obj).id == this.id;
		}
		return false;
	}

	public int hashCode() {
		return this.id.hashCode();
	}

}