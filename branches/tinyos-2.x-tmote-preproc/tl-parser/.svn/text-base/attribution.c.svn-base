/***
 * * PROJECT
 * *    TeenyLIME 
 * * VERSION
 * *    $LastChangedRevision: 843 $
 * * DATE
 * *    $LastChangedDate: 2009-05-18 10:46:04 +0200 (Mon, 18 May 2009) $
 * * LAST_CHANGE_BY
 * *    $LastChangedBy: sguna $
 * *
 * *	$Id: attribution.c 843 2009-05-18 08:46:04Z sguna $
 * *
 * *   TeenyLIME - Transiently Shared Tuple Space Middleware for 
 * *               Wireless Sensor Networks
 * *
 * *   This program is free software; you can redistribute it and/or
 * *   modify it under the terms of the GNU General Public License
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

/**
 * TeenyLIME preprocessor.
 * 
 * @author Stefan Guna
 *         <a href="mailto:sguna@disi.unitn.it">sguna@disi.unitn.it</a>
 * 
 */

#include <string.h>
#include "attribution.h"
#include "symbol-table.h"

static char buffer[ATTR_BUF_SIZE];
static char *variable;
static char value_function[IDENTIFIER_SIZE];

static int field_counter = 0;

void reset_field_counter(char *identifier, char *flags)
{
    int type;
    if (find_symbol_type(identifier, &type)) {
        char tmp_buffer[ATTR_BUF_SIZE];
        snprintf(tmp_buffer, ATTR_BUF_SIZE, "(%s).expireIn = TIME_UNDEFINED; "
                "(%s).type = %d; "
                "(%s).flags = %s; ",
                identifier, identifier, type, identifier, flags);
        strncat(buffer, tmp_buffer, ATTR_BUF_SIZE - strlen(tmp_buffer) - 1);
    }
   field_counter = 0;
}

void reset_att_buffer()
{
    buffer[0] = 0;
}


void begin_attribution(char *identifier)
{
    variable = identifier;
    value_function[0] = 0;
}


int valid_function(char *value_function)
{
    if (!strcmp(value_function, "dontCare"))
        return 1;
    if (!strcmp(value_function, "lqiRead"))
        return 1;
    if (!strcmp(value_function, "rssiRead"))
        return 1;
    if (!strcmp(value_function, "actualField"))
        return 1;
    if (!strcmp(value_function, "greater"))
        return 1;
    if (!strcmp(value_function, "greaterEqual"))
        return 1;
    if (!strcmp(value_function, "lower"))
        return 1;
    if (!strcmp(value_function, "lowerEqual"))
        return 1;
    if (!strcmp(value_function, "different"))
        return 1;
    if (!strcmp(value_function, "equal"))
        return 1;
    if (!strcmp(value_function, "arrayField"))
        return 1;
    if (!strcmp(value_function, "maskTest"))
        return 1;
    return 0;
}

int set_value_function(char *function)
{
    if (!valid_function(function))
        return -1;
    strncpy(value_function, function, IDENTIFIER_SIZE);
    return 0;
}

static int add_justtype_field(char *type)
{
    char attribute[SET_BUF_SIZE];
    snprintf(attribute, SET_BUF_SIZE - 1,
            "(%s).match_types[%d] = %s",
            variable, field_counter, type);
    strncat(buffer, attribute, ATTR_BUF_SIZE - strlen(attribute) - 1);
    return 0;
}

static int add_typevalue_field(char *type)
{
    char attribute[SET_BUF_SIZE];
    snprintf(attribute, SET_BUF_SIZE - 1,
            " (%s).match_types[%d] = %s; (%s).value%d = ",
            variable, field_counter, type, variable, field_counter);
    strncat(buffer, attribute, ATTR_BUF_SIZE - strlen(attribute) - 1);
    return 0;
}


int begin_set_attribute()
{
    if (!strcmp(value_function, "dontCare"))
        return add_justtype_field("MATCH_DONT_CARE");
    if (!strcmp(value_function, "lqiRead"))
        return add_justtype_field("MATCH_DONT_CARE");
    if (!strcmp(value_function, "rssiRead"))
        return add_justtype_field("MATCH_DONT_CARE");
    if (!strcmp(value_function, "actualField"))
        return add_typevalue_field("MATCH_ACTUAL");
    if (!strcmp(value_function, "greater"))
        return add_typevalue_field("MATCH_GREATER");
    if (!strcmp(value_function, "greaterEqual"))
        return add_typevalue_field("MATCH_GREATER_EQUAL");
    if (!strcmp(value_function, "lower"))
        return add_typevalue_field("MATCH_LOWER");
    if (!strcmp(value_function, "lowerEqual"))
        return add_typevalue_field("MATCH_LOWER_EQUAL");
    if (!strcmp(value_function, "different"))
        return add_typevalue_field("MATCH_DIFFERENT");
    if (!strcmp(value_function, "equal"))
        return add_typevalue_field("MATCH_EQUAL");
    if (!strcmp(value_function, "arrayField"))
        return add_justtype_field("MATCH_ACTUAL");
    if (!strcmp(value_function, "maskTest"))
        return add_typevalue_field("MATCH_MASK");
    return -1;
}


void flush_member()
{
    strncat(buffer, ";", ATTR_BUF_SIZE - strlen(";") - 1);
    value_function[0] = 0;
    field_counter++;
}


void flush_attribution(FILE *output)
{
    fprintf(output, "%s", buffer);
}


void append_text(char *text)
{
    strncat(buffer, text, ATTR_BUF_SIZE - strlen(buffer) - 1);
}
