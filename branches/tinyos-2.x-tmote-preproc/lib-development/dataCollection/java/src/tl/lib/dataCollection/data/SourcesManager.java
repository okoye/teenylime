/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 684 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:07:49 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SourcesManager.java 684 2008-10-01 10:07:49Z mceriotti $
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

package tl.lib.dataCollection.data;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionScenario;

public class SourcesManager {

	private static Hashtable<SourceId, Source> sources = null;

	public static boolean exists(SourceId id) {
		if (sources != null)
			return sources.containsKey(id);
		else
			return false;
	}

	public static void addSource(_CollectionScenario scenario, SourceId id) {
		if (sources == null)
			sources = new Hashtable<SourceId, Source>();
		Source source = scenario.createSource(id);
		sources.put(id, source);
	}

	public static Source getSource(SourceId id) {
		if (sources == null)
			return null;
		return sources.get(id);
	}

	public static Vector<SourceId> getAllSourcesId() {
		if (sources == null)
			return new Vector<SourceId>();
		Vector<SourceId> sourcesId = new Vector<SourceId>();
		Enumeration<SourceId> keys = sources.keys();
		while (keys.hasMoreElements()) {
			sourcesId.add(keys.nextElement());
		}
		return sourcesId;
	}
}
