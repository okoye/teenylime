/*
 * Copyright (c) 2008 TRETEC S.r.l.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * SPI abstraction for the RAMTRON FM25LC256 family of fram chips.
 *
 * @author Michele Corra' <michele.corra@3tec.it>
 * @author Carloalberto Torghele <carloalberto.torghele@gmail.com>
*/
#include "Fm25lc.h"
configuration Fm25lcSpiC {

  provides interface Init;
  provides interface Resource;
  provides interface Fm25lcSpi;

}

implementation {

  components Fm25lcSpiP as SpiP;
  Init = SpiP;
  Resource = SpiP.ClientResource;
  Fm25lcSpi = SpiP;

  components HplFm25lcSpiC as SpiC;
  SpiP.SpiResource -> SpiC;
  SpiP.SpiByte -> SpiC;
  SpiP.SpiPacket -> SpiC;

  components HplFm25lcPinsC as PinsC;
  SpiP.CSN -> PinsC.CSN;
  SpiP.Hold -> PinsC.Hold;

  components LedsC as Leds;
  SpiP.Leds -> Leds;

}
