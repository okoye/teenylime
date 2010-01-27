/**
 * 
 */
package it.unitn.acube.wp3.translocation;

import java.util.HashMap;
import java.util.Hashtable;

import org.apache.log4j.Logger;

/**
 * This class describes a deployment.
 * 
 * @author Stefan Guna
 * 
 */
public class Deployment {
	public static Logger log = Logger.getLogger(Deployment.class.getName());
	private Hashtable<Integer, String> actors;
	private HashMap<String, Area> areas;

	protected Deployment() {
		actors = new Hashtable<Integer, String>();
		areas = new HashMap<String, Area>();
	}

	public String getActor(int nodeId) {
		String actor = actors.get(nodeId);
		if (actor == null)
			return "Actor " + nodeId;
		return actor;
	}

	/**
	 * Finds the room where an anchor node is located.
	 * 
	 * @param nodeId
	 *            ID of anchor node.
	 * @return The room where the {@code nodeId} is located (if {@code nodeId}
	 *         is an actual anchor), {@code null} otherwise.
	 */
	public Area getArea(int nodeId) {
		for (Area area : areas.values())
			if (area.hasLinkNode(nodeId))
				return area;
		return null;
	}

	public Area getArea(String areaName) {
		return areas.get(areaName);
	}

	public Area newArea(String areaName) {
		Area tmp = areas.get(areaName);
		if (tmp != null)
			return tmp;
		tmp = new Area(areaName);
		areas.put(areaName, tmp);
		log.trace("found area " + tmp.getName());
		return tmp;
	}

	public Area newSubArea(String areaName, Area parent) {
		Area tmp = areas.get(areaName + "@" + parent);
		if (tmp != null)
			return tmp;
		tmp = new Area(areaName, parent);
		areas.put(areaName + "@" + parent, tmp);
		log.trace("found sub area " + tmp.getName());
		return tmp;
	}

	public boolean registerActor(int nodeId, String actorCode) {
		if (actors.get(nodeId) != null)
			return false;
		actors.put(nodeId, actorCode);
		return true;
	}

	public void unregisterActor(int nodeId) {
		actors.remove(nodeId);
	}
}
