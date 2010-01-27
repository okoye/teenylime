/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  18/03/2009
 */

interface ISL29004Control {

  /**
   * Start the sensors specified as argument, 
   * a bit set to 1 indicates a requesto to start a specific sensor.
   */
  command void start(uint8_t set_sensors);

  /**
   * Check the sensor status.
   *
   * @return a byte where the 4 lsb signal the status of a specific sensor, 
   *          0 indicates correct operation
   */
  command uint8_t status();

  /**
   * @return SUCCESS if every correctly operating sensor has been
   *         successfully turned off<br> 
   *         FAIL otherwise
   */
  command error_t stop();
}
