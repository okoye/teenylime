/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 972 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 00:40:36 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderIR.java 972 2009-12-03 06:40:36Z mceriotti $
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

import java.util.Date;
import java.util.Hashtable;
import java.util.Vector;

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderIR implements _CollectionTupleReader {

	public Hashtable<_CollectionFeature, Sample> read(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		boolean ending = false;
		int period = (data[4] << 8) + data[5];
		Vector<Integer> s = new Vector<Integer>();
		for (int i = 0; i < 26; i++) {
			s.add((data[7 + 2 * i] << 8) + data[6 + 2 * i]);
		}
		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		ret.put(IR.getFeature(), new Sample(s, period, new Date(System
				.currentTimeMillis()), ending));
		return ret;
	}

	public SourceId getSource(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[2] << 8) + data[3];
		return new SourceId(node_identifier);
	}

}
