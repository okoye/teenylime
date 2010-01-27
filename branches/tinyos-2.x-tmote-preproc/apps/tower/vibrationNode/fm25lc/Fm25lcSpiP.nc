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

#include "crc.h"
#include "Fm25lc.h"

module Fm25lcSpiP {

  provides interface Init;
  provides interface Resource as ClientResource;
  provides interface Fm25lcSpi as Spi;

  uses interface Resource as SpiResource;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as Hold;
  uses interface SpiByte;
  uses interface SpiPacket;
  uses interface Leds;

}

implementation {

  enum {
    CRC_BUF_SIZE = 16,
  };

  typedef enum {
    S_READ 		= 0x03,
    S_READ_SR 		= 0x05,
    S_WRITE_SR 		= 0x01,
    S_WRITE_DISABLE 	= 0x04,
    S_WRITE_ENABLE 	= 0x06,
    S_WRITE 		= 0x02,
    S_SECTOR_ERASE	= 0xD8,
    S_BULK_ERASE	= 0xC7
  } Fm25lc_cmd_t;

  norace uint8_t m_cmd[ 4 ];

  norace bool m_is_writing = FALSE;
  norace bool m_computing_crc = FALSE;

  norace Fm25lc_addr_t m_addr;
  norace uint8_t* m_buf;
  norace Fm25lc_len_t m_len;
  norace Fm25lc_addr_t m_cur_addr;
  norace Fm25lc_len_t m_cur_len;
  norace uint8_t m_crc_buf[ CRC_BUF_SIZE ];
  norace uint16_t m_crc;

  error_t newRequest( bool write, Fm25lc_len_t cmd_len );
  void signalDone( error_t error );

  uint8_t sendCmd( uint8_t cmd, uint8_t len ) {

    uint8_t readval=0;

    call CSN.clr();
    for ( ; len; len--)
      readval = call SpiByte.write( cmd );
    call CSN.set();

    return readval;

  }

  command error_t Init.init() {
    call CSN.makeOutput();
    call Hold.makeOutput();
    call CSN.set();
    call Hold.set();
    return SUCCESS;
  }

  async command error_t ClientResource.request() {
    return call SpiResource.request();
  }

  async command error_t ClientResource.immediateRequest() {
    return call SpiResource.immediateRequest();
  }
  
  async command error_t ClientResource.release() {
    return call SpiResource.release();
  }

  async command uint8_t ClientResource.isOwner() {
    return call SpiResource.isOwner();
  }

  Fm25lc_len_t calcReadLen() {
    return ( m_cur_len < CRC_BUF_SIZE ) ? m_cur_len : CRC_BUF_SIZE;
  }  

  async command error_t Spi.powerDown() {
    //sendCmd( S_DEEP_SLEEP, 1 );
    return SUCCESS;
  }

  async command error_t Spi.powerUp() {
    //sendCmd( S_POWER_ON, 5 );
    return SUCCESS;
  }

  async command error_t Spi.read( Fm25lc_addr_t addr, uint8_t* buf, 
				  Fm25lc_len_t len ) {
    m_cmd[ 0 ] = S_READ;
    m_addr = addr;
    m_buf = buf;
    m_len = len;
    return newRequest( FALSE, 3 );
  }

  async command error_t Spi.computeCrc( uint16_t crc, Fm25lc_addr_t addr,
					Fm25lc_len_t len ) {
    m_computing_crc = TRUE;
    m_crc = crc;
    m_addr = m_cur_addr = addr;
    m_len = m_cur_len = len;
    return call Spi.read( addr, m_crc_buf, calcReadLen() );
  }
  
  async command error_t Spi.pageProgram( Fm25lc_addr_t addr, uint8_t* buf, 
					 Fm25lc_len_t len ) {
    m_cmd[ 0 ] = S_WRITE;
    m_addr = addr;
    m_buf = buf;
    m_len = len;
    return newRequest( TRUE, 3 );
  }

  async command error_t Spi.sectorErase( uint8_t sector ) {
    m_cmd[ 0 ] = S_SECTOR_ERASE;
    m_addr = (Fm25lc_addr_t)sector;
    signalDone( SUCCESS );
    return SUCCESS;
  }

  async command error_t Spi.bulkErase() {
    m_cmd[ 0 ] = S_BULK_ERASE;
    signalDone( SUCCESS );
    return SUCCESS;
  }

  error_t newRequest( bool write, Fm25lc_len_t cmd_len ) {
    m_cmd[ 1 ] = m_addr >> 8;
    m_cmd[ 2 ] = m_addr;
    if ( write )
      sendCmd( S_WRITE_ENABLE, 1 );
    call CSN.clr();
    call SpiPacket.send( m_cmd, NULL, cmd_len );
    return SUCCESS;
  }

  void releaseAndRequest() {
    call SpiResource.release();
    call SpiResource.request();
  }

  async event void SpiPacket.sendDone( uint8_t* tx_buf, uint8_t* rx_buf,
				       uint16_t len, error_t error ) {

    int i;

    switch( m_cmd[ 0 ] ) {

    case S_READ:
      if ( tx_buf == m_cmd ) {
	call SpiPacket.send( NULL, m_buf, m_len );
	break;
      }
      else if ( m_computing_crc ) {
	for ( i = 0; i < len; i++ )
	  m_crc = crcByte( m_crc, m_crc_buf[ i ] );
	m_cur_addr += len;
	m_cur_len -= len;
	if ( m_cur_len ) {
	  call SpiPacket.send( NULL, m_crc_buf, calcReadLen() );
	  break;
	}
      }
      call CSN.set();
      signalDone( SUCCESS );
      break;

    case S_WRITE:
      if ( tx_buf == m_cmd ) {
	call SpiPacket.send( m_buf, NULL, m_len );
	break;
      }
      // fall through
      
    case S_SECTOR_ERASE: case S_BULK_ERASE:
      call CSN.set();
      m_is_writing = TRUE;
      releaseAndRequest();
      break;

    default:
      break;

    }

  }

  event void SpiResource.granted() {

    if ( !m_is_writing )
      signal ClientResource.granted();
    else if ( sendCmd( S_READ_SR, 2 ) & 0x01 )	// verifico se sta scrivendo, ma non serve: non ci sono latenze di scrittura!
      releaseAndRequest();
    else
      signalDone( SUCCESS );

  }

  void signalDone( error_t error ) {
    m_is_writing = FALSE;
    switch( m_cmd[ 0 ] ) {
    case S_READ:
      if ( m_computing_crc ) {
	m_computing_crc = FALSE;
	signal Spi.computeCrcDone( m_crc, m_addr, m_len, error );
      }
      else {
	signal Spi.readDone( m_addr, m_buf, m_len, error );
      }
      break;
    case S_WRITE:
      signal Spi.pageProgramDone( m_addr, m_buf, m_len, error );
      break;
    case S_SECTOR_ERASE:
      signal Spi.sectorEraseDone( m_addr , error );
      break;
    case S_BULK_ERASE:
      signal Spi.bulkEraseDone( error );
      break;
    }
  }
}
