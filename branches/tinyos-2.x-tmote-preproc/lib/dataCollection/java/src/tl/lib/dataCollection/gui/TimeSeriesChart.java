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
 * *	$Id: TimeSeriesChart.java 758 2009-03-28 12:26:44Z mceriotti $
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

import java.awt.BasicStroke;
import java.util.Iterator;
import java.util.Vector;

import org.jfree.chart.ChartPanel;
import org.jfree.chart.ChartRenderingInfo;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.DateAxis;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.labels.StandardXYToolTipGenerator;
import org.jfree.chart.labels.XYToolTipGenerator;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYItemRenderer;
import org.jfree.chart.renderer.xy.XYLineAndShapeRenderer;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

import tl.lib.dataCollection.data.SourceId;

public class TimeSeriesChart extends ChartPanel implements _ChartPanel {

	private JFreeChart chart;
	private XYSeriesCollection collection;
	private _CollectionGUIScenario scenario;
	private String description;
	private String label;
	private Vector<SourceId> selected;
	private ChartRenderingInfo renderingInfo;
	private _CollectionGUISourceDescriptor sourceDescriptor;
	private XYPlot plot;
	private boolean default_all;

	public TimeSeriesChart(_CollectionGUIScenario scenario, String label,
			String description, String labelAxisY) {
		super(null);
		this.sourceDescriptor = scenario.getSourceDescriptor();
		this.collection = new XYSeriesCollection();

		// ChartTheme currentTheme = new StandardChartTheme("JFree");
		ValueAxis timeAxis = new DateAxis("Time");
		timeAxis.setLowerMargin(0.02); // reduce the default margins
		timeAxis.setUpperMargin(0.02);
		NumberAxis valueAxis = new NumberAxis(labelAxisY);
		valueAxis.setAutoRangeIncludesZero(false); // override default

		XYToolTipGenerator toolTipGenerator = null;
		toolTipGenerator = StandardXYToolTipGenerator.getTimeSeriesInstance();

		XYLineAndShapeRenderer renderer = new XYLineAndShapeRenderer(true,
				false);
		// XYURLGenerator urlGenerator = new StandardXYURLGenerator();
		renderer.setBaseToolTipGenerator(toolTipGenerator);
		// renderer.setURLGenerator(urlGenerator);

		this.plot = new XYPlot(collection, timeAxis, valueAxis, renderer);

		this.chart = new JFreeChart(null, JFreeChart.DEFAULT_TITLE_FONT, plot,
				true);
		// currentTheme.apply(chart);

		renderingInfo = new ChartRenderingInfo();

		this.scenario = scenario;
		this.description = description;
		this.label = label;
		this.selected = new Vector<SourceId>();
		default_all = true;
		super.setChart(chart);
	}

	public void addSource(SourceId sourceId) {
		default_all = false;
		if (!selected.contains(sourceId)) {
			selected.add(sourceId);
		}
	}

	public void deleteSource(SourceId sourceId) {
		default_all = false;
		if (selected.contains(sourceId)) {
			int index = collection.indexOf(sourceId);
			if (index >= 0)
				collection.removeSeries(index);
			selected.remove(sourceId);
		}
	}

	public void deleteSources() {
		default_all = false;
		selected.clear();
		collection.removeAllSeries();
	}

	public String description() {
		return description;
	}

	public String label() {
		return label;
	}

	public void addPoint(SourceId sourceId, double x, double y) {
		if (default_all && !selected.contains(sourceId))
			selected.add(sourceId);
		if (selected.contains(sourceId)) {
			if (collection.indexOf(sourceId) < 0) {
				XYSeries series = new XYSeries(sourceId);
				collection.addSeries(series);
				XYItemRenderer renderer = plot.getRenderer();
				renderer.setSeriesPaint(collection.indexOf(sourceId),
						sourceDescriptor.getColor(sourceId));
				BasicStroke wideLine = new BasicStroke(2.0f);
				renderer
						.setSeriesStroke(collection.indexOf(sourceId), wideLine);
			}
			collection.getSeries(sourceId).add(x, y);
		}
	}

	public void clearChart(SourceId sourceId) {
		if (collection.indexOf(sourceId) >= 0) {
			collection.getSeries(sourceId).clear();
		}
	}

	public void clearChart() {
		Iterator it = collection.getSeries().iterator();
		while (it.hasNext()) {
			XYSeries s = (XYSeries) it.next();
			s.clear();
		}
	}

}
