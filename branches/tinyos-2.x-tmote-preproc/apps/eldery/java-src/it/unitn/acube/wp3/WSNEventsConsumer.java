/**
 * 
 */
package it.unitn.acube.wp3;

/**
 * The interface for a consumer of events generated by the WSN.
 * 
 * @author Stefan Guna
 * 
 */
public interface WSNEventsConsumer {
	/**
	 * Used to signal that a monitored subject node took a fall.
	 * 
	 * @param id
	 *            The ID of the monitored subject node taking the fall.
	 * @param location
	 *            The last known location of the monitored subject.
	 */
	public void fall(String id, String location);

	/**
	 * Used to signal that a monitored subject is immobile.
	 * 
	 * @param id
	 *            The ID of the monitored subject.
	 * @param locationCode
	 *            The last known location code of the monitored subject.
	 */
	public void immobile(String id, String locationCode);

	/**
	 * Used to signal that a monitored subject is close to an area of interest.
	 * 
	 * @param id
	 *            The ID of the monitored subject.
	 * @param locationCode
	 *            The last known location code of the monitored subject.
	 * @param anchorCode
	 *            The anchor with respect to which proximity is detected.
	 */
	public void proximity(String id, String locationCode, String anchorCode);

	/**
	 * Used to signal that a monitored subject is moving from one area to
	 * another.
	 * 
	 * @param id
	 *            The ID of the monitored subject.
	 * @param oldLocation
	 *            The area code from which the subject is moving.
	 * @param newLocation
	 *            The area code to which the subject is moving.
	 */
	public void translocation(String id, String oldLocation, String newLocation);
}