/**
 * 
 */
package it.unitn.acube.wp3;

import java.util.MissingResourceException;
import java.util.ResourceBundle;

/**
 * Reads configuration parameters from {@link BUNDLE_NAME}.
 * 
 * @author Stefan Guna
 * 
 */
public class ConfigParameters {

	/** The file where the configuration parameters are located */
	private static final String BUNDLE_NAME = "it.unitn.acube.wp3.gateway";

	private static final ResourceBundle RESOURCE_BUNDLE = ResourceBundle
			.getBundle(BUNDLE_NAME);

	public static String getProperty(String key) {
		try {
			return RESOURCE_BUNDLE.getString(key);
		} catch (MissingResourceException e) {
			return '!' + key + '!';
		}
	}
}