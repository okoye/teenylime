/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  09/11/2009
 */
// Interface for the ISL29004 sensor (infrared version)
interface ISL29004Control
{
  /**
   * Start this component and all of its subcomponents.
   *
   * @return a byte where the 4 lsb signal if the requested sensors started.
   bit0 = 0 means that sensor 1 started whether bit0=1 means that an error has been occurred (or that sensor1 has not been selected)
   bit1 = 0 means that sensor 2 started whether bit1=1 means that an error has been occurred (or that sensor2 has not been selected)
   bit2 = 0 means that sensor 3 started whether bit2=1 means that an error has been occurred (or that sensor3 has not been selected)
   bit3 = 0 means that sensor 4 started whether bit3=1 means that an error has been occurred (or that sensor4 has not been selected)
   */
  command uint8_t start(uint8_t set_sensors);

  /**
   * @return SUCCESS if the component was either already off or was 
   *         successfully turned off<br>
   *         FAIL otherwise
   */
  command error_t stop();
}
