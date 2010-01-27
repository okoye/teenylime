/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Low Power Listening for the CC2420
 * @author David Moss
 */

/**
 * Modified for TeenyLIME by Luca Mottola <luca@sics.se>. Uses
 * information on received acks for reliability too, and makes the use
 * of acks optional.
 */

#include "DefaultLpl.h"
#warning "*** USING TEENYLIME LOW POWER LISTENING LAYER ***"

configuration TLLplC {
  provides {
    interface LowPowerListening;
    interface Send;
    interface Receive;
    interface SplitControl;
    interface State as SendState;
    interface PacketLink;
  }
  
  uses { 
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface SplitControl as SubControl;
  }
}

implementation {
  components MainC,
    TLLplP,
    PowerCycleC,
    CC2420ActiveMessageC,
    CC2420CsmaC,
    CC2420TransmitC,
    CC2420PacketC,
    RandomC,
    TMoteTuning,
    new StateC() as SendStateC,
    new TimerMilliC() as OffTimerC,
    new TimerMilliC() as SendDoneTimerC,
    LedsC;
  
  LowPowerListening = TLLplP;
  Send = TLLplP;
  PacketLink = TLLplP;
  Receive = TLLplP;
  SplitControl = PowerCycleC;
  SendState = SendStateC;
  
  SubControl = TLLplP.SubControl;
  SubReceive = TLLplP.SubReceive;
  SubSend = TLLplP.SubSend;
  
  
  MainC.SoftwareInit -> TLLplP;
  
  TLLplP.Tuning -> TMoteTuning.Tuning[unique("TLTuning")];
  TLLplP.SplitControlState -> PowerCycleC.SplitControlState;
  TLLplP.RadioPowerState -> PowerCycleC.RadioPowerState;
  TLLplP.SendState -> SendStateC;
  TLLplP.OffTimer -> OffTimerC;
  TLLplP.SendDoneTimer -> SendDoneTimerC;
  TLLplP.PowerCycle -> PowerCycleC;
  TLLplP.Resend -> CC2420TransmitC;
  TLLplP.PacketAcknowledgements -> CC2420ActiveMessageC;
  TLLplP.AMPacket -> CC2420ActiveMessageC;
  TLLplP.CC2420PacketBody -> CC2420PacketC;
  TLLplP.RadioBackoff -> CC2420CsmaC;
  TLLplP.Random -> RandomC;
  TLLplP.Leds -> LedsC;
  
}
