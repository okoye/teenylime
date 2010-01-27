package tl.apps.tower;

import java.util.Date;
import java.util.Vector;

import tl.lib.dataCollection.data.CompressedSampleBuffer;
import tl.lib.dataCollection.data.Sample;

public class Compressed12bVibrationBuffer extends CompressedSampleBuffer {

	boolean[] incomplete;
	int[] samplesId;
	Sample[] lastAxisSample;
	int[] lastSampleStatus;

	public Compressed12bVibrationBuffer(int size) {
		super(size);
		lastAxisSample = new Sample[] { new Sample(null), new Sample(null),
				new Sample(null) };
		incomplete = new boolean[] { false, false, false };
		lastSampleStatus = new int[] { 2, 2, 2 };
		samplesId = new int[] { -1, -1, -1 };
	}

	public void clear() {
		super.clear();
		lastAxisSample = new Sample[] { new Sample(null), new Sample(null),
				new Sample(null) };
		incomplete = new boolean[] { false, false, false };
		lastSampleStatus = new int[] { 2, 2, 2 };
		samplesId = new int[] { -1, -1, -1 };
	}

	public boolean isIncomplete(int axis) {
		if (axis > incomplete.length)
			return false;
		return incomplete[axis - 1];
	}

	public Vector<Sample> decompress() {
		Vector<Sample> samples = new Vector<Sample>();
		Vector<Sample> toElaborate = this.flush();
		for (int i = 0; i < toElaborate.size(); i++) {
			Sample s = toElaborate.get(i);
			Vector<Integer> sampleValue = (Vector<Integer>) s.getValue();
			int axis = sampleValue.get(0);
			if (incomplete[axis - 1]
					|| (lastAxisSample[axis - 1].getSamplingPeriod() != Sample.NO_PERIOD && !s
							.isSamePeriod(new Sample(null,
									lastAxisSample[axis - 1]
											.getSamplingPeriod() + 3)))) {
				incomplete[axis - 1] = true;
				Vector<Integer> dec = new Vector<Integer>();
				dec.add(axis);
				dec.add(new Integer(-1));
				samples.add(new Sample(dec, ++samplesId[axis - 1], s
						.getTimestamp(), s.isEndingSession()));
				continue;
			}
			int value = 0;
			if (lastSampleStatus[axis - 1] == 0) {
				value = (((Vector<Integer>) lastAxisSample[axis - 1].getValue())
						.lastElement() & 0x00FF);
			} else if (lastSampleStatus[axis - 1] == 1) {
				value = (((Vector<Integer>) lastAxisSample[axis - 1].getValue())
						.lastElement() & 0x00F0) >> 4;
			}
			for (int j = 1; j < sampleValue.size(); j++) {
				if (lastSampleStatus[axis - 1] == 0) {
					value += ((Integer) sampleValue.get(j) & 0x000F) << 8;
					Vector<Integer> dec = new Vector<Integer>();
					dec.add(axis);
					dec.add(new Integer(value));
					samples.add(new Sample(dec, ++samplesId[axis - 1], s
							.getTimestamp(), s.isEndingSession()));
					value = ((Integer) sampleValue.get(j) & 0x00F0) >> 4;
				} else if (lastSampleStatus[axis - 1] == 1) {
					value += ((Integer) sampleValue.get(j) & 0x00FF) << 4;
					Vector<Integer> dec = new Vector<Integer>();
					dec.add(axis);
					dec.add(new Integer(value));
					samples.add(new Sample(dec, ++samplesId[axis - 1], s
							.getTimestamp(), s.isEndingSession()));
					value = 0;
				} else if (lastSampleStatus[axis - 1] == 2) {
					value = ((Integer) sampleValue.get(j) & 0x00FF);
				}
				lastSampleStatus[axis - 1] = (lastSampleStatus[axis - 1] + 1) % 3;
			}
			lastAxisSample[axis - 1] = s;
			if (s.isEndingSession()) {
				lastAxisSample = new Sample[] { new Sample(null),
						new Sample(null), new Sample(null) };
				incomplete = new boolean[] { false, false, false };
				lastSampleStatus = new int[] { 2, 2, 2 };
				samplesId = new int[] { -1, -1, -1 };
			}
		}
		return samples;
	}
}
