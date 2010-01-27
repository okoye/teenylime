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
 * *	$Id: SourceDescriptorOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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

import java.text.NumberFormat;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionSourceDescriptor;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;

public class SourceDescriptorOffice implements _CollectionSourceDescriptor {

	public SourceDescriptorOffice() {

	}

	public String getOneLineHeader() {
		return "NODE\tREC\tLOST\tPARENT\tCOST\tBATTERY\tINFO TS\n";
	}

	@SuppressWarnings("unchecked")
	public String getOneLineDescription(SourceId sourceId) {
		SourceOffice source = (SourceOffice) SourcesManager.getSource(sourceId);
		String ret = source.identifier().toString();
		ret += "\t" + source.numberOfCollectedSamples();
		ret += "\t" + source.numberOfLostSamples();
		ret += "\t" + source.getParent();
		ret += "\t" + source.getPathCost();
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		ret += "\t" + df.format(source.getBattery());
		ret += "\t" + source.getLastTimeSeen();
		return ret;
	}

	@SuppressWarnings("unchecked")
	public String getLastSampleDescription(SourceId sourceId) {
		SourceOffice source = (SourceOffice) SourcesManager.getSource(sourceId);
		String ret = "";
		ret += "\nLast Time Seen\n" + source.getLastTimeSeen() + "\n";
		return ret;
	}

	public String getMultiLineDescription(SourceId sourceId) {
		SourceOffice source = (SourceOffice) SourcesManager.getSource(sourceId);
		NumberFormat df = NumberFormat.getNumberInstance();
		df.setMaximumFractionDigits(2);
		String ret = "";
		if (!source.isSink()) {
			ret += "Battery " + df.format(source.getBattery()) + "\n";
			ret += getLastSampleDescription(sourceId);
		} else {
			ret += "Sink Node\n";
		}
		return ret;
	}

	public SourceId getParent(SourceId sourceId) {
		SourceOffice source = (SourceOffice) SourcesManager.getSource(sourceId);
		return source.getParent();
	}

	public Integer getPathCost(SourceId sourceId) {
		SourceOffice source = (SourceOffice) SourcesManager.getSource(sourceId);
		return source.getPathCost();
	}
}
