/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1015 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:15:23 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: GUIScenarioTunnel.java 1015 2010-01-11 08:15:23Z mceriotti $
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

package tl.apps.tunnel.gui;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Vector;

import javax.imageio.ImageIO;

import tl.apps.tunnel.Battery;
import tl.apps.tunnel.Constants;
import tl.apps.tunnel.IR;
import tl.apps.tunnel.MeanLight;
import tl.apps.tunnel.MeanTemperature;
import tl.apps.tunnel.Parent;
import tl.apps.tunnel.ParentQuality;
import tl.apps.tunnel.Properties;
import tl.apps.tunnel.StdDevLight;
import tl.apps.tunnel.StdDevTemperature;
import tl.apps.tunnel.Temperature;
import tl.apps.tunnel.TreeInfo;
import tl.apps.tunnel.TupleReaderIR;
import tl.apps.tunnel.TupleReaderInfos;
import tl.apps.tunnel.TupleReaderLT;
import tl.apps.tunnel.TupleReaderNodeInfo;
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

public class GUIScenarioTunnel implements _CollectionGUIScenario {

	private _CollectionTupleReader ltTupleReader;
	private _CollectionTupleReader irTupleReader;
	private _CollectionTupleReader nodeInfoTupleReader;
	private TupleReaderInfos infosTupleReader;
	private _CollectionGUISourceDescriptor sourceDescriptor;
	private GUIManager guiManager;
	private Battery battery;
	private MeanLight meanLight;
	private MeanTemperature meanTemperature;
	private StdDevLight stdDevLight;
	private StdDevTemperature stdDevTemperature;
	private Temperature temperature;
	private TreeInfo treeInfo;

	// private IR ir;

	public GUIScenarioTunnel() {
		this.guiManager = new GUIManager(this);
		this.ltTupleReader = new TupleReaderLT();
		this.irTupleReader = new TupleReaderIR();
		this.nodeInfoTupleReader = new TupleReaderNodeInfo();
		this.infosTupleReader = new TupleReaderInfos();
		this.sourceDescriptor = new GUISourceDescriptorTunnel();
		this.battery = new Battery(true);
		this.meanLight = new MeanLight(true);
		this.meanTemperature = new MeanTemperature(false);
		this.stdDevLight = new StdDevLight(false);
		this.stdDevTemperature = new StdDevTemperature(false);
		this.treeInfo = new TreeInfo(true);
		this.temperature = new Temperature(true);
		// this.ir = new IR(true);
		SourcesManager.addSource(this, new SourceId(Properties.SINK_ADDRESS));
	}

	public Source createSource(SourceId id) {
		SourceId sinkId = new SourceId(Properties.SINK_ADDRESS);
		return new GUISourceTunnel(id, id.equals(sinkId), Battery.getFeature(),
				TreeInfo.getFeature(), Parent.getFeature(), ParentQuality
						.getFeature());
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
			case 0:
				if (data[1] == Constants.SAMPLE_TYPE_IDENTIFIER)
					return this.ltTupleReader;
				else if (data[1] == Constants.INFO_TYPE_IDENTIFIER)
					return this.infosTupleReader;
				else if (data[1] == Constants.IR_SAMPLE_TYPE_IDENTIFIER)
					return this.irTupleReader;
				else
					break;
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
					.getResource("tl/apps/tunnel/gui/images/pontealto.png"));
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	public Vector<_ChartPanel> getChartPanels(_CollectionFeature feature) {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		if (feature.equals(Battery.getFeature())) {
			charts.add(Battery.getChartPanel(this));
		} else if (feature.equals(MeanLight.getFeature())) {
			charts.add(MeanLight.getChartPanel(this));
		} else if (feature.equals(MeanTemperature.getFeature())) {
			charts.add(MeanTemperature.getChartPanel(this));
		} else if (feature.equals(StdDevLight.getFeature())) {
			charts.add(StdDevLight.getChartPanel(this));
		} else if (feature.equals(StdDevTemperature.getFeature())) {
			charts.add(StdDevTemperature.getChartPanel(this));
		} else if (feature.equals(Temperature.getFeature())) {
			charts.add(Temperature.getChartPanel(this));
		} else if (feature.equals(IR.getFeature())) {
			charts.add(IR.getChartPanel(this));
		}
		return charts;
	}

	public Vector<_ChartPanel> getChartPanels() {
		Vector<_ChartPanel> charts = new Vector<_ChartPanel>();
		charts.add(Battery.getChartPanel(this));
		charts.add(MeanLight.getChartPanel(this));
		// charts.add(StdDevLight.getChartPanel(this));
		// charts.add(MeanTemperature.getChartPanel(this));
		// charts.add(StdDevTemperature.getChartPanel(this));
		charts.add(Temperature.getChartPanel(this));
		// charts.add(IR.getChartPanel(this));
		return charts;
	}

	public Vector<_CollectionFeatureListener> getSampleFeatureListeners(
			_CollectionFeature feature) {
		Vector<_CollectionFeatureListener> ret = new Vector<_CollectionFeatureListener>();
		if (feature.equals(Battery.getFeature())) {
			ret.add(battery);
		} else if (feature.equals(MeanLight.getFeature())) {
			ret.add(meanLight);
		} else if (feature.equals(StdDevLight.getFeature())) {
			ret.add(stdDevLight);
		} else if (feature.equals(MeanTemperature.getFeature())) {
			ret.add(meanTemperature);
		} else if (feature.equals(StdDevTemperature.getFeature())) {
			ret.add(stdDevTemperature);
		} else if (feature.equals(TreeInfo.getFeature())) {
			ret.add(treeInfo);
		} else if (feature.equals(Temperature.getFeature())) {
			ret.add(temperature);
			// } else if (feature.equals(IR.getFeature())) {
			// ret.add(ir);
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

	public void setSerial(SerialComm receiver) {

	}

	public void start() {
		guiManager.activate();
	}

	public void stop() {
		guiManager.deactivate();
	}
}
