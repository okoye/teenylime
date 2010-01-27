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
 * *	$Id: GUIScenarioOffice.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office.gui;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Vector;

import javax.imageio.ImageIO;

import tl.apps.office.Acceleration;
import tl.apps.office.Battery;
import tl.apps.office.CO;
import tl.apps.office.CO2;
import tl.apps.office.Constants;
import tl.apps.office.Dust;
import tl.apps.office.Humidity;
import tl.apps.office.Magnetic;
import tl.apps.office.Microphone;
import tl.apps.office.Presence;
import tl.apps.office.Pressure;
import tl.apps.office.SolarLight;
import tl.apps.office.SynthLight;
import tl.apps.office.Temperature;
import tl.apps.office.Tilt;
import tl.apps.office.TreeInfo;
import tl.apps.office.TupleReaderAcceleration;
import tl.apps.office.TupleReaderCO;
import tl.apps.office.TupleReaderCO2;
import tl.apps.office.TupleReaderDust;
import tl.apps.office.TupleReaderHumidity;
import tl.apps.office.TupleReaderMagnetic;
import tl.apps.office.TupleReaderMicrophone;
import tl.apps.office.TupleReaderPresence;
import tl.apps.office.TupleReaderPressure;
import tl.apps.office.TupleReaderSolarLight;
import tl.apps.office.TupleReaderSynthLight;
import tl.apps.office.TupleReaderTemperature;
import tl.apps.office.TupleReaderNodeInfo;
import tl.apps.office.Properties;
import tl.apps.office.TupleReaderTilt;
import tl.common.serial.SerialComm;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection._CollectionSamplesMsgListener;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataCollection.data.SourcesManager;
import tl.lib.dataCollection.gui._ChartPanel;
import tl.lib.dataCollection.gui._CollectionGUIScenario;
import tl.lib.dataCollection.gui._CollectionGUISourceDescriptor;
import tl.lib.dataDissemination.gui._DisseminationGUIScenario;
import tl.lib.dataDissemination.gui._GUIDisseminator;

