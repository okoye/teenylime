/**
 * 
 */
package it.unitn.acube.wp3.translocation;

import java.util.Hashtable;
import java.util.Set;

/**
 * This class represents an area in a deployment. The area has a number of
 * "links" with other areas, where each link is represented by two sets of
 * sensor nodes: the nodes in this "area" and the nodes in the linked area.
 * 
 * An area can be a room or can mark a hazard area within a room.
 * 
 * @author Stefan Guna
 * 
 */
public class Area {
	public enum Type {
		HAZARD, ROOM;
	}

	private String code;

	/** If this is a {@link Type#ROOM}, this marks the links with other rooms. */
	private Hashtable<Area, Set<Integer>> links;
	private String name;

	/**
	 * If the type is a {@link Type#HAZARD}, the this is the containing room of
	 * the hazard area.
	 */
	private Area parent;

	private Type type;

	protected Area(String name) {
		this.name = new String(name);
		links = new Hashtable<Area, Set<Integer>>();
		code = new String("!" + name + "!");
		type = Type.ROOM;
	}

	protected Area(String name, Area parent) {
		this.name = new String(name);
		this.parent = parent;
		type = Type.HAZARD;
	}

	/**
	 * 
	 * @param other
	 * @param localLinks
	 */
	protected void addLink(Area other, Set<Integer> localLinks) {
		if (links.get(other) == null)
			links.put(other, localLinks);
		else
			links.get(other).addAll(localLinks);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.lang.Object#equals(java.lang.Object)
	 */
	@Override
	public boolean equals(Object obj) {
		if (!(obj instanceof Area))
			return false;
		Area other = (Area) obj;
		if (type != other.type)
			return false;
		if (type == Type.ROOM)
			return name.equals(other.name);
		return name.equals(other.name) && parent.equals(other.parent);
	}

	/**
	 * @return the code
	 */
	public String getCode() {
		return code;
	}

	/**
	 * @return the name
	 */
	protected String getName() {
		if (type == Type.HAZARD)
			return name + "@" + parent.getName();
		return name;
	}

	protected Area getNeighbor(Integer node) {
		if (links == null)
			return null;
		for (Area area : links.keySet())
			if (links.get(area).contains(node))
				return area;
		return null;
	}

	/**
	 * @return the parent
	 */
	public Area getParent() {
		return parent;
	}

	/**
	 * Tells whether this room contains the given node.
	 * 
	 * @param node
	 *            Node to test.
	 * @return true if this room contains the given node, false otherwise.
	 */
	protected boolean hasLinkNode(Integer node) {
		if (links == null)
			return false;
		for (Set<Integer> nodes : links.values())
			if (nodes.contains(node))
				return true;
		return false;
	}

	/** Tells whether this area is a hazard area */
	protected boolean isHazard() {
		return type == Type.HAZARD;
	}

	/**
	 * @param code
	 *            the code to set
	 */
	public void setCode(String code) {
		this.code = code;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		if (type == Type.HAZARD)
			return name + "@" + parent.name;
		return name;
	}
}
