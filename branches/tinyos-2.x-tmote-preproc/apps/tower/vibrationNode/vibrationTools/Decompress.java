/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 611 $
 * * DATE
 * *    $LastChangedDate: 2008-08-02 12:21:00 +0200 (Sat, 02 Aug 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: lmottola $
 * *
 * *	$Id: GenerateHuffmanCompression.java 611 2008-08-02 10:21:00Z lmottola $
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

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Set;
import java.util.StringTokenizer;

public class Decompress {

	public static void main(String[] args) {

		if (args.length < 3) {
			printUsageAndExit();
		}

		try {
			decompress(args[0], args[1], args[2]);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private static void decompress(String inputFile, String dictionaryFile,
			String outputFile) throws IOException {

		// Reading the dictionary
		BufferedReader dicReader = new BufferedReader(new FileReader(
				dictionaryFile));
		HashMap<String, String> decoding = new HashMap<String, String>();
		String s = null;
		while ((s = dicReader.readLine()) != null) {
			StringTokenizer stk = new StringTokenizer(s, " ");
			while (stk.hasMoreTokens()) {
				String symbol = stk.nextToken();
				// System.out.println("Symbol:" + symbol);
				// Ignores the EOF symbol
				if (!symbol.equals("EOF")) {
					// Ignore the count of this symbol in the dictionary
					stk.nextToken();
					String code = stk.nextToken();
					decoding.put(code, symbol);
				} else {
					break;
				}
			}
		}
		dicReader.close();

		// Getting out control info indicating the number of bits written in the
		// last byte
		String s0;
		int lastByteBits = 0;
		int noBytes = 0;
		BufferedReader tempInput = new BufferedReader(new FileReader(inputFile));
		while ((s0 = tempInput.readLine()) != null) {
			lastByteBits = Integer.parseInt(s0);
			noBytes++;
		}

		// Creating bit sequence
		BufferedReader inputReader = new BufferedReader(new FileReader(
				inputFile));
		LinkedList<String> data = new LinkedList<String>();
		int nBytesRead = 0;
		while ((s0 = inputReader.readLine()) != null) {
			nBytesRead++;
			String s0Bit = null;
			if (nBytesRead < noBytes - 1) {
				s0Bit = convertToNBits(s0, 8);
				data.addFirst(s0Bit);
			}
			if (nBytesRead == noBytes - 1) {
				s0Bit = convertToNBits(s0, lastByteBits);
				data.addFirst(s0Bit);
			}
		}
		String bitSequenceStr = new String();
		for (String s0Bit : data) {
			bitSequenceStr = bitSequenceStr.concat(s0Bit);
		}

		//System.out.println(bitSequenceStr);
		// System.out.println(bitSequenceStr.length());

		// Decompressing
		int from = 0, to = 1;
		boolean found = false;
		Set<String> codes = decoding.keySet();
		LinkedList<String> symbols = new LinkedList<String>();
		while (to <= bitSequenceStr.length()) {
			String atom = bitSequenceStr.substring(from, to);
			// System.out.println("Atom:" + atom);
			// Searching for code
			found = false;
			for (String code : codes) {
				if (atom.equals(code)) {
					// Found code
					// System.out.println("Found code " + code);
					symbols.addFirst(decoding.get(code).substring(2));
					from = to;
					to++;
					found = true;
					break;
				}
			}
			if (!found) {
				// System.out.println("Not found");
				to++;
			}
		}

		if (!found) {
			System.err.println("Last Huffman code was not consistent!");
			System.exit(-1);
		}
		// Writing output file
		FileWriter output = new FileWriter(outputFile);
		for (String symbol : symbols) {
			output.write(Integer.parseInt(symbol, 16) + "\n");
		}
		output.flush();
		output.close();
	}

	private static String convertToNBits(String n, int bits) {

		Integer i = Integer.parseInt(n);
		String bitString = Integer.toBinaryString(i);
		while (bitString.length() < bits) {
			bitString = "0" + bitString;
		}
		return bitString;
	}

	private static void printUsageAndExit() {

		System.err
				.println("Usage: java Decompress compressedFile dictionaryFile outputFile");
		System.exit(-1);
	}

	protected static int convertToInt(String bitString) {

		int result = 0;
		char[] bits = bitString.toCharArray();
		for (int i = 0; i < bitString.length(); i++) {
			result = result + ((byte) bits[i] - 48)
					* (int) Math.pow(2, (bitString.length() - 1 - i));
		}

		if (result > MAX_SIZE_CODING) {
			System.out.println("Failed code conversion to 16 bits integer!");
			System.exit(-1);
		}
		return result;
	}

	private static final int MAX_SIZE_CODING = 0xFFFF;
}

class DecompressSymbolCode {

	private int code;
	private byte length;

	public DecompressSymbolCode(String codeString, byte length) {

		this.code = Decompress.convertToInt(codeString);
		this.length = length;
	}

	public int getCode() {
		return code;
	}

	public byte getLength() {
		return length;
	}
}
