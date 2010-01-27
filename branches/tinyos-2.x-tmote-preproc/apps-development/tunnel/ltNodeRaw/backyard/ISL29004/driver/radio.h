/* Project:		T.R.I.T.On
 * Authors:		Carloalberto Torghele
 * Date last modified:  22/09/2008
 */

/* 
 * Test application for the ISL29004 sensor's driver (release 1.5)
 */

#ifndef RADIO_H
#define RADIO_H

enum {
  AM_RADIO = 6,
};

typedef nx_struct RadioMsg {
  nx_uint16_t sensor1;
  nx_uint16_t sensor2;
  nx_uint16_t sensor3;
  nx_uint16_t sensor4;
} RadioMsg;

#endif
