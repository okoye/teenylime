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
 * *	$Id: tuple-print.c 843 2009-05-18 08:46:04Z sguna $
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
#include <ctype.h>
#include <stdlib.h>
#include "tuple-print.h"
#include "tuple-type.h"
#include "attribution.h"


void print_file_headers(FILE *header_file, FILE *code_file,
        char *filename, char *new_name)
{
    fprintf(header_file, "#ifndef __%s_h\n", filename);
    fprintf(header_file, "#define __%s_h\n\n", filename);
    
    fprintf(header_file, "#include \"TupleSpace.h\"\n\n");

    fprintf(header_file, "#ifdef TOSSIM\n");
    fprintf(header_file, "typedef nx_uint8_t nx_bool;\n");
    fprintf(header_file, "#endif\n\n");

    fprintf(header_file, "enum {\n");
    fprintf(header_file, "\tTYPE_INVALID = 0,\n");
    fprintf(header_file, "\tTYPE_UINT8_T = 2,\n");
    fprintf(header_file, "\tTYPE_UINT16_T,\n");
    fprintf(header_file, "\tTYPE_UINT32_T,\n");
    fprintf(header_file, "\tTYPE_FLOAT,\n");
    fprintf(header_file, "\tTYPE_CHAR,\n");
    fprintf(header_file, "\tTYPE_STR,\n");
    fprintf(header_file, "\tTYPE_LQI,\n");
    fprintf(header_file, "\tTYPE_RSSI\n");
    fprintf(header_file, "};\n\n");

    fprintf(header_file, "#define TYPE_ARRAY 0x8000\n\n");
    
    fprintf(header_file, "#define NEXT_TUPLE(t) \\\n"
                         "\t((tuple *) ((char *)(t) + "
                         "call TLObjects.tuple_sizeof((tuple *) (t))))\n");
    
    fprintf(header_file, "\n");

    fprintf(code_file, "#include \"%s\"\n", new_name);
    fprintf(code_file, "#include \"TupleSpace.h\"\n\n");

    fprintf(code_file, "module TLObjectsParsed {\n");
    fprintf(code_file, "\tprovides interface TLObjects;\n");
    fprintf(code_file, "}\n\n");
    fprintf(code_file, "implementation {\n\n");

}


void print_file_footers(FILE *header_file, FILE *code_file, int max_size_tuple,
        int max_neighbor_tuple)
{
    if (max_size_tuple != -1)
        fprintf(header_file, "#define MAX_TUPLE_SIZE sizeof(tuple_%d_t)\n",
                max_size_tuple);
    if (max_neighbor_tuple == -1) {
        max_neighbor_tuple = 0;
        fprintf(header_file,
                "#warning No neighbor tuple defined. Disregard this if you are"
                " using the default neighbor tuple.\n");
    }
    fprintf(header_file,
            "#define NEIGHBOR_TUPLE_SIZE sizeof(tuple_%d_t)\n\n",
            max_neighbor_tuple);

    fprintf(header_file,
            "#ifdef TUPLE_MSG_DATA_SIZE\n"
            "#warning Using user defined message data size.\n"
            "#else\n"
            "#define TUPLE_MSG_DATA_SIZE "
            "(sizeof(tuple_%d_t) + sizeof(tuple_%d_t))\n"
            "#endif\n\n",
            max_neighbor_tuple, max_size_tuple);
    fprintf(header_file, "#endif\n");
    fprintf(code_file, "\n}\n");
}


void print_tuple_header(FILE *header_file, int tuple_id)
{
    fprintf(header_file, "nx_struct tuple_%d {\n"
                        "\tnx_uint16_t logicalTime;\n"
                        "\tnx_uint16_t expireIn;\n"
                        "\tnx_uint8_t type;\n"
                        "\tnx_uint8_t flags;\n",
                        tuple_id);
}


void print_tuple_match_types(FILE *header_file, int count)
{
    if (count & 1)
        count++;
    fprintf(header_file, "\tnx_uint8_t match_types[%d];\n\n", count);
}


static char * array_length_as_string(char *field_type)
{
    static char array_size[IDENTIFIER_SIZE];
    if (!strchr(field_type, '['))
        return "";
    snprintf(array_size, IDENTIFIER_SIZE, "[%d]", get_array_length(field_type));
    return array_size;
}

static char * get_basic_type(char *field_type)
{
    static char basic_type[IDENTIFIER_SIZE];
    strncpy(basic_type, field_type, IDENTIFIER_SIZE);
    *(strchr(basic_type, '[')) = 0;
    return basic_type;
}

