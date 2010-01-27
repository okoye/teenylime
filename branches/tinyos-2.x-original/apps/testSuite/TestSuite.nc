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
 * *	$Id: Benchmark.nc 41 2007-05-30 08:28:32Z lmottola $
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
 * Configuration file for a benchmark application.
 *
 * @author Luca Mottola
 *         <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>
 *
 */


// ===== Application options =====

#if defined(DistrOut)
#define TEST_COMPONENTS components TestDistrOut as App;

#elif defined(DistrIn)
#define TEST_COMPONENTS  components TestDistrIn as App;

#elif defined(LocalRd)
#define TEST_COMPONENTS  components TestLocalRd as App;

#elif defined(LocalIn)
#define TEST_COMPONENTS  components TestLocalIn as App;

#elif defined(LocalIng)
#define TEST_COMPONENTS  components TestLocalIng as App;

#elif defined(_Malloc)
#define TEST_COMPONENTS  components TestMalloc as App;\
  App.Mem -> TinyMallocC;

#elif defined(LocalIn)
#define TEST_COMPONENTS  components TestLocalIn as App;

#elif defined(LocalIng)
#define TEST_COMPONENTS  components TestLocalIng as App;

#elif defined(NewTuple)
#define TEST_COMPONENTS  components TestNewTuple as App;

#elif defined(InLocalQueryGen)
#define TEST_COMPONENTS  components TestInLocalQueryGen as App;

#elif defined(InReceive)
#define TEST_COMPONENTS  components TestInReceive as App;

#elif defined(OutReaction)
#define TEST_COMPONENTS  components TestOutReaction as App;

#elif defined(NewTuple)
#define TEST_COMPONENTS  components TestNewTuple as App;

#elif defined(OutMix)
  components TestOutMix as App;

#elif defined(Benchmark)
#define TEST_COMPONENTS  components TestBenchmark as App;


#else
#error ======================================================
#error = Please define a test application to compile.
#error = Try:
#error =     export BENCHMARK_NODE=LocalRd
#error = and recompile. Check TestSuite.nc for more options.
#error =======================================================
#endif




#ifdef myrianode
#define TMilli T4khz
#define TimerMilliC Timer4khzC
// Timer prescaler: for the moment we only have 4khz timer on the myrianode.
// All timer operations should be prescaled with this macro.
#define PRESC(a) ((uint32_t) a * 4)
#else
#define PRESC(a) a
#endif

configuration TestSuite {
}


implementation {
  components MainC, TeenyLimeC;
  components ActiveMessageC as AM;
  components new TimerMilliC() as Timer0;
  components LedsC;
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

