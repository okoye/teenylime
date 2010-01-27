/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 720 $
 * * DATE
 * *    $LastChangedDate: 2008-12-18 05:15:40 -0600 (Thu, 18 Dec 2008) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: UnknownTupleReader.java 720 2008-12-18 11:15:40Z mceriotti $
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

package tl.lib.dataCollection.console;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Hashtable;

import tl.common.types.Tuple;
import tl.lib.dataCollection._CollectionFeature;
import tl.lib.dataCollection._CollectionTupleReader;
import tl.lib.dataCollection.data.Sample;
import tl.lib.dataCollection.data.SourceId;

public class UnknownTupleReader implements _CollectionTupleReader {

	private FileWriter writer;
	private String fileName;
	private boolean log;

	public UnknownTupleReader(boolean log, String dir) {
		this.log = log;
		if (log) {
			this.fileName = "";
			if (dir.length() > 0) {
				File directory = new File(dir);
				directory.mkdirs();
				this.fileName = dir + File.separator;
			}
			this.fileName += "Unknown.txt";
		}
	}

	public Hashtable<_CollectionFeature, Sample> read(Tuple tuple) {
		if (log) {
			try {
				this.writer = new FileWriter(fileName, true);
				writer.write(tuple.toString() + "\n");
				writer.flush();
				writer.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return new Hashtable<_CollectionFeature, Sample>();
	}

	public SourceId getSource(Tuple tuple) {
		return new SourceId(-1);
	}
}
