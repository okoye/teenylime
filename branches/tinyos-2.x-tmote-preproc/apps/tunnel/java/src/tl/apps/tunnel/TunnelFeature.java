/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:08:41 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TunnelFeature.java 885 2009-07-15 16:08:41Z mceriotti $
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

package tl.apps.tunnel;

import tl.lib.dataCollection._CollectionFeature;

public class TunnelFeature implements _CollectionFeature {

	final static String BATTERY = "Battery";
	final static String MEAN_LIGHT = "MeanLight";
	final static String RAW_MEAN_LIGHT = "RawMeanLight";
	final static String STD_DEV_LIGHT = "StdDevLight";
	final static String RAW_VARIANCE_LIGHT = "RawVarianceLight";
	final static String MEAN_TEMPERATURE = "MeanTemperature";
	final static String RAW_MEAN_TEMPERATURE = "RawMeanTemperature";
	final static String STD_DEV_TEMPERATURE = "StdDevTemperature";
	final static String RAW_VARIANCE_TEMPERATURE = "RawVarianceTemperature";
	final static String TREE_INFO = "TreeInfo";
	final static String PARENT = "Parent";
	final static String PARENT_QUALITY = "ParentQuality";
	final static String TEMPERATURE = "Temperature";
	final static String NULL = "Null";

	private String id;
	private String label;

	public TunnelFeature(String id, String label) {
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
		if (obj instanceof TunnelFeature) {
			return ((TunnelFeature) obj).id == this.id;
		}
		return false;
	}

	public int hashCode() {
		return this.id.hashCode();
	}

}
