/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  09/11/2009
 */
// Interface for the ISL29004 sensor (infrared version)
 
interface ISL29004Read<val_t> {
  /**
   * Initiates a read of the value.
   * 
   *@param set_sensors indicates which sensors have to be read:
    bit0 = 1 means that sensor 1 has to be read
    bit1 = 1 means that sensor 2 has to be read
    bit2 = 1 means that sensor 3 has to be read
    bit3 = 1 means that sensor 4 has to be read
    bit4 = 1 means that sensor 1 IR has to be read
    bit5 = 1 means that sensor 2 IR has to be read
    bit6 = 1 means that sensor 3 IR has to be read
    bit7 = 1 means that sensor 4 IR has to be read
   * @return a byte where the 4 lsb signal if a read done event will eventually come back for
   the 4 sensors. 
   bit0 = 0 means that sensor 1 will return a meaningful value whether bit0 = 1 does not.
   bit1 = 0 means that sensor 2 will return a meaningful value whether bit0 = 1 does not.
   bit2 = 0 means that sensor 3 will return a meaningful value whether bit0 = 1 does not.
   bit3 = 0 means that sensor 4 will return a meaningful value whether bit0 = 1 does not.
   */
  command uint8_t read(uint8_t set_sensors);

  /**
   * Signals the completion of the read().
   *
   * @param result indicates if the reading process succeded:
   bit0 = 0 means that sensor 1 has been read correctly while bit0 = 1 means that an error occurred (or that sensor1 wasn't selected for the reading)
   bit1 = 0 means that sensor 2 has been read correctly while bit0 = 1 means that an error occurred (or that sensor2 wasn't selected for the reading)
   bit2 = 0 means that sensor 3 has been read correctly while bit0 = 1 means that an error occurred (or that sensor3wasn't selected for the reading)
   bit3 = 0 means that sensor 4 has been read correctly while bit0 = 1 means that an error occurred (or that sensor4 wasn't selected for the reading)
   * @param val1 the value that has been read from sensor1
		 val2 the value that has been read from sensor2
		 val3 the value that has been read from sensor3
		 val4 the value that has been read from sensor4
		 IRval1 the infrared value that has been read from sensor1
		 IRval2 the infrared value that has been read from sensor2
		 IRval3 the infrared value that has been read from sensor3
		 IRval4 the infrared value that has been read from sensor4
   */
  event void readDone( uint8_t result, val_t val1, val_t val2, val_t val3, val_t val4, val_t IRval1, val_t IRval2, val_t IRval3, val_t IRval4);
}
