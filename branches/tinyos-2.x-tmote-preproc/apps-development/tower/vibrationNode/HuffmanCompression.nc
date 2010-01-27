/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 662 $
 * * DATE
 * *    $LastChangedDate: 2008-09-16 12:09:04 -0500 (Tue, 16 Sep 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: HuffmanCompression.nc 662 2008-09-16 17:09:04Z lmottola $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU Lesser General Public License
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

#include "vibration_1.h"
#include "vibration_2.h"
#include "vibration_3.h"

#include "Constants.h"
/* #include "printf.h" */

module HuffmanCompression {

  provides interface Compression;
  uses interface Leds;

}

implementation {

/*   uint8_t bitSizeOf(uint16_t i) { */
    
/*     uint8_t bits = 0; */
/*     while (i != 0) { */
/*       i = (uint16_t) (i >> 2); */
/*       bits++; */
/*     } */
/*     return bits; */
/*   } */

  uint8_t getLastNBits(uint16_t i, uint8_t nBits) {

    switch (nBits) {

    case 0:
      return 0;

    case 1:
      return i & 0x01;

    case 2:
      return i & 0x03;

    case 3:
      return i & 0x07;

    case 4:
      return i & 0x0F;

    case 5:
      return i & 0x1F;

    case 6:
      return i & 0x3F;

    case 7:
      return i & 0x7F;

    case 8:
      return i & 0xFF;
    }
    
    return 0;
  }

  uint8_t compress(uint8_t axis, uint8_t* input, uint8_t size, uint8_t* output) {

    uint8_t i;
    uint16_t bitsWritten = 0;
    uint8_t currentPos, currentOffset;
    uint8_t* writerPointer;
    uint16_t code;
    uint8_t length;
    
    // TODO: check length

    // Initialize target memory
    for (i = 0; i<size; i++) {
      output[i] = 0;
    }

    for (i = 0; i<size; i++) {
      if (axis == X_AXIS) {
	code = returnHuffmanCode_1(input[i]);
	length = returnHuffmanBitLen_1(input[i]);
      } else if (axis == Y_AXIS) {
	code = returnHuffmanCode_2(input[i]);
	length = returnHuffmanBitLen_2(input[i]);
      } else {
	code = returnHuffmanCode_3(input[i]);
	length = returnHuffmanBitLen_3(input[i]);
      }
      currentOffset = bitsWritten % 8;
      currentPos = (uint8_t) (bitsWritten / 8);
      writerPointer = &(output[currentPos]);
      if (length + currentOffset <= 8) {
	// The code spans a single byte
	*writerPointer = (*writerPointer) | (code << currentOffset);
      } else if (length + currentOffset > 8
		 && length + currentOffset <= 16) {
	// The code spans two bytes
	uint8_t firstByte = 8-currentOffset;
	*writerPointer = *writerPointer | (getLastNBits(code, firstByte) 
					   << currentOffset);
	writerPointer++;
	*writerPointer = *writerPointer | (code >> firstByte);
      } else if (length + currentOffset > 16
		 && length + currentOffset <= 32) {
	// The code spans three bytes
	uint8_t firstByte = 8-currentOffset;
	*writerPointer = *writerPointer | (getLastNBits(code, firstByte) 
					   << currentOffset);
	writerPointer++;
	*writerPointer = *writerPointer | getLastNBits((code >> firstByte), 8);
	writerPointer++;
	*writerPointer = *writerPointer | (code >> (firstByte + 8));
      } else {
	// TODO: resort to no-compression
      }  
      bitsWritten += length;
/*       printf("i%dc%dl%d",input[i],code,length); */
    }    

    // Use the last byt to indicate how many data bits were written in
    // the last byte
    if (bitsWritten % 8 > 0) {
      currentPos = (uint8_t) (bitsWritten / 8) + 1;
    } else {
      currentPos = (uint8_t) (bitsWritten / 8);    
    }
    writerPointer = &(output[currentPos]);
    *writerPointer = (uint8_t) (bitsWritten % 8);
    return currentPos+1;
    

/*     if (currentOffset > 0) { */
/*       return currentPos + 1; */
/*     } else { */
/*       return currentPos; */
/*     } */
  }

  command uint8_t Compression.compressX(uint8_t* input, uint8_t size, 
					uint8_t* output) {
    return compress(X_AXIS, input, size,  output);
  }

  command uint8_t Compression.compressY(uint8_t* input, uint8_t size, 
					uint8_t* output) {
    return compress(Y_AXIS, input, size,  output);
  }

  command uint8_t Compression.compressZ(uint8_t* input, uint8_t size, 
					uint8_t* output) {
    return compress(Z_AXIS, input, size,  output);
  }
}

