/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 895 $
 * * DATE
 * *    $LastChangedDate: 2009-09-10 04:13:45 -0500 (Thu, 10 Sep 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: TupleReaderLT.java 895 2009-09-10 09:13:45Z mceriotti $
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

import tl.common.types.Tuple;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class TupleReaderLT implements _CollectionTupleReader {

	public Hashtable<_CollectionFeature, Sample> read(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		boolean ending = false;

		int period = (data[6] << 8) + data[7];
		long light_mean = (data[10] << 8) + data[11];
		long light_variance = (data[12] << 8) + data[13];
		long temperature_mean = (data[14] << 8) + data[15];
		long temperature_variance = (data[16] << 8) + data[17];

		Hashtable<_CollectionFeature, Sample> ret = new Hashtable<_CollectionFeature, Sample>();
		ret.put(MeanLight.getFeature(), new Sample(MeanLight
				.convert(light_mean), period, new Date(System
				.currentTimeMillis()), ending));
		ret.put(StdDevLight.getFeature(), new Sample(StdDevLight
				.convert(light_variance), period, new Date(System
				.currentTimeMillis()), ending));
		ret.put(MeanTemperature.getFeature(), new Sample(MeanTemperature
				.convert(temperature_mean), period, new Date(System
				.currentTimeMillis()), ending));
		ret.put(StdDevTemperature.getFeature(), new Sample(StdDevTemperature
				.convert(temperature_variance), period, new Date(System
				.currentTimeMillis()), ending));
		return ret;
	}

	public SourceId getSource(Tuple tuple) {
		short[] data = ((Uint8Array) tuple.get(3).getValue()).serializeValue();
		int node_identifier = (data[4] << 8) + data[5];
		return new SourceId(node_identifier);
	}

}
