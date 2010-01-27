/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 883 $
 * * DATE
 * *    $LastChangedDate: 2009-07-14 07:51:17 -0500 (Tue, 14 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Properties.java 883 2009-07-14 12:51:17Z mceriotti $
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

package tl.apps.office;

import java.awt.Color;

import tl.lib.dataCollection.data.SourceId;

public class Properties {

	public final static int TUPLE_DISS_PAYLOAD_SIZE = 68;
	public final static int TUPLE_MSG_PAYLOAD_SIZE = 68;

	public final static int TREE_REFRESH = 18;

	public final static int CACHE_SIZE = 10;

	public final static String LOG_DIR_NAME = "office_log";

	public final static int MAX_ENTRIES = 0xFFFF;

	public final static boolean LOG_MESSAGES = true;

	// In milliseconds
	public static final long MAX_NOSEEN_INTERVAL = 240000;

	public static final int SINK_ADDRESS = 0;

	public static final int X_MAX = 1000;
	public static final int Y_MAX = 1000;
	public static final int MOTE_RADIUS = 10;

	static final Color COLOR_0 = Color.red;

	public static int initialPrimaryXPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		default:
			result = (int) (Math.random() * X_MAX);
		}
		if (result < 2 * Properties.MOTE_RADIUS)
			result = 2 * Properties.MOTE_RADIUS;
		if (result > X_MAX - 2 * Properties.MOTE_RADIUS)
			result = X_MAX - 2 * Properties.MOTE_RADIUS;
		return result;
	}

	public static int initialPrimaryYPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		default:
			result = (int) (Math.random() * Y_MAX);
		}
		if (result < 2 * Properties.MOTE_RADIUS)
			result = 2 * Properties.MOTE_RADIUS;
		if (result > X_MAX - 2 * Properties.MOTE_RADIUS)
			result = X_MAX - 2 * Properties.MOTE_RADIUS;
		return result;
	}

	public static Color initialColor(SourceId identifier) {
		Color result = null;
		switch (identifier.address()) {
		case 0:
			result = COLOR_0;
			break;
		default:
			int red = (int) (Math.random() * 255 * identifier.address()) % 255;
			int green = (int) (Math.random() * 255 * identifier.address()) % 255;
			int blue = (int) (Math.random() * 255 * identifier.address()) % 255;
			result = new Color(red, green, blue);
		}
		return result;
	}
}
