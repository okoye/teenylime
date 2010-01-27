/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 699 $
 * * DATE
 * *    $LastChangedDate: 2008-10-26 04:39:44 -0500 (Sun, 26 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Sample.java 699 2008-10-26 09:39:44Z mceriotti $
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

import java.util.Date;

public class Sample {

	public static final int NO_PERIOD = -1;
	public static final int MAX_SAMPLING_PERIOD = 0xFFFF + 1;

	private Object value;
	private int samplingPeriod;
	private Date timestamp;
	private boolean endingSession;

	public Sample(Object value) {
		this(value, NO_PERIOD, new Date(System.currentTimeMillis()), false);
	}

	public Sample(Object value, Date timestamp) {
		this(value, NO_PERIOD, timestamp, false);
	}

	public Sample(Object value, int samplingPeriod) {
		this(value, samplingPeriod, new Date(System.currentTimeMillis()), false);
	}

	public Sample(Object value, int samplingPeriod, boolean endingSession) {
		this(value, samplingPeriod, new Date(System.currentTimeMillis()),
				endingSession);
	}

	public Sample(Object value, int samplingPeriod, Date timestamp) {
		this(value, samplingPeriod, timestamp, false);
	}

	public Sample(Object value, int samplingPeriod, Date timestamp,
			boolean endingSession) {
		this.value = value;
		this.samplingPeriod = samplingPeriod % MAX_SAMPLING_PERIOD;
		this.timestamp = timestamp;
		this.endingSession = endingSession;
	}

	public Object getValue() {
		return value;
	}

	public int getSamplingPeriod() {
		return samplingPeriod;
	}

	public Date getTimestamp() {
		return timestamp;
	}

	public void setTimestamp(Date timestamp) {
		this.timestamp = timestamp;
	}

	public boolean isEndingSession() {
		return endingSession;
	}

	public boolean isNewerThan(Sample sample) {
		if (sample.samplingPeriod == NO_PERIOD)
			return true;
		if (sample.samplingPeriod != NO_PERIOD
				&& this.samplingPeriod == NO_PERIOD)
			return false;
		if (sample.samplingPeriod == this.samplingPeriod) {
			return false;
		} else if (sample.samplingPeriod < this.samplingPeriod) {
			if ((this.samplingPeriod - sample.samplingPeriod) < (int) (MAX_SAMPLING_PERIOD / 2)) {
				return true;
			} else {
				return false;
			}
		} else {
			if ((sample.samplingPeriod - this.samplingPeriod) < (int) (MAX_SAMPLING_PERIOD / 2)) {
				return false;
			} else {
				return true;
			}
		}
	}

	public boolean isSamePeriod(Sample sample) {
		return sample.samplingPeriod == this.samplingPeriod;
	}
}