static char * align_type(char *field_type)
{
    if (strchr(field_type, '['))
        return get_basic_type(field_type);
    if (strcmp(field_type, "char") == 0)
        return "uint16_t";
    if (strcmp(field_type, "uint8_t") == 0)
        return "uint16_t";
    if (strcmp(field_type, "byte") == 0)
        return "uint16_t";
    if (strcmp(field_type, "bool") == 0)
        return "uint16_t";
    if (strcmp(field_type, "rssi") == 0)
        return "uint16_t";
    if (strcmp(field_type, "lqi") == 0)
        return "uint16_t";
    return field_type;
}

void print_tuple_field(FILE *header_file, int field_id, char *field_type)
{
    fprintf(header_file, "\tnx_%s value%d%s;\n",
                         align_type(field_type), field_id,
                         array_length_as_string(field_type));
}


void print_tuple_footer(FILE *header_file, int tuple_id)
{
    fprintf(header_file, "};\n"
                         "typedef nx_struct tuple_%d tuple_%d_t;\n\n",
                         tuple_id, tuple_id);
}


void print_cmp_function(FILE *code_file, int tuple_number)
{
    int i;

    fprintf(code_file,
            "command bool TLObjects.compare_tuple(tuple *t1, tuple *t2)\n"
            "{\n"
            "\tif (t1->type != t2->type)\n"
            "\t\treturn FALSE;\n"
            "\tif (t1->flags != t2->flags)\n"
            "\t\treturn FALSE;\n\n");

    fprintf(code_file,
            "\tswitch (t1->type) {\n");

    for(i = 0; i < tuple_number; i++) 
        fprintf(code_file,
                "\t\tcase %d:\n"
                "\t\t\treturn compare_tuple_%d((tuple_%d_t *) t1, (tuple_%d_t *) t2);\n",
                i, i, i, i);

    fprintf(code_file,
            "\t}\n"
            "\treturn FALSE;\n"
            "}\n\n\n");
}


void print_replace_function(FILE *code_file, int tuple_number)
{
    int i;

    fprintf(code_file,
            "command void TLObjects.replace_indicator(tuple *t,\n"
            "\t\t\tuint16_t lqi, uint16_t rssi)\n"
            "{\n");

    fprintf(code_file,
            "\tswitch (t->type) {\n");

    for(i = 0; i < tuple_number; i++) {
        if (!contains_replaceable(i))
            continue;
        fprintf(code_file,
                "\t\tcase %d:\n"
                "\t\t\treturn replace_tuple_%d((tuple_%d_t *) t, lqi, rssi);\n",
                i, i, i);
    }

    fprintf(code_file,
            "\t}\n"
            "}\n\n\n");
}



void print_istemplate_function(FILE *header_file, FILE *code_file,
        int tuple_number)
{
    int i;
    
    fprintf(code_file,
            "command bool TLObjects.istemplate_tuple(tuple *t)\n"
            "{\n");

    fprintf(code_file,
            "\tswitch (t->type) {\n");

    for(i = 0; i < tuple_number; i++) 
        fprintf(code_file,
                "\t\tcase %d:\n"
                "\t\t\treturn istemplate_tuple_%d((tuple_%d_t *) t);\n",
                i, i, i);

    fprintf(code_file,
            "\t}\n"
            "\treturn FALSE;\n"
            "}\n\n\n");
}


void print_sizeof_function(FILE *code_file, int tuple_number)
{
    int i;

    fprintf(code_file,
            "int my_tuple_sizeof(tuple *t)\n"
            "{\n");
    fprintf(code_file,
            "\tswitch (t->type) {\n");

    for(i = 0; i < tuple_number; i++) 
        fprintf(code_file,
                "\t\tcase %d:\n"
                "\t\t\treturn sizeof(tuple_%d_t);\n",
                i, i);

    fprintf(code_file,
            "\t}\n\n"
            "\treturn 0;\n"
            "}\n\n\n");

    fprintf(code_file,
            "command int TLObjects.tuple_sizeof(tuple *t)\n"
            "{\n"
            "\treturn my_tuple_sizeof(t);\n"
            "}\n\n\n");
}


void print_copy_function(FILE *code_file, int tuple_number)
{   
    int i;
    fprintf(code_file,
            "command int TLObjects.copy_tuple(tuple *dest, tuple *src)\n"
            "{\n"
            "\tdest->logicalTime = src->logicalTime;\n"
            "\tdest->expireIn = src->expireIn;\n"
            "\tdest->type = src->type;\n"
            "\tdest->flags = src->flags;\n\n");

    fprintf(code_file,
            "\tswitch (src->type) {\n");

    for(i = 0; i < tuple_number; i++) 
        fprintf(code_file,
                "\t\tcase %d:\n"
                "\t\t\tcopy_tuple_%d((tuple_%d_t *) dest, (tuple_%d_t *) src);\n"
                "\t\t\tbreak;\n",
                i, i, i, i);

    fprintf(code_file,
            "\t}\n\n"
            "\treturn my_tuple_sizeof(src);\n"
            "}\n\n\n");
}


