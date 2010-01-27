/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 684 $
 * * DATE
 * *    $LastChangedDate: 2008-10-01 05:07:49 -0500 (Wed, 01 Oct 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: SerializerBuilder.java 684 2008-10-01 10:07:49Z mceriotti $
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

package tl.common.utils;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Vector;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The Class SerializeBuilder.
 * 
 * This class builds the Serializer class which is used to convert tuples
 * coming from the serial into tl.types.Tuple objects. It parses the tl_objs
 * file generated by the TeenyLIME preprocessor in order to find the tuple
 * types used in the TeenyLIME application.
 * 
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

public class SerializerBuilder {

	private static String DEFAULT_OUTPUT = "Serializer.java";

	public static void main(String[] args) {
		try {
			if (args.length == 1) {
				generateSerializer(args[0], DEFAULT_OUTPUT);
			} else if (args.length == 2) {
				generateSerializer(args[0], args[1]);
			} else {
				printUsageAndExit();
			}
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private static void generateSerializer(String tlObjsFile, String targetFile)
			throws IllegalArgumentException, IOException {

		// Reading the tl_objs file
		System.out.println("Opening tl_objs file: " + tlObjsFile);
		BufferedReader tlObjsReader = new BufferedReader(new FileReader(
				tlObjsFile));

		HashMap<Integer, Vector<String>> map = new HashMap<Integer, Vector<String>>();
		String s = null;
		Vector<String> v = new Vector<String>();
		int tuple_id = 0;
		while ((s = tlObjsReader.readLine()) != null) {
			if ("".equals(s)) {
				continue;
			} else if (s.matches("^uint8_t$") || s.matches("^char$")) {
				v.add("Uint8");
			} else if (s.matches("^uint16_t$") || s.matches("^lqi$")) {
				v.add("Uint16");
			} else if (s.matches("^uint8_t\\[[0-9]+\\]$")) {
				Pattern p = Pattern.compile("^uint8_t\\[([^\\]]+)\\]$");
				Matcher m = p.matcher(s);
				m.find();
				int size = Integer.parseInt(m.group(1));
				v.add("Uint8Array["+size+"]");
			} else if (s.matches("^tuple done[\\w\\W]*$")
					|| s.matches("^neighborTuple done[\\w\\W]*$")) {
				map.put(new Integer(tuple_id), v);
				tuple_id++;
				v = new Vector<String>();
			} else {
				throw new IllegalArgumentException("Unknown input value:" + s);
			}
		}
		tlObjsReader.close();

		// Generating output
		System.out.println("Generating Serializer in " + targetFile);
		BufferedWriter fileWriter = new BufferedWriter(new FileWriter(
				targetFile));

		// Writing tag
		fileWriter.write(generateTag());

		// Writing header
		fileWriter.write("package tl.common.utils;\n" + "import tl.common.types.*;\n" + "\n"
				+ "public class Serializer {\n" + "\n");

		// Writing toSerialMsg function
		// Generic beginning
		fileWriter
				.write("\tstatic public short[] toSerial(Tuple tuple) throws IllegalArgumentException {\n"
						+ "\t\tshort[] serialTuple = new short[TupleSerialMsg.numElements_data()];\n"
						+ "\t\tint index = 0;\n"
						+ "\t\t// Logical Time\n"
						+ "\t\tserialTuple[0] = (short) (tuple.getLogicalTime() >> 8);\n"
						+ "\t\tserialTuple[1] = (short) (tuple.getLogicalTime() & 0xFF);\n"
						+ "\t\t// Expire In\n"
						+ "\t\tserialTuple[2] = (short) (tuple.getExpireIn() >> 8);\n"
						+ "\t\tserialTuple[3] = (short) (tuple.getExpireIn() & 0xFF);\n"
						+ "\t\t// Capability Tuple\n"
						+ "\t\tserialTuple[5] = (short) (tuple.isCapabilityT() ? 1 : 0);\n"
						+ "\t\tindex = 6;\n"
						+ "\t\t// Match Types\n"
						+ "\t\tfor (int i = 0; i < tuple.length(); i++) {\n"
						+ "\t\t\tserialTuple[index++] = (short) tuple.get(i).getMatchType();\n"
						+ "\t\t}\n"
						+ "\t\tif (tuple.length() % 2 != 0) {\n"
						+ "\t\t\tserialTuple[index++] = (short) 0;\n"
						+ "\t\t}\n"
						+ "\t\t// Values\n"
						+ "\t\tfor (int i = 0; i < tuple.length(); i++) {\n"
						+ "\t\t\tshort[] c = tuple.get(i).getValue().serializeValue();\n"
						+ "\t\t\tif (tuple.get(i).getValue() instanceof Uint16) {\n"
						+ "\t\t\t\tserialTuple[index++] = c[0];\n"
						+ "\t\t\t\tserialTuple[index++] = c[1];\n"
						+ "\t\t\t} else if (tuple.get(i).getValue() instanceof Uint8) {\n"
						+ "\t\t\t\tserialTuple[index++] = (short) 0;\n"
						+ "\t\t\t\tserialTuple[index++] = c[0];\n"
						+ "\t\t\t} else if (tuple.get(i).getValue() instanceof Uint8Array) {\n"
						+ "\t\t\t\tfor (int j = 0; j < c.length; j++) {\n"
						+ "\t\t\t\t\tserialTuple[index++] = c[j];\n"
						+ "\t\t\t\t}\n"
						+ "\t\t\t}\n"
						+ "\t\t}\n"
						+ "\t\tboolean foundType = false;\n");

		// Writing type specific code
		Vector<Integer> keys = new Vector<Integer>(map.keySet());
		Collections.sort(keys);
		Integer tupleId;
		for (int k = 0; k < keys.size(); k++) {
			tupleId = keys.get(k);
			if (k == 0)
				fileWriter.write("\t\tif ");
			else
				fileWriter.write("\t\telse if ");
			fileWriter.write("(tuple.length() == " + map.get(tupleId).size());
			for (int i = 0; i < map.get(tupleId).size(); i++) {
				if (map.get(tupleId).get(i).matches("^Uint8Array\\[[0-9]+\\]$")) {
					fileWriter
					.write("\n\t\t\t&& tuple.get("
							+ i
							+ ").getValue() instanceof Uint8Array");
					Pattern p = Pattern.compile("^Uint8Array\\[([^\\]]+)\\]$");
					Matcher m = p.matcher(map.get(tupleId).get(i));
					m.find();
					int size = Integer.parseInt(m.group(1));
					fileWriter.write("\n\t\t\t&& ((Uint8Array) tuple.get(" + i
							+ ").getValue()).getSize() == "
							+ size);
				} else {
					fileWriter
					.write("\n\t\t\t&& tuple.get("
							+ i
							+ ").getValue() instanceof "
							+ map.get(tupleId).get(i));
				}
			}
			fileWriter.write(") {\n" + "\t\t\tfoundType = true;\n"
					+ "\t\t\t// The type of the tuple\n"
					+ "\t\t\tserialTuple[4] = (short) " + tupleId + ";\n"
					+ "\t\t}\n");
		}

		// Closing toSerialMsg function
		fileWriter
				.write("\t\tif (!foundType) {\n"
						+ "\t\t\tthrow new IllegalArgumentException(\"Unknown tuple type\" + tuple.length());\n"
						+ "\t\t}\n"
						+ "\t\tshort[] result = new short[index];\n"
						+ "\t\tfor (int i = 0; i < index; i++){\n"
						+ "\t\t\tresult[i] = serialTuple[i];\n" + "\t\t}\n"
						+ "\t\treturn result;\n" + "\t}\n\n");

		// Writing toTuple function
		// Generic beginning
		fileWriter
				.write("\tstatic public Tuple toTuple(short[] serialTuple) throws IllegalArgumentException {\n"
						+ "\t\tshort type = serialTuple[4];\n"
						+ "\t\tTuple tuple = new Tuple();\n"
						+ "\t\ttuple.setLogicalTime((serialTuple[0] << 8) + serialTuple[1]);\n"
						+ "\t\ttuple.setExpireIn((serialTuple[2] << 8) + serialTuple[3]);\n"
						+ "\t\ttuple.setCapabilityT(serialTuple[5] != 0);\n"
						+ "\t\tshort[] value;\n" + "\t\tswitch (type) {\n");

		// Writing type specific code
		int matchIndex = 0;
		int dataIndex = 0;
		for (int k = 0; k < keys.size(); k++) {
			tupleId = keys.get(k);
			fileWriter.write("\t\tcase " + tupleId + ":\n");
			matchIndex = 6;
			dataIndex = matchIndex + map.get(tupleId).size();
			if (dataIndex % 2 != 0)
				dataIndex++;
			for (int i = 0; i < map.get(tupleId).size(); i++) {
				if (map.get(tupleId).get(i).equals("Uint8")) {
					dataIndex++;
					fileWriter
							.write("\t\t\tvalue = new short[1];\n"
									+ "\t\t\tvalue[0] = serialTuple["
									+ (dataIndex++)
									+ "];\n"
									+ "\t\t\ttuple.add(new Field().setField(serialTuple["
									+ (matchIndex++)
									+ "], new Uint8().setValue(value)));\n");
				} else if (map.get(tupleId).get(i).equals("Uint16")) {
					fileWriter
							.write("\t\t\tvalue = new short[2];\n"
									+ "\t\t\tvalue[0] = serialTuple["
									+ (dataIndex++)
									+ "];\n"
									+ "\t\t\tvalue[1] = serialTuple["
									+ (dataIndex++)
									+ "];\n"
									+ "\t\t\ttuple.add(new Field().setField(serialTuple["
									+ (matchIndex++)
									+ "], new Uint16().setValue(value)));\n");
				} else if (map.get(tupleId).get(i).matches("^Uint8Array\\[[0-9]+\\]$")) {
					Pattern p = Pattern.compile("^Uint8Array\\[([^\\]]+)\\]$");
					Matcher m = p.matcher(map.get(tupleId).get(i));
					m.find();
					int arraySize = Integer.parseInt(m.group(1));
					fileWriter
							.write("\t\t\tvalue = new short["
									+ arraySize
									+ "];\n"
									+ "\t\t\tfor (int i = "
									+ dataIndex
									+ ", j = 0; i < "
									+ (dataIndex + arraySize)
									+ "; i++, j++) {\n"
									+ "\t\t\t\tvalue[j] = serialTuple[i];\n"
									+ "\t\t\t}\n"
									+ "\t\t\ttuple.add(new Field().setField(serialTuple["
									+ (matchIndex++) + "], new Uint8Array("
									+ arraySize + ").setValue(value)));\n");
					dataIndex += arraySize;
				}
			}
			fileWriter.write("\t\t\tbreak;\n");
		}

		// Closing toTuple function
		fileWriter
				.write("\t\tdefault:\n"
						+ "\t\t\tthrow new IllegalArgumentException(\"Unknown tuple type\");\n"
						+ "\t\t}\n" + "\t\treturn tuple;\n" + "\t}\n");

		// Closing Serializer class
		fileWriter.write("}\n");

		fileWriter.flush();
		fileWriter.close();
		tlObjsReader.close();
	}

	private static String generateTag() {
		DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
		DateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");
		Date today = new Date();
		String nowDate = dateFormat.format(today);
		String nowTime = timeFormat.format(today);

		String ret = "/***\n"
				+ " * * Automatically generated by SerializerBuilder on "
				+ nowDate + " " + nowTime + "\n * * DO NOT EDIT! \n ***/\n\n";

		return ret;
	}

	private static void printUsageAndExit() {
		System.err.println("Usage: java tl.utils.SerializerBuilder tl_objs_file");
		System.exit(-1);
	}
}