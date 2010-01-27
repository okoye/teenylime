/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 944 $
 * * DATE
 * *    $LastChangedDate: 2009-11-25 09:23:31 +0100 (Wed, 25 Nov 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: TeenyLimeC.nc 944 2009-11-25 08:23:31Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
 * *   as published by the Free Software Foundation; either version 2
 * *   of the License, or (at your option) any later version.
 * *
 * *   This program is distributed in the hope that it will be useful,
 * *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 * *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * *   GNU General Public License for more details.
 * *
 * *   You should have received a copy of the GNU General Public License
 * *   along with this program; if not, you may find a copy at the FSF web
 * *   site at 'www.gnu.org' or 'www.fsf.org', or you may write to the
 * *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * *   Boston, MA  02111-1307, USA
 ***/

/**
 * 
 * @author Gianalberto Chini
 * <a href="mailto:gianalberto.chini@gmail.com">gianalberto.chini@gmail.com</a>
 * 
 */
#ifndef __POSTUREDETECTION_H
#define __POSTUREDETECTION_H

enum {
  //----------------- VOLTAGE SPEC ----------------------

  // Peroiod of voltage uploading
  //   notice that from this parameter depends the begin
  //   sense timer
  VOLT_PERIOD_CHECK = 3000,

  // Reference voltage used to reweight the others voltages
  V_REF_MEASURE=2374,

  VX_AT_0G=2310,
  VY_AT_0G=2174,	
  VZ_AT_0G=2331,

  //----------------- BUFFER ----------------------
  /* sampling period. */
  SAMPLING_PERIOD = 10, //256

  /* size of circular storing sampling buffer 
     This value derermines the lenght of history
     buffer
     The history time is calculated as 
     SIZE_HISTROY_BUFFER / SAMPLING_PERIOD
     */
  SIZE_HISTROY_BUFFER = 3,

  //----------------- IMMOBILITY DETECTION ------------

  //Period used to check the immobility
  //  if in this period all the measumements of all axes
  //  has a difference not greater than IMM_MAX_WIDTH_STRIP
  //  then the person is condidered immobile  
  IMM_PERIOD_CHECK = 5000,
  IMM_MAX_WIDTH_STRIP=40,


  //----------------- HORIZZ_TO_THE_GROUND ------------

  // ==== !!! WARNING !!!!!! WARNING !!!!!! WARNING !!! ====
  //   Read the part of this file releted to fall detction before
  //   modify this fields  

  /* call of test function period */
  HORIZ_TEST_PERIOD = 1000,

  /* These are the trashold used to understand if the posture 
   *   is horizzontal to the ground.
   * If the acceleration a measurament is between this values
   *   then the posture is considered horizzontal to the gorund.
   */
  HORIZ_UPPERTHR_X = 2456,
  HORIZ_LOWERTHR_X = 2165,
  HORIZ_UPPERTHR_Y = 2317,
  HORIZ_LOWERTHR_Y = 2030,
  HORIZ_UPPERTHR_Z = 2475,
  HORIZ_LOWERTHR_Z = 2186,

  /* This two variables indicates bound of the FSM used to detect 
   *   the horizzontal posture. This is used mainly to avoid the false
   *   measurements or very short variations in the acceleration that  
   *   can be intrepreted as horizzontal posture.
   * When a check is considerd "horizzontal" then the FSM jump to the
   *   state n-1 otherwise jump to the state n+1 until reaches a bound
   */
  HORIZ_POSITIVE_LIMIT = 3,
  HORIZ_NEGATIVE_LIMIT = -3,

  /* Inficates the states of the FSM indicating that the immobility 
   *   was occoured. If the FSM is in a state lower or equal than than 
   */
  HORIZ_LOWER_TH_ALARM = -2,


  //--------------- FALL DETECTION --------------------

  /* 1g is 289 */
  FALL_2G_SQUARED = 334150, //334150 = 578^2

  // Time after a fall in witch the posture is analized
  //   ==== !!! WARNING !!!!!! WARNING !!!!!! WARNING !!! ====
  //   The time must be greater than the time necessary to have
  //   a correct posture analizys (time to check if the position is horizontal) 
  FALL_TIME_CHECK_POS_AFTER_FALL = 10000,

};



#endif