static void print_basic_type_cmp(FILE *code_file, char *type, int index)
{
    fprintf(code_file,
            "\tif (field_%s_cmp(t1->match_types[%d], t2->match_types[%d],\n"
            " \t\tt1->value%d, t2->value%d) == FALSE)\n"
            "\t\treturn FALSE;\n",
            type, index, index, index, index); 

}


static void print_array_type_cmp(FILE *code_file, char *type, int index)
{
    fprintf(code_file,
            "\tif (field_array_%s_cmp(t1->match_types[%d], t2->match_types[%d],\n"
            "\t\t\tt1->value%d, t2->value%d, %d) == FALSE)\n"
            "\t\treturn FALSE;\n",
            get_basic_type(type), index, index, index, index,
            get_array_length(type)); 
}


void print_tuple_cmp_function(FILE *code_file, int tuple_id,
        struct field_node *field_list)
{
    struct field_node *iterator;
    int i;

    fprintf(code_file,
            "bool compare_tuple_%d(tuple_%d_t *t1, tuple_%d_t *t2)\n"
            "{\n",
            tuple_id, tuple_id, tuple_id);

    for (iterator = field_list, i = 0; 
            iterator != NULL; 
            iterator = iterator->next, i++) {
        if (strchr(iterator->type, '['))
            print_array_type_cmp(code_file, iterator->type, i);
        else
            print_basic_type_cmp(code_file, iterator->type, i);
    }
    fprintf(code_file, 
        "\treturn TRUE;\n"
        "}\n\n\n");
}


void print_tuple_replace_function(FILE *code_file, int tuple_id,
        struct field_node *field_list)
{
    struct field_node *iterator;
    int i;

    fprintf(code_file,
            "void replace_tuple_%d(tuple_%d_t *t, "
            "uint16_t lqi, uint16_t rssi)\n"
            "{\n",
            tuple_id, tuple_id);

    for (iterator = field_list, i = 0; 
            iterator != NULL; 
            iterator = iterator->next, i++) {
        if (!strcmp(iterator->type, "lqi"))
            fprintf(code_file, "\tt->value%d = lqi;\n", i);
        if (!strcmp(iterator->type, "rssi"))
            fprintf(code_file, "\tt->value%d = rssi;\n", i);
    }
    fprintf(code_file, "}\n\n\n");
}


static void print_basic_type_copy(FILE *code_file, char *type, int index)
{
    fprintf(code_file,
            "\tdest->value%d = src->value%d;\n"
            "\tdest->match_types[%d] = src->match_types[%d];\n"
            ,index, index, index, index); 

}


static void print_array_type_copy(FILE *code_file, char *type, int index)
{
    int i, n = get_array_length(type);
    for (i = 0; i < n; i++)
        fprintf(code_file,
                "\tdest->value%d[%d] = src->value%d[%d];\n",
                index, i, index, i);
    fprintf(code_file,
            "\tdest->match_types[%d] = src->match_types[%d];\n",
            index, index);
}


void print_tuple_copy_function(FILE *code_file, int tuple_id,
        struct field_node *field_list)
{
    struct field_node *iterator;
    int i;

    fprintf(code_file,
            "void copy_tuple_%d(tuple_%d_t *dest, tuple_%d_t *src)\n"
            "{\n",
            tuple_id, tuple_id, tuple_id);

    for (iterator = field_list, i = 0; 
            iterator != NULL; 
            iterator = iterator->next, i++) {
        if (strchr(iterator->type, '['))
            print_array_type_copy(code_file, iterator->type, i);
        else
            print_basic_type_copy(code_file, iterator->type, i);
    }

    fprintf(code_file,
            "}\n\n\n");
}


void print_tuple_istemplate_function(FILE *code_file, int tuple_id,
        struct field_node *field_list)
{
    struct field_node *iterator;
    int i;

    fprintf(code_file,
            "bool istemplate_tuple_%d(tuple_%d_t *t)\n"
            "{\n",
            tuple_id, tuple_id);

    for (iterator = field_list, i = 0; 
            iterator != NULL; 
            iterator = iterator->next, i++) {
        fprintf(code_file,
                "\tif (t->match_types[%d] != MATCH_ACTUAL)\n"
                "\t\treturn TRUE;\n",
                i);
    }
    fprintf(code_file, 
        "\treturn FALSE;\n"
        "}\n\n\n");
}


