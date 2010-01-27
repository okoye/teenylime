/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 885 $
 * * DATE
 * *    $LastChangedDate: 2009-07-15 11:08:41 -0500 (Wed, 15 Jul 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Properties.java 885 2009-07-15 16:08:41Z mceriotti $
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

package tl.apps.tunnel;

import java.awt.Color;

import tl.lib.dataCollection.data.SourceId;

public class Properties {

	public final static int CACHE_SIZE = 10;

	public final static int TUPLE_DISS_PAYLOAD_SIZE = 28;
	public final static int TUPLE_MSG_PAYLOAD_SIZE = 28;

	public final static String LOG_DIR_NAME = "tunnel_log";

	public final static int MAX_ENTRIES = 0xFFFF;

	public final static boolean LOG_MESSAGES = true;

	// In milliseconds
	public static final long MAX_NOSEEN_INTERVAL = 120000;

	public static final int SINK_ADDRESS = 0;

	public static final int X_MAX = 1000;
	public static final int Y_MAX = 1000;
	public static final int MOTE_RADIUS = 10;

	static final Color COLOR_0 = Color.blue;
	static final Color COLOR_1 = Color.darkGray;
	static final Color COLOR_2 = Color.red;
	static final Color COLOR_3 = new Color(250, 125, 0);
	static final Color COLOR_4 = Color.green;
	static final Color COLOR_5 = new Color(0, 216, 216);
	static final Color COLOR_6 = Color.magenta;
	static final Color COLOR_7 = Color.gray;
	static final Color COLOR_8 = new Color(88, 0, 147);
	static final Color COLOR_9 = new Color(0, 125, 0);
	static final Color COLOR_10 = new Color(0, 125, 125);
	static final Color COLOR_11 = new Color(0, 160, 250);
	static final Color COLOR_12 = new Color(125, 125, 0);
	static final Color COLOR_13 = new Color(125, 125, 250);
	static final Color COLOR_14 = new Color(150, 70, 150);;
	static final Color COLOR_15 = new Color(250, 70, 250);
	static final Color COLOR_16 = new Color(0, 125, 250);
	static final Color COLOR_17 = new Color(0, 50, 0);
	static final Color COLOR_18 = new Color(0, 0, 90);
	static final Color COLOR_19 = new Color(80, 0, 0);
	// static final Color COLOR_101 = new Color(250, 0, 125);

	static final int PRIMARY_X_0 = 59;
	static final int PRIMARY_Y_0 = 577;
	static final int PRIMARY_X_1 = 244;
	static final int PRIMARY_Y_1 = 937;
	static final int PRIMARY_X_2 = 106;
	static final int PRIMARY_Y_2 = 542;
	static final int PRIMARY_X_3 = 288;
	static final int PRIMARY_Y_3 = 904;
	static final int PRIMARY_X_4 = 160;
	static final int PRIMARY_Y_4 = 507;
	static final int PRIMARY_X_5 = 343;
	static final int PRIMARY_Y_5 = 869;
	static final int PRIMARY_X_6 = 222;
	static final int PRIMARY_Y_6 = 464;
	static final int PRIMARY_X_7 = 407;
	static final int PRIMARY_Y_7 = 823;
	static final int PRIMARY_X_8 = 300;
	static final int PRIMARY_Y_8 = 412;
	static final int PRIMARY_X_9 = 478;
	static final int PRIMARY_Y_9 = 775;
	static final int PRIMARY_X_10 = 377;
	static final int PRIMARY_Y_10 = 359;
	static final int PRIMARY_X_11 = 558;
	static final int PRIMARY_Y_11 = 720;
	static final int PRIMARY_X_12 = 454;
	static final int PRIMARY_Y_12 = 307;
	static final int PRIMARY_X_13 = 646;
	static final int PRIMARY_Y_13 = 663;
	static final int PRIMARY_X_14 = 556;
	static final int PRIMARY_Y_14 = 236;
	static final int PRIMARY_X_15 = 744;
	static final int PRIMARY_Y_15 = 596;
	static final int PRIMARY_X_16 = 678;
	static final int PRIMARY_Y_16 = 152;
	static final int PRIMARY_X_17 = 859;
	static final int PRIMARY_Y_17 = 521;
	static final int PRIMARY_X_18 = 780;
	static final int PRIMARY_Y_18 = 82;
	static final int PRIMARY_X_19 = 972;
	static final int PRIMARY_Y_19 = 442;

	// static final int PRIMARY_X_101 = 750;
	// static final int PRIMARY_Y_101 = 700;

	public static int initialPrimaryXPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		case 0:
			result = PRIMARY_X_0;
			break;
		case 1:
			result = PRIMARY_X_1;
			break;
		case 2:
			result = PRIMARY_X_2;
			break;
		case 3:
			result = PRIMARY_X_3;
			break;
		case 4:
			result = PRIMARY_X_4;
			break;
		case 5:
			result = PRIMARY_X_5;
			break;
		case 6:
			result = PRIMARY_X_6;
			break;
		case 7:
			result = PRIMARY_X_7;
			break;
		case 8:
			result = PRIMARY_X_8;
			break;
		case 9:
			result = PRIMARY_X_9;
			break;
		case 10:
			result = PRIMARY_X_10;
			break;
		case 11:
			result = PRIMARY_X_11;
			break;
		case 12:
			result = PRIMARY_X_12;
			break;
		case 13:
			result = PRIMARY_X_13;
			break;
		case 14:
			result = PRIMARY_X_14;
			break;
		case 15:
			result = PRIMARY_X_15;
			break;
		case 16:
			result = PRIMARY_X_16;
			break;
		case 17:
			result = PRIMARY_X_17;
			break;
		case 18:
			result = PRIMARY_X_18;
			break;
		case 19:
			result = PRIMARY_X_19;
			break;
		// case 101:
		// result = PRIMARY_X_101;
		// break;
		default:
			result = (int) (Math.random() * X_MAX);
		}
		return result;
	}

	public static int initialPrimaryYPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		case 0:
			result = PRIMARY_Y_0;
			break;
		case 1:
			result = PRIMARY_Y_1;
			break;
		case 2:
			result = PRIMARY_Y_2;
			break;
		case 3:
			result = PRIMARY_Y_3;
			break;
		case 4:
			result = PRIMARY_Y_4;
			break;
		case 5:
			result = PRIMARY_Y_5;
			break;
		case 6:
			result = PRIMARY_Y_6;
			break;
		case 7:
			result = PRIMARY_Y_7;
			break;
		case 8:
			result = PRIMARY_Y_8;
			break;
		case 9:
			result = PRIMARY_Y_9;
			break;
		case 10:
			result = PRIMARY_Y_10;
			break;
		case 11:
			result = PRIMARY_Y_11;
			break;
		case 12:
			result = PRIMARY_Y_12;
			break;
		case 13:
			result = PRIMARY_Y_13;
			break;
		case 14:
			result = PRIMARY_Y_14;
			break;
		case 15:
			result = PRIMARY_Y_15;
			break;
		case 16:
			result = PRIMARY_Y_16;
			break;
		case 17:
			result = PRIMARY_Y_17;
			break;
		case 18:
			result = PRIMARY_Y_18;
			break;
		case 19:
			result = PRIMARY_Y_19;
			break;
		// case 101:
		// result = PRIMARY_Y_101;
		// break;
		default:
			result = (int) (Math.random() * Y_MAX);
		}
		return result;
	}

	public static Color initialColor(SourceId identifier) {
		Color result = null;
		switch (identifier.address()) {
		case 0:
			result = COLOR_0;
			break;
		case 1:
			result = COLOR_1;
			break;
		case 2:
			result = COLOR_2;
			break;
		case 3:
			result = COLOR_3;
			break;
		case 4:
			result = COLOR_4;
			break;
		case 5:
			result = COLOR_5;
			break;
		case 6:
			result = COLOR_6;
			break;
		case 7:
			result = COLOR_7;
			break;
		case 8:
			result = COLOR_8;
			break;
		case 9:
			result = COLOR_9;
			break;
		case 10:
			result = COLOR_10;
			break;
		case 11:
			result = COLOR_11;
			break;
		case 12:
			result = COLOR_12;
			break;
		case 13:
			result = COLOR_13;
			break;
		case 14:
			result = COLOR_14;
			break;
		case 15:
			result = COLOR_15;
			break;
		case 16:
			result = COLOR_16;
			break;
		case 17:
			result = COLOR_17;
			break;
		case 18:
			result = COLOR_18;
			break;
		case 19:
			result = COLOR_19;
			break;
		// case 101:
		// result = COLOR_101;
		// break;
		default:
			int red = (int) (Math.random() * 255 * identifier.address()) % 255;
			int green = (int) (Math.random() * 255 * identifier.address()) % 255;
			int blue = (int) (Math.random() * 255 * identifier.address()) % 255;
			result = new Color(red, green, blue);
		}
		return result;
	}
}
