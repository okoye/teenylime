/**
 * 
 */
package it.unitn.acube.wp3.translocation;

import java.io.IOException;
import java.io.InputStream;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.SchemaFactory;

import org.apache.log4j.Logger;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.DefaultHandler;

/**
 * Parses an xml file describing a collection and returns a collection of the
 * areas found in the deployment. The XML must comply to the specifications in
 * {@link SCHEMA_LOCATION}.
 * 
 * @author Stefan Guna
 * 
 */
public class DeploymentBuilder extends DefaultHandler {
	public static Logger log = Logger.getLogger(DeploymentBuilder.class
			.getName());

	/** The XML Schema for the location XML description */
	private static final String SCHEMA_LOCATION = "deploymentSchema.xsd";

	/**
	 * Reads an XML file describing a deployment.
	 * 
	 * @param filename
	 *            The XML file describing a deployment.
	 * @return A collection of Area objects describing the deployment.
	 * @throws ParserConfigurationException
	 * @throws SAXException
	 * @throws IOException
	 */
	public static Deployment readDeployment(String filename)
			throws ParserConfigurationException, SAXException, IOException {
		DeploymentBuilder builder = new DeploymentBuilder();

		SAXParserFactory factory = SAXParserFactory.newInstance();
		factory.setNamespaceAware(true);
		factory.setValidating(false);

		SchemaFactory schemaFactory = SchemaFactory
				.newInstance("http://www.w3.org/2001/XMLSchema");

		InputStream schemaStream = DeploymentBuilder.class
				.getResourceAsStream(SCHEMA_LOCATION);

		factory.setSchema(schemaFactory
				.newSchema(new Source[] { new StreamSource(schemaStream) }));

		SAXParser parser = factory.newSAXParser();

		parser.parse(filename, builder);
		if (!builder.errorEncountered)
			return builder.deployment;
		return null;
	}

	private Deployment deployment;
	private boolean errorEncountered = false;

	private Area tempArea, tempNeighborArea;

	private HashSet<Integer> tmpLinks;

	private DeploymentBuilder() {
		deployment = new Deployment();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.xml.sax.helpers.DefaultHandler#endElement(java.lang.String,
	 * java.lang.String, java.lang.String)
	 */
	@Override
	public void endElement(String uri, String localName, String qName)
			throws SAXException {
		if (localName.equalsIgnoreCase("link")) {
			log.trace("adding links: " + tempArea.getName() + " -> "
					+ tempNeighborArea.getName() + ": " + tmpLinks);
			tempArea.addLink(tempNeighborArea, tmpLinks);
		}
		if (localName.equalsIgnoreCase("hazard")) {
			log.trace("adding links: " + tempArea.getName() + " -> "
					+ tempNeighborArea.getName() + ": " + tmpLinks);
			tempArea.addLink(tempNeighborArea, tmpLinks);
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.xml.sax.helpers.DefaultHandler#error(org.xml.sax.SAXParseException)
	 */
	@Override
	public void error(SAXParseException e) throws SAXException {
		errorEncountered = true;
		log.error(e.getMessage());
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.xml.sax.helpers.DefaultHandler#fatalError(org.xml.sax.SAXParseException
	 * )
	 */
	@Override
	public void fatalError(SAXParseException e) throws SAXException {
		errorEncountered = true;
		log.fatal(e.getMessage());
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.xml.sax.helpers.DefaultHandler#startElement(java.lang.String,
	 * java.lang.String, java.lang.String, org.xml.sax.Attributes)
	 */
	@Override
	public void startElement(String uri, String localName, String qName,
			Attributes attributes) throws SAXException {

		if (localName.equalsIgnoreCase("actor")) {
			Integer id = new Integer(attributes.getValue("id"));
			String actor = attributes.getValue("name");
			deployment.registerActor(id, actor);
			log.trace("Node " + id + " is bound to actor \"" + actor + "\"");
		}

		if (localName.equalsIgnoreCase("area")) {
			String areaName = attributes.getValue("name");
			tempArea = deployment.newArea(areaName);
			tempArea.setCode(attributes.getValue("code"));
		}

		if (localName.equalsIgnoreCase("link")) {
			String areaName = attributes.getValue("neighbor");
			tempNeighborArea = deployment.newArea(areaName);
			log.trace("found link to " + tempNeighborArea);
			tmpLinks = new HashSet<Integer>();
		}

		if (localName.equalsIgnoreCase("hazard")) {
			String areaName = attributes.getValue("name");
			tempNeighborArea = deployment.newSubArea(areaName, tempArea);
			tempNeighborArea.setCode(attributes.getValue("code"));
			log.trace("found link to " + tempNeighborArea);
			tmpLinks = new HashSet<Integer>();
		}

		if (localName.equalsIgnoreCase("node"))
			tmpLinks.add(new Integer(attributes.getValue("id")));
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.xml.sax.helpers.DefaultHandler#warning(org.xml.sax.SAXParseException)
	 */
	@Override
	public void warning(SAXParseException e) throws SAXException {
		log.warn(e.getMessage());
	}
}
