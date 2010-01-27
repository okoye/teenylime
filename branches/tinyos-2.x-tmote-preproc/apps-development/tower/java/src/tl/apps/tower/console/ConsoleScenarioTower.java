/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 975 $
 * * DATE
 * *    $LastChangedDate: 2009-12-03 00:55:45 -0600 (Thu, 03 Dec 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: ConsoleScenarioTower.java 975 2009-12-03 06:55:45Z mceriotti $
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

package tl.apps.tower.console;

import java.io.File;
import java.util.Vector;

import net.tinyos.message.Message;

import tl.apps.tower.Battery;
import tl.apps.tower.Constants;
import tl.apps.tower.Deformation;
import tl.apps.tower.Humidity;
import tl.apps.tower.Light;
import tl.apps.tower.Properties;
import tl.apps.tower.SolarLight;
import tl.apps.tower.SourceDescriptorTower;
import tl.apps.tower.SourceTower;
import tl.apps.tower.SynthLight;
import tl.apps.tower.Temperature;
import tl.apps.tower.TreeInfo;
import tl.apps.tower.TupleReaderDT;
import tl.apps.tower.TupleReaderNodeInfo;
import tl.apps.tower.TupleReaderTHL;
import tl.apps.tower.TupleReaderTL;
import tl.apps.tower.TupleReaderVibration;
import tl.apps.tower.Vibration;
import tl.common.serial.HeaderConstants;
import tl.common.serial.SerialComm;
import tl.common.serial.TupleMsgHeader;
import tl.common.types.Field;
import tl.common.types.Tuple;
import tl.common.types.Uint16;
import tl.common.types.Uint8;
import tl.common.types.Uint8Array;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionFeatureListener;
import tl.lib.dataCollection._CollectionSamplesMsgListener;
import tl.lib.dataCollection._CollectionScenario;
import tl.lib.dataCollection._CollectionSourceDescriptor;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.console.StatsLogWriter;
import tl.lib.dataCollection.console.UnknownTupleReader;
import tl.lib.dataCollection.data.Source;
import tl.lib.dataCollection.data.SourceId;
import tl.lib.dataDissemination.console.DisseminationManager;
import tl.lib.dataDissemination.console._ConsoleDisseminator;
import tl.lib.dataDissemination.console._DisseminationConsoleScenario;

public class ConsoleScenarioTower implements _CollectionScenario,
		_DisseminationConsoleScenario {

	private TupleReaderTHL thlTupleReader;
	private TupleReaderTL tlTupleReader;
	private TupleReaderNodeInfo nodeInfoTupleReader;
	private TupleReaderVibration vibrationTupleReader;
	private TupleReaderDT dtTupleReader;
	private UnknownTupleReader unknownTupleReader;
	private Battery battery;
	private Deformation deformation;
	private Humidity humidity;
	private Light light;
	private SolarLight solarLight;
	private SynthLight synthLight;
	private Temperature temperature;
	private TreeInfo treeInfo;
	private Vibration vibration;
	private StatsLogWriter statsLogWriter;
	private DisseminationManager taskManager;

	public ConsoleScenarioTower() {
		this.thlTupleReader = new TupleReaderTHL();
		this.thlTupleReader.setDir(Properties.LOG_DIR_NAME);
		this.thlTupleReader.setLog(Properties.LOG_MESSAGES);
		this.tlTupleReader = new TupleReaderTL();
		this.tlTupleReader.setDir(Properties.LOG_DIR_NAME);
		this.tlTupleReader.setLog(Properties.LOG_MESSAGES);
		this.nodeInfoTupleReader = new TupleReaderNodeInfo();
		this.nodeInfoTupleReader.setDir(Properties.LOG_DIR_NAME);
		this.nodeInfoTupleReader.setLog(Properties.LOG_MESSAGES);
		this.vibrationTupleReader = new TupleReaderVibration();
		this.vibrationTupleReader.setDir(Properties.LOG_DIR_NAME);
		this.vibrationTupleReader.setLog(Properties.LOG_MESSAGES);
		this.dtTupleReader = new TupleReaderDT();
		this.dtTupleReader.setDir(Properties.LOG_DIR_NAME);
		this.dtTupleReader.setLog(Properties.LOG_MESSAGES);
		this.unknownTupleReader = new UnknownTupleReader(true,
				Properties.LOG_DIR_NAME);
		this.statsLogWriter = new StatsLogWriter(this, Properties.LOG_DIR_NAME,
				false);
		this.taskManager = new DisseminationManager(this);
		this.battery = new Battery(Properties.LOG_DIR_NAME, false);
		this.deformation = new Deformation(Properties.LOG_DIR_NAME, false);
		this.humidity = new Humidity(Properties.LOG_DIR_NAME, false);
		this.light = new Light(Properties.LOG_DIR_NAME, false);
		this.solarLight = new SolarLight(Properties.LOG_DIR_NAME, false);
		this.synthLight = new SynthLight(Properties.LOG_DIR_NAME, false);
		this.temperature = new Temperature(Properties.LOG_DIR_NAME, false);
		this.treeInfo = new TreeInfo(Properties.LOG_DIR_NAME, false);
		this.vibration = new Vibration(Properties.LOG_DIR_NAME, false);
	}

	public Source createSource(SourceId id) {
		SourceId sink = new SourceId(Properties.SINK_ADDRESS);
		return new SourceTower(id, id.equals(sink), Battery.getFeature(),
				TreeInfo.getFeature());
	}

	public Vector<_CollectionFeatureListener> getSampleFeatureListeners(
			_CollectionFeature feature) {
		Vector<_CollectionFeatureListener> ret = new Vector<_CollectionFeatureListener>();
		if (feature.equals(Battery.getFeature())) {
			ret.add(battery);
		} else if (feature.equals(Deformation.getFeature())) {
			ret.add(deformation);
		} else if (feature.equals(Humidity.getFeature())) {
			ret.add(humidity);
		} else if (feature.equals(Light.getFeature())) {
			ret.add(light);
		} else if (feature.equals(SolarLight.getFeature())) {
			ret.add(solarLight);
		} else if (feature.equals(SynthLight.getFeature())) {
			ret.add(synthLight);
		} else if (feature.equals(Temperature.getFeature())) {
			ret.add(temperature);
		} else if (feature.equals(TreeInfo.getFeature())) {
			ret.add(treeInfo);
		} else if (feature.equals(Vibration.getFeature())) {
			ret.add(vibration);
		}
		return ret;
	}

	public _CollectionSourceDescriptor getSourceDescriptor() {
		return new SourceDescriptorTower();
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
			int type = (data[0] << 8) + data[1];
			switch (type) {
			case Constants.TEMP_LIGHT_TYPE:
			case Constants.TEMP_LIGHT_END_SESSION:
				return tlTupleReader;
			case Constants.TEMP_HUM_LIGHT_TYPE:
			case Constants.TEMP_HUM_LIGHT_END_SESSION:
				return thlTupleReader;
			case Constants.DT_TYPE:
			case Constants.DT_END_SESSION:
				return dtTupleReader;
			case Constants.VIBRATION_TYPE:
			case Constants.VIBRATION_END_SESSION:
				return vibrationTupleReader;
			case Constants.NODE_INFO_TYPE:
				return nodeInfoTupleReader;
			default:
				return unknownTupleReader;
			}
		}
		return unknownTupleReader;
	}

	public Vector<_CollectionSamplesMsgListener> getSampleMsgListeners() {
		Vector<_CollectionSamplesMsgListener> ret = new Vector<_CollectionSamplesMsgListener>();
		ret.add(this.statsLogWriter);
		return ret;
	}

	public void setSerial(SerialComm serial) {
		taskManager.setSerialComm(serial);
	}

	public void start() {
		taskManager.activate();
	}

	public void stop() {
		taskManager.deactivate();
	}

	public Vector<_ConsoleDisseminator> getDisseminators() {
		Vector<_ConsoleDisseminator> taskers = new Vector<_ConsoleDisseminator>();
		taskers.add(new TaskerDT());
		taskers.add(new TaskerTHL());
		taskers.add(new TaskerTL());
		taskers.add(new TaskerVibration());
		taskers.add(new TaskerSynch());
		taskers.add(new TaskerTree());
		return taskers;
	}

	public boolean isResettable() {
		return true;
	}

	public Message getResetMessage() {
		TupleMsgHeader reset = new TupleMsgHeader();
		reset.set_operation(HeaderConstants.CTRL_RESET);
		return reset;
	}
}
