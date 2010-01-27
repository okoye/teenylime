/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 756 $
 * * DATE
 * *    $LastChangedDate: 2009-03-28 07:20:32 -0500 (Sat, 28 Mar 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SampleBuffer.java 756 2009-03-28 12:20:32Z mceriotti $
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

import java.util.Collections;
import java.util.Hashtable;
import java.util.Vector;

public class SampleBuffer {

	private Hashtable<Integer, Sample> buffer;
	private Sample lastFlushedSample;
	private int size;

	public SampleBuffer(int size) {
		this.buffer = new Hashtable<Integer, Sample>();
		lastFlushedSample = null;
		this.size = size;
	}

	public void addSample(Sample sample) {
		buffer.put(new Integer(sample.getSamplingPeriod()), sample);
	}

	public Sample lastFlushedSample() {
		return lastFlushedSample;
	}

	public Vector<Sample> flush() {
		Vector<Sample> ret = new Vector<Sample>();
		Vector<Integer> v = new Vector<Integer>(buffer.keySet());
		Collections.sort(v);
		while (buffer.size() > size) {
			lastFlushedSample = buffer.remove(v.firstElement());
			v.remove(0);
			ret.add(lastFlushedSample);
		}
		while (buffer.size() > 0 && lastFlushedSample != null) {
			Sample expected = new Sample(null, lastFlushedSample
					.getSamplingPeriod() + 1);
			if (buffer.get(v.firstElement()).isSamePeriod(expected)) {
				lastFlushedSample = buffer.remove(v.firstElement());
				ret.add(lastFlushedSample);
				v.remove(0);
			} else {
				break;
			}
		}
		return ret;
	}

	public void clear() {
		buffer.clear();
	}

}
