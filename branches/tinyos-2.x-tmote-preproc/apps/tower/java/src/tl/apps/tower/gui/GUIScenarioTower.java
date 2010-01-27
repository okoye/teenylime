/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 982 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 05:06:21 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUIScenarioTower.java 982 2009-12-03 11:06:21Z mceriotti $
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

package tl.apps.tower.gui;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Vector;

import javax.imageio.ImageIO;

import tl.apps.tower.Battery;
import tl.apps.tower.Constants;
import tl.apps.tower.Deformation;
import tl.apps.tower.Humidity;
import tl.apps.tower.Light;
import tl.apps.tower.SolarLight;
import tl.apps.tower.SynthLight;
import tl.apps.tower.Temperature;
import tl.apps.tower.TreeInfo;
import tl.apps.tower.TupleReaderDT;
import tl.apps.tower.TupleReaderNodeInfo;
import tl.apps.tower.TupleReaderTHL;
import tl.apps.tower.TupleReaderTL;
import tl.apps.tower.TupleReaderVibration;
import tl.apps.tower.Vibration;
import tl.apps.tower.Properties;
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

public class GUIScenarioTower implements _CollectionGUIScenario,
		_DisseminationGUIScenario {

	// private _CollectionTupleReader thlTupleReader;
	private _CollectionTupleReader tlTupleReader;
	private _CollectionTupleReader nodeInfoTupleReader;
	private _CollectionTupleReader vibrationTupleReader;
	private _CollectionTupleReader dtTupleReader;
	private _GUIDisseminator dtTasker;
	// private _GUIDisseminator thlTasker;
	private _GUIDisseminator tlTasker;
	private _GUIDisseminator vTasker;
	private _CollectionGUISourceDescriptor sourceDescriptor;
	private GUIManager guiManager;
	private Battery battery;
	private Deformation deformation;
	// private Humidity humidity;
	private Light light;
	// private SolarLight solarLight;
	// private SynthLight synthLight;
	private Temperature temperature;
	private TreeInfo treeInfo;
	private Vibration vibration;

	public GUIScenarioTower() {
		this.guiManager = new GUIManager(this);
		// this.thlTupleReader = new TupleReaderTHL();
		this.tlTupleReader = new TupleReaderTL();
		this.nodeInfoTupleReader = new TupleReaderNodeInfo();
		this.vibrationTupleReader = new TupleReaderVibration();
		this.dtTupleReader = new TupleReaderDT();
		this.dtTasker = new TaskPanelDT();
		// this.thlTasker = new TaskPanelTHL();
		this.tlTasker = new TaskPanelTL();
		this.vTasker = new TaskPanelV();
		this.sourceDescriptor = new GUISourceDescriptorTower();
		this.battery = new Battery(true);
		this.deformation = new Deformation(true);
		// this.humidity = new Humidity(true);
		this.light = new Light(true);
		// this.solarLight = new SolarLight(true);
		// this.synthLight = new SynthLight(true);
		this.temperature = new Temperature(true);
		this.treeInfo = new TreeInfo(true);
		this.vibration = new Vibration(true);
		SourcesManager.addSource(this, new SourceId(Properties.SINK_ADDRESS));
	}

	public Source createSource(SourceId id) {
		SourceId sinkId = new SourceId(Properties.SINK_ADDRESS);
		return new GUISourceTower(id, id.equals(sinkId), Battery.getFeature(),
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
			case Constants.TEMP_LIGHT_TYPE:
			case Constants.TEMP_LIGHT_END_SESSION:
				return tlTupleReader;
				// case Constants.TEMP_HUM_LIGHT_TYPE:
				// case Constants.TEMP_HUM_LIGHT_END_SESSION:
				// return thlTupleReader;
			case Constants.DT_TYPE:
			case Constants.DT_END_SESSION:
				return dtTupleReader;
			case Constants.VIBRATION_TYPE:
			case Constants.VIBRATION_END_SESSION:
				return vibrationTupleReader;
			case Constants.NODE_INFO_TYPE:
				return nodeInfoTupleReader;
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
					.getResource("tl/apps/tower/gui/images/tower.jpg"));
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	public Vector<_ChartPanel> getChartPanels(_CollectionFeature feature) {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		if (feature.equals(Battery.getFeature())) {
			charts.add(Battery.getChartPanel(this));
		} else if (feature.equals(Deformation.getFeature())) {
			charts.add(Deformation.getChartPanel(this));
			// } else if (feature.equals(Humidity.getFeature())) {
			// charts.add(Humidity.getChartPanel(this));
		} else if (feature.equals(Light.getFeature())) {
			charts.add(Light.getChartPanel(this));
			// } else if (feature.equals(SolarLight.getFeature())) {
			// charts.add(SolarLight.getChartPanel(this));
			// } else if (feature.equals(SynthLight.getFeature())) {
			// charts.add(SynthLight.getChartPanel(this));
		} else if (feature.equals(Temperature.getFeature())) {
			charts.add(Temperature.getChartPanel(this));
		} else if (feature.equals(Vibration.getFeature())) {
			charts.add(Vibration.getChartPanel(this));
		}
		return charts;
	}

	public Vector<_ChartPanel> getChartPanels() {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		charts.add(Battery.getChartPanel(this));
		charts.add(Deformation.getChartPanel(this));
		// charts.add(Humidity.getChartPanel(this));
		charts.add(Light.getChartPanel(this));
		// charts.add(SolarLight.getChartPanel(this));
		// charts.add(SynthLight.getChartPanel(this));
		charts.add(Temperature.getChartPanel(this));
		charts.add(Vibration.getChartPanel(this));
		return charts;
	}

	public Vector<_CollectionFeatureListener> getSampleFeatureListeners(
			_CollectionFeature feature) {
		Vector<_CollectionFeatureListener> ret = new Vector<_CollectionFeatureListener>();
		if (feature.equals(Battery.getFeature())) {
			ret.add(battery);
		} else if (feature.equals(Deformation.getFeature())) {
			ret.add(deformation);
			// } else if (feature.equals(Humidity.getFeature())) {
			// ret.add(humidity);
		} else if (feature.equals(Light.getFeature())) {
			ret.add(light);
			// } else if (feature.equals(SolarLight.getFeature())) {
			// ret.add(solarLight);
			// } else if (feature.equals(SynthLight.getFeature())) {
			// ret.add(synthLight);
		} else if (feature.equals(Temperature.getFeature())) {
			ret.add(temperature);
		} else if (feature.equals(TreeInfo.getFeature())) {
			ret.add(treeInfo);
		} else if (feature.equals(Vibration.getFeature())) {
			ret.add(vibration);
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
		dtTasker.setSerial(serial);
		// thlTasker.setSerial(serial);
		tlTasker.setSerial(serial);
		vTasker.setSerial(serial);
	}

	public void start() {
		guiManager.activate();
	}

	public void stop() {
		guiManager.deactivate();
	}

	public Vector<_GUIDisseminator> getDisseminators() {
		Vector<_GUIDisseminator> panels = new Vector<_GUIDisseminator>();
		panels.add(dtTasker);
		// panels.add(thlTasker);
		panels.add(tlTasker);
		panels.add(vTasker);
		return panels;
	}
}
