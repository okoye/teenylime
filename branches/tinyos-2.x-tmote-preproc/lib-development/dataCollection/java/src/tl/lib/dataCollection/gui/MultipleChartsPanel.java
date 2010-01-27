/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 758 $
 * * DATE
 * *    $LastChangedDate: 2009-03-28 07:26:44 -0500 (Sat, 28 Mar 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: MultipleChartsPanel.java 758 2009-03-28 12:26:44Z mceriotti $
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

package tl.lib.dataCollection.gui;

import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.util.Enumeration;
import java.util.Hashtable;

import javax.swing.BorderFactory;
import javax.swing.JPanel;

import org.jfree.chart.ChartPanel;

import tl.lib.dataCollection.data.SourceId;

public class MultipleChartsPanel extends JPanel implements _ChartPanel {

	private Hashtable<Integer, _ChartPanel> charts;
	private _CollectionGUIScenario scenario;
	private String description;
	private String label;
	private GridBagConstraints grid;

	public MultipleChartsPanel(_CollectionGUIScenario scenario, String label,
			String description) {
		super(new GridBagLayout());
		this.charts = new Hashtable<Integer, _ChartPanel>();
		this.scenario = scenario;
		this.description = description;
		this.label = label;
		grid = new GridBagConstraints();
		grid.weighty = 1;
		grid.weightx = 1;
		grid.anchor = GridBagConstraints.PAGE_START;
		grid.fill = GridBagConstraints.BOTH;
	}

	public void addSource(SourceId sourceId) {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).addSource(sourceId);
		}
	}

	public void deleteSource(SourceId sourceId) {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).deleteSource(sourceId);
		}
	}

	public void deleteSources() {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).deleteSources();
		}
	}

	public String description() {
		return description;
	}

	public String label() {
		return label;
	}

	public void addPoint(SourceId sourceId, double x, double y) {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).addPoint(sourceId, x, y);
		}
	}

	public void addChart(int chartIndex, _ChartPanel chart) {
		if (charts.containsKey(new Integer(chartIndex))) {
			remove((ChartPanel) charts.get(new Integer(chartIndex)));
		}
		charts.remove(new Integer(chartIndex));
		charts.put(new Integer(chartIndex), chart);
		grid.gridx = 0;
		grid.gridy = chartIndex - 1;
		grid.gridwidth = 1;
		((ChartPanel) chart).setBorder(BorderFactory.createTitledBorder(chart
				.label()));
		add((ChartPanel) chart, grid);
	}

	public void addPoint(int chartIndex, SourceId sourceId, double x, double y) {
		if (charts.containsKey(new Integer(chartIndex))) {
			charts.get(new Integer(chartIndex)).addPoint(sourceId, x, y);
		}
	}

	public void clearChart(int chartIndex, SourceId sourceId) {
		if (charts.containsKey(new Integer(chartIndex))) {
			charts.get(new Integer(chartIndex)).clearChart(sourceId);
		}
	}

	public void clearCharts(int chartIndex) {
		if (charts.containsKey(new Integer(chartIndex))) {
			charts.get(new Integer(chartIndex)).clearChart();
		}
	}

	public void clearChart(SourceId sourceId) {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).clearChart(sourceId);
		}
	}

	public void clearChart() {
		Enumeration<Integer> keys = charts.keys();
		while (keys.hasMoreElements()) {
			Integer key = keys.nextElement();
			charts.get(key).clearChart();
		}
	}
}
