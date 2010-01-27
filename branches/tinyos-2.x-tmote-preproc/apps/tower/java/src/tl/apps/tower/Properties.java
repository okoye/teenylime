/***
 * * PROJECT
 * *    TeenyLIME
 * * VERSION
 * *    $LastChangedRevision: 1009 $
 * * DATE
 * *    $LastChangedDate: 2010-01-08 02:57:33 -0600 (Fri, 08 Jan 2010) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: mceriotti $
 * *
 * *	$Id: Properties.java 1009 2010-01-08 08:57:33Z mceriotti $
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

package tl.apps.tower;

import java.awt.Color;

import tl.lib.dataCollection.data.SourceId;

public class Properties {

	public final static int TUPLE_DISS_PAYLOAD_SIZE = 26;
	public final static int TUPLE_MSG_PAYLOAD_SIZE = 26;

	public final static int TREE_REFRESH = 18;

	public final static int CACHE_SIZE = 10;

	public final static String LOG_DIR_NAME = "tower_log";
	public final static String RAW_VIBR_DIR_NAME = "vibr";
	
	public final static boolean LOG_MESSAGES = true;
	
	// In milliseconds
	public static final long MAX_NOSEEN_INTERVAL = 240000;

	public static final int SINK_ADDRESS = 0;

	public static final int X_MAX = 1000;
	public static final int Y_MAX = 1000;
	public static final int MOTE_RADIUS = 10;

	static final int PRIMARY_X_0 = 347;
	static final int PRIMARY_Y_0 = 139;
	static final int PRIMARY_X_138 = 149;
	static final int PRIMARY_Y_138 = 264;
	static final int PRIMARY_X_141 = 186;
	static final int PRIMARY_Y_141 = 282;
	static final int PRIMARY_X_142 = 359;
	static final int PRIMARY_Y_142 = 344;
	static final int PRIMARY_X_143 = 297;
	static final int PRIMARY_Y_143 = 733;
	static final int PRIMARY_X_144 = 157;
	static final int PRIMARY_Y_144 = 562;
	static final int PRIMARY_X_145 = 351;
	static final int PRIMARY_Y_145 = 194;
	static final int PRIMARY_X_146 = 157;
	static final int PRIMARY_Y_146 = 373;
	static final int PRIMARY_X_147 = 60;
	static final int PRIMARY_Y_147 = 526;
	static final int PRIMARY_X_148 = 181;
	static final int PRIMARY_Y_148 = 658;
	static final int PRIMARY_X_149 = 254;
	static final int PRIMARY_Y_149 = 368;
	static final int PRIMARY_X_150 = 90;
	static final int PRIMARY_Y_150 = 672;
	static final int PRIMARY_X_151 = 310;
	static final int PRIMARY_Y_151 = 657;
	static final int PRIMARY_X_152 = 592;
	static final int PRIMARY_Y_152 = 552;
	static final int PRIMARY_X_153 = 170;
	static final int PRIMARY_Y_153 = 320;
	static final int PRIMARY_X_154 = 195;
	static final int PRIMARY_Y_154 = 768;

	static final int SECONDARY_X_0 = 891;
	static final int SECONDARY_Y_0 = 205;
	static final int SECONDARY_X_138 = 744;
	static final int SECONDARY_Y_138 = 211;
	static final int SECONDARY_X_141 = 777;
	static final int SECONDARY_Y_141 = 149;
	static final int SECONDARY_X_142 = 903;
	static final int SECONDARY_Y_142 = 291;
	static final int SECONDARY_X_143 = 908;
	static final int SECONDARY_Y_143 = 470;
	static final int SECONDARY_X_144 = 790;
	static final int SECONDARY_Y_144 = 536;
	static final int SECONDARY_X_145 = 915;
	static final int SECONDARY_Y_145 = 241;
	static final int SECONDARY_X_146 = 753;
	static final int SECONDARY_Y_146 = 245;
	static final int SECONDARY_X_147 = 731;
	static final int SECONDARY_Y_147 = 850;
	static final int SECONDARY_X_148 = 821;
	static final int SECONDARY_Y_148 = 564;
	static final int SECONDARY_X_149 = 845;
	static final int SECONDARY_Y_149 = 246;
	static final int SECONDARY_X_150 = 752;
	static final int SECONDARY_Y_150 = 564;
	static final int SECONDARY_X_151 = 914;
	static final int SECONDARY_Y_151 = 564;
	static final int SECONDARY_X_152 = 906;
	static final int SECONDARY_Y_152 = 348;
	static final int SECONDARY_X_153 = 790;
	static final int SECONDARY_Y_153 = 230;
	static final int SECONDARY_X_154 = 855;
	static final int SECONDARY_Y_154 = 564;

	static final Color COLOR_0 = Color.red;
	static final Color COLOR_141 = Color.darkGray;
	static final Color COLOR_142 = new Color(125, 125, 250);
	static final Color COLOR_143 = new Color(0, 250, 140);
	static final Color COLOR_144 = new Color(200, 0, 125);
	static final Color COLOR_145 = Color.blue;
	static final Color COLOR_146 = Color.magenta;
	static final Color COLOR_147 = new Color(250, 125, 0);
	static final Color COLOR_148 = new Color(88, 0, 147);
	static final Color COLOR_149 = new Color(0, 125, 0);
	static final Color COLOR_150 = new Color(0, 125, 125);
	static final Color COLOR_151 = new Color(80, 0, 0);
	static final Color COLOR_152 = new Color(125, 125, 0);
	static final Color COLOR_153 = new Color(0, 0, 125);
	static final Color COLOR_154 = Color.green;

	public static int initialPrimaryXPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		case 0:
			result = PRIMARY_X_0;
			break;
		case 138:
			result = PRIMARY_X_138;
			break;
		case 141:
			result = PRIMARY_X_141;
			break;
		case 142:
			result = PRIMARY_X_142;
			break;
		case 143:
			result = PRIMARY_X_143;
			break;
		case 144:
			result = PRIMARY_X_144;
			break;
		case 145:
			result = PRIMARY_X_145;
			break;
		case 146:
			result = PRIMARY_X_146;
			break;
		case 147:
			result = PRIMARY_X_147;
			break;
		case 148:
			result = PRIMARY_X_148;
			break;
		case 149:
			result = PRIMARY_X_149;
			break;
		case 150:
			result = PRIMARY_X_150;
			break;
		case 151:
			result = PRIMARY_X_151;
			break;
		case 152:
			result = PRIMARY_X_152;
			break;
		case 153:
			result = PRIMARY_X_153;
			break;
		case 154:
			result = PRIMARY_X_154;
			break;
		default:
			result = (int) (Math.random() * 600);
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
		case 0:
			result = PRIMARY_Y_0;
			break;
		case 138:
			result = PRIMARY_Y_138;
			break;
		case 141:
			result = PRIMARY_Y_141;
			break;
		case 142:
			result = PRIMARY_Y_142;
			break;
		case 143:
			result = PRIMARY_Y_143;
			break;
		case 144:
			result = PRIMARY_Y_144;
			break;
		case 145:
			result = PRIMARY_Y_145;
			break;
		case 146:
			result = PRIMARY_Y_146;
			break;
		case 147:
			result = PRIMARY_Y_147;
			break;
		case 148:
			result = PRIMARY_Y_148;
			break;
		case 149:
			result = PRIMARY_Y_149;
			break;
		case 150:
			result = PRIMARY_Y_150;
			break;
		case 151:
			result = PRIMARY_Y_151;
			break;
		case 152:
			result = PRIMARY_Y_152;
			break;
		case 153:
			result = PRIMARY_Y_153;
			break;
		case 154:
			result = PRIMARY_Y_154;
			break;
		default:
			result = (int) (Math.random() * Y_MAX);
		}
		if (result < 2 * Properties.MOTE_RADIUS)
			result = 2 * Properties.MOTE_RADIUS;
		if (result > X_MAX - 2 * Properties.MOTE_RADIUS)
			result = X_MAX - 2 * Properties.MOTE_RADIUS;
		return result;
	}

	public static int initialSecondaryXPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		case 0:
			result = SECONDARY_X_0;
			break;
		case 138:
			result = SECONDARY_X_138;
			break;
		case 141:
			result = SECONDARY_X_141;
			break;
		case 142:
			result = SECONDARY_X_142;
			break;
		case 143:
			result = SECONDARY_X_143;
			break;
		case 144:
			result = SECONDARY_X_144;
			break;
		case 145:
			result = SECONDARY_X_145;
			break;
		case 146:
			result = SECONDARY_X_146;
			break;
		case 147:
			result = SECONDARY_X_147;
			break;
		case 148:
			result = SECONDARY_X_148;
			break;
		case 149:
			result = SECONDARY_X_149;
			break;
		case 150:
			result = SECONDARY_X_150;
			break;
		case 151:
			result = SECONDARY_X_151;
			break;
		case 152:
			result = SECONDARY_X_152;
			break;
		case 153:
			result = SECONDARY_X_153;
			break;
		case 154:
			result = SECONDARY_X_154;
			break;
		default:
			result = (int) (Math.random() * X_MAX) % 200 + 700;
		}
		if (result < 2 * Properties.MOTE_RADIUS)
			result = 2 * Properties.MOTE_RADIUS;
		if (result > X_MAX - 2 * Properties.MOTE_RADIUS)
			result = X_MAX - 2 * Properties.MOTE_RADIUS;
		return result;
	}

	public static int initialSecondaryYPosition(SourceId identifier) {
		int result;
		switch (identifier.address()) {
		case 0:
			result = SECONDARY_Y_0;
			break;
		case 138:
			result = SECONDARY_Y_138;
			break;
		case 141:
			result = SECONDARY_Y_141;
			break;
		case 142:
			result = SECONDARY_Y_142;
			break;
		case 143:
			result = SECONDARY_Y_143;
			break;
		case 144:
			result = SECONDARY_Y_144;
			break;
		case 145:
			result = SECONDARY_Y_145;
			break;
		case 146:
			result = SECONDARY_Y_146;
			break;
		case 147:
			result = SECONDARY_Y_147;
			break;
		case 148:
			result = SECONDARY_Y_148;
			break;
		case 149:
			result = SECONDARY_Y_149;
			break;
		case 150:
			result = SECONDARY_Y_150;
			break;
		case 151:
			result = SECONDARY_Y_151;
			break;
		case 152:
			result = SECONDARY_Y_152;
			break;
		case 153:
			result = SECONDARY_Y_153;
			break;
		case 154:
			result = SECONDARY_Y_154;
			break;
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
		case 141:
			result = COLOR_141;
			break;
		case 142:
			result = COLOR_142;
			break;
		case 143:
			result = COLOR_143;
			break;
		case 144:
			result = COLOR_144;
			break;
		case 145:
			result = COLOR_145;
			break;
		case 146:
			result = COLOR_146;
			break;
		case 147:
			result = COLOR_147;
			break;
		case 148:
			result = COLOR_148;
			break;
		case 149:
			result = COLOR_149;
			break;
		case 150:
			result = COLOR_150;
			break;
		case 151:
			result = COLOR_151;
			break;
		case 152:
			result = COLOR_152;
			break;
		case 153:
			result = COLOR_153;
			break;
		case 154:
			result = COLOR_154;
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
