/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  18/03/2009
 */

interface ISL29004Read {

  /**
   * Initiates a read of the value.
   * 
   * @param set_sensors indicates the sensors to be read, a bit set to 
   *                    1 indicates a read from a specific sensor 
   * @return a byte whose 4 lsb signal if a read done is eventually 
   *         signaled for a specific sensor, 
   *         a bit set to 0 indicates so
   */
  command uint8_t read(uint8_t set_sensors);

  /**
   * Signals a read completion.
   *
   * @param result indicates if the reading process succeded, 
   *               setting a specific bit to 0 if the corresponding 
   *               value is meaningful
   * @param val1 the value read from sensor1
   *	    val2 the value read from sensor2
   *        val3 the value read from sensor3
   *        val4 the value read from sensor4
   */
  event void readDone(uint8_t result, 
		      uint16_t val1, uint16_t val2, 
		      uint16_t val3, uint16_t val4);
}
