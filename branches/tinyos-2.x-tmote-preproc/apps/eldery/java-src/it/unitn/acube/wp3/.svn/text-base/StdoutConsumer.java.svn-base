/**
 * 
 */
package it.unitn.acube.wp3;

/**
 * A consumer of WSN events that outputs to {@link System#out}.
 * 
 * @author Stefan Guna
 * 
 */
public class StdoutConsumer implements WSNEventsConsumer {

	/*
	 * (non-Javadoc)
	 * 
	 * @see it.unitn.acube.wp3.WSNEventsConsumer#fall(java.lang.String,
	 * java.lang.String)
	 */
	public void fall(String id, String location) {
		System.out.println(id + " took a fall in " + location + ".");
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see it.unitn.acube.wp3.WSNEventsConsumer#immobile(java.lang.String,
	 * java.lang.String)
	 */
	public void immobile(String id, String location) {
		System.out.println(id + " is immobile in " + location + ".");
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see it.unitn.acube.wp3.WSNEventsConsumer#proximity(java.lang.String,
	 * java.lang.String, java.lang.String)
	 */
	public void proximity(String id, String location, String anchorCode) {
		System.out.println(id + " is close to " + anchorCode + ".");
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see it.unitn.acube.wp3.WSNEventsConsumer#translocation(java.lang.String,
	 * java.lang.String, java.lang.String)
	 */
	public void translocation(String id, String oldLocation, String newLocation) {
		System.out.println(id + " moved from " + oldLocation + " to "
				+ newLocation + ".");
	}

}
