/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1015 $
 * * DATE
 * *    $LastChangedDate: 2010-01-11 02:15:23 -0600 (Mon, 11 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Properties.java 1015 2010-01-11 08:15:23Z mceriotti $
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

	public final static int TUPLE_DISS_PAYLOAD_SIZE = 58;
	public final static int TUPLE_MSG_PAYLOAD_SIZE = 58;

	public final static String LOG_DIR_NAME = "tunnel_log";

	public final static int MAX_ENTRIES = 0xFFFF;

	public final static boolean LOG_MESSAGES = true;

	// In milliseconds
	public static final long MAX_NOSEEN_INTERVAL = 600000;

	public static final int SINK_ADDRESS = 100;

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

	static final int PRIMARY_X_0 = 79;
	static final int PRIMARY_Y_0 = 985;
	static final int PRIMARY_X_1 = 92;
	static final int PRIMARY_Y_1 = 971;
	static final int PRIMARY_X_2 = 123;
	static final int PRIMARY_Y_2 = 938;
	static final int PRIMARY_X_3 = 152;
	static final int PRIMARY_Y_3 = 912;
	static final int PRIMARY_X_4 = 180;
	static final int PRIMARY_Y_4 = 888;
	static final int PRIMARY_X_5 = 210;
	static final int PRIMARY_Y_5 = 864;
	static final int PRIMARY_X_6 = 239;
	static final int PRIMARY_Y_6 = 833;
	static final int PRIMARY_X_7 = 267;
	static final int PRIMARY_Y_7 = 810;
	static final int PRIMARY_X_8 = 296;
	static final int PRIMARY_Y_8 = 783;
	static final int PRIMARY_X_9 = 325;
	static final int PRIMARY_Y_9 = 759;
	static final int PRIMARY_X_10 = 355;
	static final int PRIMARY_Y_10 = 733;
	static final int PRIMARY_X_11 = 384;
	static final int PRIMARY_Y_11 = 705;
	static final int PRIMARY_X_12 = 409;
	static final int PRIMARY_Y_12 = 679;
	static final int PRIMARY_X_13 = 452;
	static final int PRIMARY_Y_13 = 641;
	static final int PRIMARY_X_14 = 510;
	static final int PRIMARY_Y_14 = 589;
	static final int PRIMARY_X_15 = 567;
	static final int PRIMARY_Y_15 = 539;
	static final int PRIMARY_X_16 = 627;
	static final int PRIMARY_Y_16 = 485;
	static final int PRIMARY_X_17 = 682;
	static final int PRIMARY_Y_17 = 433;
	static final int PRIMARY_X_18 = 740;
	static final int PRIMARY_Y_18 = 378;
	static final int PRIMARY_X_19 = 824;
	static final int PRIMARY_Y_19 = 306;
	static final int PRIMARY_X_20 = 910;
	static final int PRIMARY_Y_20 = 225;
	static final int PRIMARY_X_21 = 43;
	static final int PRIMARY_Y_21 = 847;
	static final int PRIMARY_X_22 = 74;
	static final int PRIMARY_Y_22 = 819;
	static final int PRIMARY_X_23 = 102;
	static final int PRIMARY_Y_23 = 797;
	static final int PRIMARY_X_24 = 129;
	static final int PRIMARY_Y_24 = 770;
	static final int PRIMARY_X_25 = 161;
	static final int PRIMARY_Y_25 = 743;
	static final int PRIMARY_X_26 = 191;
	static final int PRIMARY_Y_26 = 714;
	static final int PRIMARY_X_27 = 218;
	static final int PRIMARY_Y_27 = 692;
	static final int PRIMARY_X_28 = 244;
	static final int PRIMARY_Y_28 = 669;
	static final int PRIMARY_X_29 = 274;
	static final int PRIMARY_Y_29 = 641;
	static final int PRIMARY_X_30 = 305;
	static final int PRIMARY_Y_30 = 615;
	static final int PRIMARY_X_31 = 331;
	static final int PRIMARY_Y_31 = 589;
	static final int PRIMARY_X_32 = 361;
	static final int PRIMARY_Y_32 = 562;
	static final int PRIMARY_X_33 = 403;
	static final int PRIMARY_Y_33 = 522;
	static final int PRIMARY_X_34 = 461;
	static final int PRIMARY_Y_34 = 474;
	static final int PRIMARY_X_35 = 521;
	static final int PRIMARY_Y_35 = 415;
	static final int PRIMARY_X_36 = 576;
	static final int PRIMARY_Y_36 = 363;
	static final int PRIMARY_X_37 = 633;
	static final int PRIMARY_Y_37 = 311;
	static final int PRIMARY_X_38 = 690;
	static final int PRIMARY_Y_38 = 259;
	static final int PRIMARY_X_39 = 773;
	static final int PRIMARY_Y_39 = 183;
	static final int PRIMARY_X_40 = 860;
	static final int PRIMARY_Y_40 = 110;
	static final int PRIMARY_X_100 = 630;
	static final int PRIMARY_Y_100 = 590;

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
		case 20:
			result = PRIMARY_X_20;
			break;
		case 21:
			result = PRIMARY_X_21;
			break;
		case 22:
			result = PRIMARY_X_22;
			break;
		case 23:
			result = PRIMARY_X_23;
			break;
		case 24:
			result = PRIMARY_X_24;
			break;
		case 25:
			result = PRIMARY_X_25;
			break;
		case 26:
			result = PRIMARY_X_26;
			break;
		case 27:
			result = PRIMARY_X_27;
			break;
		case 28:
			result = PRIMARY_X_28;
			break;
		case 29:
			result = PRIMARY_X_29;
			break;
		case 30:
			result = PRIMARY_X_30;
			break;
		case 31:
			result = PRIMARY_X_31;
			break;
		case 32:
			result = PRIMARY_X_32;
			break;
		case 33:
			result = PRIMARY_X_33;
			break;
		case 34:
			result = PRIMARY_X_34;
			break;
		case 35:
			result = PRIMARY_X_35;
			break;
		case 36:
			result = PRIMARY_X_36;
			break;
		case 37:
			result = PRIMARY_X_37;
			break;
		case 38:
			result = PRIMARY_X_38;
			break;
		case 39:
			result = PRIMARY_X_39;
			break;
		case 40:
			result = PRIMARY_X_40;
			break;
		case 100:
			result = PRIMARY_X_100;
			break;
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
		case 20:
			result = PRIMARY_Y_20;
			break;
		case 21:
			result = PRIMARY_Y_21;
			break;
		case 22:
			result = PRIMARY_Y_22;
			break;
		case 23:
			result = PRIMARY_Y_23;
			break;
		case 24:
			result = PRIMARY_Y_24;
			break;
		case 25:
			result = PRIMARY_Y_25;
			break;
		case 26:
			result = PRIMARY_Y_26;
			break;
		case 27:
			result = PRIMARY_Y_27;
			break;
		case 28:
			result = PRIMARY_Y_28;
			break;
		case 29:
			result = PRIMARY_Y_29;
			break;
		case 30:
			result = PRIMARY_Y_30;
			break;
		case 31:
			result = PRIMARY_Y_31;
			break;
		case 32:
			result = PRIMARY_Y_32;
			break;
		case 33:
			result = PRIMARY_Y_33;
			break;
		case 34:
			result = PRIMARY_Y_34;
			break;
		case 35:
			result = PRIMARY_Y_35;
			break;
		case 36:
			result = PRIMARY_Y_36;
			break;
		case 37:
			result = PRIMARY_Y_37;
			break;
		case 38:
			result = PRIMARY_Y_38;
			break;
		case 39:
			result = PRIMARY_Y_39;
			break;
		case 40:
			result = PRIMARY_Y_40;
			break;
		case 100:
			result = PRIMARY_Y_100;
			break;
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
