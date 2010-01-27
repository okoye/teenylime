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
 * A timer multiplexing service.
 * 
 * @author Stefan Guna
 *         <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>
 * 
 */

#include "vtimer.h"

generic module VolatileTimerM(int size) {
  uses {
    interface Boot;
    interface Timer<TMilli> as InternalTimer;
  }

  provides interface VolatileTimer;
}

implementation {
  uint32_t wait[size];
  uint32_t delay;
  bool running = FALSE;

  
  int find_placeholder()
  {
    int i;
    for (i = 0; i < size; i++)
      if (wait[i] == DISABLED)
        return i;
    mydbg("volatile-timer", "queue full (size = %d)\n", size);
    return -1;
  }
  

  event void Boot.booted()
  {
    int i;
    for (i = 0; i < size; i++)
      wait[i] = DISABLED;
    delay = 0;
  }

  event void InternalTimer.fired()
  {
    int i;
    uint32_t dt = call InternalTimer.getdt();
    uint32_t min_wait = DISABLED;

    running = FALSE;
    mydbg("volatile-timer", "volatile timer fired at %u\n", sim_time()); 
    for (i = 0; i < size; i++) {
      if (wait[i] == DISABLED)
        continue;

      wait[i] -= delay;

      if (wait[i] > dt) {
        wait[i] -= dt;
        if (wait[i] < min_wait)
          min_wait = wait[i];
        continue;
      }

      wait[i] = DISABLED;
      signal VolatileTimer.fired(i);
    }

    delay = 0;
    if (min_wait != DISABLED) {
      running = TRUE;
      call InternalTimer.startOneShot(min_wait);
    }
  }


  command int VolatileTimer.addTask(uint32_t wait_time)
  {
    uint32_t elapsed, remaining;
    int id = find_placeholder();
    if (id == -1)
      return -1;
    
    if (!running) {
      wait[id] = wait_time;
      delay = 0;
      mydbg("volatile-timer", "waiting %lu\n", wait_time);
      running = TRUE;
      call InternalTimer.startOneShot(wait_time);
      return id;
    }

    elapsed = call InternalTimer.getNow() - call InternalTimer.gett0();
    remaining = call InternalTimer.getdt() - elapsed;
    wait[id] = wait_time + delay + elapsed;
    
    if (wait_time < remaining) {
      mydbg("volatile-timer", "waiting 2 %lu\n", wait_time);
      running = TRUE;
      call InternalTimer.startOneShot(wait_time);
      delay += elapsed;
    }
    return id;
  }
  
  
  command error_t VolatileTimer.resetTask(int id, uint32_t wait_time)
  {
    uint32_t elapsed, remaining;
    if (wait[id] == DISABLED) {
      mydbgerror("volatile-timer", "task %d does not exist\n", id);
      return FAIL;
    }
    
    elapsed = call InternalTimer.getNow() - call InternalTimer.gett0();
    remaining = call InternalTimer.getdt() - elapsed;
    wait[id] = wait_time + delay + elapsed;
    
    if (wait_time < remaining) {
      mydbg("volatile-timer", "waiting 2 %lu\n", wait_time);
      running = TRUE;
      call InternalTimer.startOneShot(wait_time);
      delay += elapsed;
    }
    return SUCCESS;
  }


  command error_t VolatileTimer.stopTask(int id)
  {
    if (wait[id] == DISABLED) {
      mydbgerror("volatile-timer", "task %d does not exist\n", id);
      return FAIL;
    }
    wait[id] = DISABLED;
    return SUCCESS;
  }

  command uint32_t VolatileTimer.remaining(int id)
  {
    uint32_t elapsed;
    if (wait[id] == DISABLED) {
      mydbgerror("volatile-timer", "task %d does not exist\n", id);
      return 0;
    }
    elapsed = call InternalTimer.getNow() - call InternalTimer.gett0();
    return wait[id] - delay - elapsed;
  }
}

