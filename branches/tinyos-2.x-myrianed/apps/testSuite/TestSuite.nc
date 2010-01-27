/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 41 $
 * * DATE
 * *    $LastChangedDate: 2007-05-30 10:28:32 +0200 (Wed, 30 May 2007) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *  $Id: Benchmark.nc 41 2007-05-30 08:28:32Z lmottola $
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

#include "Constants.h"

/**
 * Configuration file for a test application.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */

// ===== Application options =====

#if defined(LocalRd)
#define TEST_COMPONENTS  components TestLocalRd as App;

#elif defined(LocalIng)
#define TEST_COMPONENTS  components TestLocalIng as App;

#elif defined(MallocFree)
#define TEST_COMPONENTS  components TestMallocFree as App;\
  App.Mem -> TinyMallocC;

#elif defined(LocalIn)
#define TEST_COMPONENTS  components TestLocalIn as App;

#elif defined(LocalIng)
#define TEST_COMPONENTS  components TestLocalIng as App;

#elif defined(OutReaction)
#define TEST_COMPONENTS  components TestOutReaction as App;

#elif defined(NewTuple)
#define TEST_COMPONENTS  components TestNewTuple as App;

#elif defined(OutMix)
#define TEST_COMPONENTS  components TestOutMix as App;

#elif defined(Benchmark) || defined(BenchmarkProfile)
#define TEST_COMPONENTS  components TestBenchmark as App;



#else
#error ======================================================
#error = Please define a test application to compile.
#error = Try:
#error =     export BENCHMARK_NODE=LocalRd
#error = and recompile. Check TestSuite.nc for more options.
#error =======================================================
#endif




configuration TestSuite {
}


implementation {
  components MainC, TeenyLimeC;
  components ActiveMessageC as AM;
  components new TimerMilliC() as Timer0;
  components LedsC;
  components TinyMallocC;

  TEST_COMPONENTS


#define DEFINED_TOS_AM_ADDRESS REACTIVE_NODE

  App.Timer -> Timer0;
  App.TS -> TeenyLimeC.TupleSpace[unique("TL")];
  App.Boot -> MainC.Boot;
  App.TeenyLIMESystem -> TeenyLimeC;
  App.AMPacket -> AM;
  App.TSControl -> TeenyLimeC;
  App.Leds -> LedsC;
}

