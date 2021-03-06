/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 785 $
 * * DATE
 * *    $LastChangedDate: 2009-04-29 05:50:15 -0500 (Wed, 29 Apr 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: FeatureTest.java 785 2009-04-29 10:50:15Z mceriotti $
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

package tl.apps.routingTest;

import tl.lib.dataCollection._CollectionFeature;

public class FeatureTest implements _CollectionFeature {

	final static String BATTERY = "Battery";
	final static String CLASS_1 = "Class1";
	final static String CLASS_2 = "Class2";
	final static String TREE_INFO = "TreeInfo";
	final static String NULL = "Null";

	private String id;
	private String label;

	public FeatureTest(String id, String label) {
		this.id = id;
		this.label = label;
	}

	public String id() {
		return id;
	}

	public boolean isReliable() {
		if (id == CLASS_1) {
			return true;
		} else {
			return false;
		}
	}

	public String label() {
		return label;
	}

	public boolean equals(Object obj) {
		if (obj instanceof FeatureTest) {
			return ((FeatureTest) obj).id == this.id;
		}
		return false;
	}

	public int hashCode() {
		return this.id.hashCode();
	}

}