public class GUIScenarioOffice implements _CollectionGUIScenario,
		_DisseminationGUIScenario {

	private _GUIDisseminator tasker;
	private _CollectionGUISourceDescriptor sourceDescriptor;
	private GUIManager guiManager;
	private Acceleration acceleration;
	private Battery battery;
	private CO co;
	private CO2 co2;
	private Dust dust;
	private Humidity humidity;
	private Magnetic magnetic;
	private Microphone microphone;
	private Presence presence;
	private Pressure pressure;
	private SolarLight solarLight;
	private SynthLight synthLight;
	private Temperature temperature;
	private Tilt tilt;
	private TreeInfo treeInfo;

	public GUIScenarioOffice() {
		this.guiManager = new GUIManager(this);
		this.tasker = new TaskPanel();
		this.sourceDescriptor = new GUISourceDescriptorOffice();
		this.acceleration = new Acceleration(true);
		this.battery = new Battery(true);
		this.co = new CO(true);
		this.co2 = new CO2(true);
		this.dust = new Dust(true);
		this.humidity = new Humidity(true);
		this.magnetic = new Magnetic(true);
		this.microphone = new Microphone(true);
		this.presence = new Presence(true);
		this.pressure = new Pressure(true);
		this.solarLight = new SolarLight(true);
		this.synthLight = new SynthLight(true);
		this.temperature = new Temperature(true);
		this.tilt = new Tilt(true);
		this.treeInfo = new TreeInfo(true);
		SourcesManager.addSource(this, new SourceId(Properties.SINK_ADDRESS));
	}

	public Source createSource(SourceId id) {
		SourceId sinkId = new SourceId(Properties.SINK_ADDRESS);
		return new GUISourceOffice(id, id.equals(sinkId), Battery.getFeature(),
				TreeInfo.getFeature());
	}

	public _CollectionTupleReader getTupleReader(Tuple tuple) {
		Tuple pattern = new Tuple();
		pattern.add(new Field().actualField(new Uint8(Constants.MSG_TYPE)));
		pattern.add(new Field().dontCareField(new Uint16()));
		pattern.add(new Field().dontCareField(new Uint16()));
		pattern.add(new Field().dontCareField(new Uint8Array(
				Properties.TUPLE_MSG_PAYLOAD_SIZE)));
		if (pattern.matches(tuple)) {
			short[] data = ((Uint8Array) tuple.get(3).getValue())
					.serializeValue();
			short type = data[0];
			switch (type) {
			case Constants.ACCELERATION:
				return new TupleReaderAcceleration();
			case Constants.CO:
				return new TupleReaderCO();
			case Constants.CO2:
				return new TupleReaderCO2();
			case Constants.DUST:
				return new TupleReaderDust();
			case Constants.HUMIDITY:
				return new TupleReaderHumidity();
			case Constants.MAGNETIC:
				return new TupleReaderMagnetic();
			case Constants.MICROPHONE:
				return new TupleReaderMicrophone();
			case Constants.NODE_INFO_TYPE:
				return new TupleReaderNodeInfo();
			case Constants.PRESENCE:
				return new TupleReaderPresence();
			case Constants.PRESSURE:
				return new TupleReaderPressure();
			case Constants.SOLAR_LIGHT:
				return new TupleReaderSolarLight();
			case Constants.SYNTH_LIGHT:
				return new TupleReaderSynthLight();
			case Constants.TEMPERATURE:
				return new TupleReaderTemperature();
			case Constants.TILT:
				return new TupleReaderTilt();
			default:
				return null;
			}
		}
		return null;
	}

	public BufferedImage getBackgroundImage() {
		try {
			ClassLoader cl = this.getClass().getClassLoader();
			return ImageIO.read(cl
					.getResource("tl/apps/office/gui/images/office.jpg"));
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	public Vector<_ChartPanel> getChartPanels(_CollectionFeature feature) {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		if (feature.equals(Acceleration.getFeature())) {
			charts.add(Acceleration.getChartPanel(this));
		} else if (feature.equals(Battery.getFeature())) {
			charts.add(Battery.getChartPanel(this));
		} else if (feature.equals(CO.getFeature())) {
			charts.add(CO.getChartPanel(this));
		} else if (feature.equals(CO2.getFeature())) {
			charts.add(CO2.getChartPanel(this));
		} else if (feature.equals(Dust.getFeature())) {
			charts.add(Dust.getChartPanel(this));
		} else if (feature.equals(Humidity.getFeature())) {
			charts.add(Humidity.getChartPanel(this));
		} else if (feature.equals(Magnetic.getFeature())) {
			charts.add(Magnetic.getChartPanel(this));
		} else if (feature.equals(Microphone.getFeature())) {
			charts.add(Microphone.getChartPanel(this));
		} else if (feature.equals(Presence.getFeature())) {
			charts.add(Presence.getChartPanel(this));
		} else if (feature.equals(Pressure.getFeature())) {
			charts.add(Pressure.getChartPanel(this));
		} else if (feature.equals(SolarLight.getFeature())) {
			charts.add(SolarLight.getChartPanel(this));
		} else if (feature.equals(SynthLight.getFeature())) {
			charts.add(SynthLight.getChartPanel(this));
		} else if (feature.equals(Temperature.getFeature())) {
			charts.add(Temperature.getChartPanel(this));
		} else if (feature.equals(Tilt.getFeature())) {
			charts.add(Tilt.getChartPanel(this));
		}
		return charts;
	}

	public Vector<_ChartPanel> getChartPanels() {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		charts.add(Acceleration.getChartPanel(this));
		charts.add(Battery.getChartPanel(this));
		charts.add(CO.getChartPanel(this));
		charts.add(CO2.getChartPanel(this));
		charts.add(Dust.getChartPanel(this));
		charts.add(Humidity.getChartPanel(this));
		charts.add(Magnetic.getChartPanel(this));
		charts.add(Microphone.getChartPanel(this));
		charts.add(Presence.getChartPanel(this));
		charts.add(Pressure.getChartPanel(this));
		charts.add(SolarLight.getChartPanel(this));
		charts.add(SynthLight.getChartPanel(this));
		charts.add(Temperature.getChartPanel(this));
		charts.add(Tilt.getChartPanel(this));
		return charts;
	}

	public Vector<_CollectionFeatureListener> getSampleFeatureListeners(
			_CollectionFeature feature) {
		Vector<_CollectionFeatureListener> ret = new Vector<_CollectionFeatureListener>();
		if (feature.equals(Acceleration.getFeature())) {
			ret.add(acceleration);
		} else if (feature.equals(Battery.getFeature())) {
			ret.add(battery);
		} else if (feature.equals(CO.getFeature())) {
			ret.add(co);
		} else if (feature.equals(CO2.getFeature())) {
			ret.add(co2);
		} else if (feature.equals(Dust.getFeature())) {
			ret.add(dust);
		} else if (feature.equals(Humidity.getFeature())) {
			ret.add(humidity);
		} else if (feature.equals(Magnetic.getFeature())) {
			ret.add(magnetic);
		} else if (feature.equals(Microphone.getFeature())) {
			ret.add(microphone);
		} else if (feature.equals(Presence.getFeature())) {
			ret.add(presence);
		} else if (feature.equals(Pressure.getFeature())) {
			ret.add(pressure);
		} else if (feature.equals(SolarLight.getFeature())) {
			ret.add(solarLight);
		} else if (feature.equals(SynthLight.getFeature())) {
			ret.add(synthLight);
		} else if (feature.equals(Temperature.getFeature())) {
			ret.add(temperature);
		} else if (feature.equals(Tilt.getFeature())) {
			ret.add(tilt);
		} else if (feature.equals(TreeInfo.getFeature())) {
			ret.add(treeInfo);
		}
		return ret;
	}

	public _CollectionGUISourceDescriptor getSourceDescriptor() {
		return sourceDescriptor;
	}

	public Vector<_CollectionSamplesMsgListener> getSampleMsgListeners() {
		Vector<_CollectionSamplesMsgListener> ret = new Vector<_CollectionSamplesMsgListener>();
		ret.add(guiManager);
		return ret;
	}

	public void setSerial(SerialComm serial) {
		tasker.setSerial(serial);
	}

	public void start() {
		guiManager.activate();
	}

	public void stop() {
		guiManager.deactivate();
	}

	public Vector<_GUIDisseminator> getDisseminators() {
		Vector<_GUIDisseminator> panels = new Vector<_GUIDisseminator>();
		panels.add(tasker);
		return panels;
	}
}