void print_field_count(FILE *code_file, int field_count[],
        int tuple_number)
{
    int i;
    fprintf(code_file, "command int TLObjects.field_count(int type_id)\n");
    fprintf(code_file, "{\n");
    fprintf(code_file, "\tint fields_per_type[] = {\n");
    for (i = 0; i < tuple_number; i++) {
        fprintf(code_file, "\t\t%d", field_count[i]);
        if (i != tuple_number - 1)
            fprintf(code_file, ",\n");
    }
    fprintf(code_file, "\n\t};\n\n");
    
    fprintf(code_file, "\tif (type_id < 0 || type_id >= %d)\n", tuple_number);
    fprintf(code_file, "\t\treturn 0;\n");

    fprintf(code_file, "\treturn fields_per_type[type_id];\n");
    fprintf(code_file, "}\n\n\n");
}


void print_header_field_types_function(FILE *code_file)
{
    fprintf(code_file, "command int TLObjects.get_field_type(int type_id, "
            "int field_no)\n");
    fprintf(code_file, "{\n");
    fprintf(code_file, "\tint result = TYPE_INVALID;\n");
}


void print_footer_field_types_function(FILE *code_file, int tuple_number)
{
    int i;
    fprintf(code_file, "\n\t switch (type_id) {\n");
    for (i = 0; i < tuple_number; i++) {
        fprintf(code_file, "\t\tcase %d:\n", i);
        fprintf(code_file, "\t\t\tif (field_no < 0 || "
                "field_no >= sizeof(tuple%d_fields) / 2 )\n",
                i);
        fprintf(code_file, "\t\t\t\tbreak;\n");
        fprintf(code_file, "\t\t\tresult = tuple%d_fields[field_no];\n", i);
        fprintf(code_file, "\t\t\tbreak;\n");
    }
    fprintf(code_file, "\t}\n");
    fprintf(code_file, "\treturn result;\n");
    fprintf(code_file, "}\n\n");
}


void print_field_types_array_header(FILE *code_file, int type_id)
{
    fprintf(code_file, "\tuint16_t tuple%d_fields[] = {\n", type_id);
}


void print_field_types_array_footer(FILE *code_file, int type_id)
{
    fprintf(code_file, "\t};\n");
}


static char *strtoupper(char *string)
{
    char *result = malloc(strlen(string) + 1), *i = result;
    while (*string != '\0') {
        if (islower(*string))
            *i = toupper(*string);
        else
            *i = *string;
        i++;
        string++;
    }
    *i = '\0';
    return result;
}

void print_field_type(FILE *code_file, char *type)
{
    char *upper;
    if (strchr(type, '[')) {
        upper = strtoupper(get_basic_type(type)); 
        fprintf(code_file, "\t\tTYPE_%s | TYPE_ARRAY,\n", upper);
    }
    else {
        upper = strtoupper(type);
        fprintf(code_file, "\t\tTYPE_%s,\n", upper);
    }
    free(upper);
}


void print_header_field_sizes_function(FILE *code_file)
{
    fprintf(code_file, "command size_t TLObjects.get_field_size(int type_id, "
            "int field_no)\n");
    fprintf(code_file, "{\n");
    fprintf(code_file, "\tsize_t result = 0;\n");
}


void print_footer_field_sizes_function(FILE *code_file, int tuple_number)
{
    int i;
    fprintf(code_file, "\n\t switch (type_id) {\n");
    for (i = 0; i < tuple_number; i++) {
        fprintf(code_file, "\t\tcase %d:\n", i);
        fprintf(code_file, "\t\t\tif (field_no < 0 || "
                "field_no >= sizeof(tuple%d_fields) / 2 )\n",
                i);
        fprintf(code_file, "\t\t\t\tbreak;\n");
        fprintf(code_file, "\t\t\tresult = tuple%d_fields[field_no];\n", i);
        fprintf(code_file, "\t\t\tbreak;\n");
    }
    fprintf(code_file, "\t}\n");
    fprintf(code_file, "\treturn result;\n");
    fprintf(code_file, "}\n\n");
}


void print_field_sizes_array_header(FILE *code_file, int type_id)
{
    fprintf(code_file, "\tuint16_t tuple%d_fields[] = {\n", type_id);
}


void print_field_sizes_array_footer(FILE *code_file, int type_id)
{
    fprintf(code_file, "\t};\n");
}


void print_field_size(FILE *code_file, int size)
{
    fprintf(code_file, "\t\t%d,\n", size);
}


