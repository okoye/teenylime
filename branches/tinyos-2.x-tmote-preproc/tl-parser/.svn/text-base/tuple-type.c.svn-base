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
 * *	$Id: tuple-type.c 843 2009-05-18 08:46:04Z sguna $
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


#include <stdlib.h>
#include <string.h>
#include "tuple-type.h"
#include "tuple-print.h"
#include "file_searcher.h"


static FILE *header_file = NULL, *code_file = NULL;
static struct tuple_node *tuple_list = NULL, *last_tuple;
struct field_node *field_list = NULL, *last_field;
static int tuple_number;
static int last_tuple_id;

static int field_count[MAX_TUPLE_TYPES];
static int crt_field_count = 0;
static int max_size_tuple = -1;
static int max_neighbor_tuple = -1;

int open_files(char *filename)
{
    char new_name[256];
    char *plain_file = extract_filename(filename);

    strncpy(new_name, plain_file, 253);
    strcat(new_name, ".c");
    code_file = fopen(new_name, "w");
    printf("creating code file '%s'\n", new_name);
    if (code_file == NULL) {
        fprintf(stderr, "unable to open file %s\n", filename);
        return -1;
    }
    
    strncpy(new_name, plain_file, 253);
    strcat(new_name, ".h");
    header_file = fopen(new_name, "w");
    printf("creating header file '%s'\n", new_name);
    if (header_file == NULL) {
        fprintf(stderr, "unable to open file %s\n", filename);
        return -1;
    }

    print_file_headers(header_file, code_file, plain_file, new_name);

    return 0;
}



void close_files()
{
    print_cmp_function(code_file, tuple_number);
    print_replace_function(code_file, tuple_number);
//    print_istemplate_function(header_file, code_file, tuple_number);
    print_sizeof_function(code_file, tuple_number);
    print_copy_function(code_file, tuple_number);
    print_field_count(code_file, field_count, tuple_number); 
    
    print_file_footers(header_file, code_file, max_size_tuple,
            max_neighbor_tuple);
    
    fclose(header_file);
    fclose(code_file);
}

static void clear_field_list()
{
    crt_field_count = 0;
    if (field_list == NULL)
        return;
    struct field_node *iterator, *next;
    for (iterator = field_list; iterator != NULL; iterator = next) {
        next = iterator->next;
        free(iterator->type);
        free(iterator);
    }
    field_list = NULL;
}


void new_tuple()
{
    clear_field_list();
}


static int get_type_size(char *type);


int add_attribute(char *attr_type)
{
    struct field_node *new_node = malloc(sizeof(struct field_node));
    if (new_node == NULL)
        return -1;
    new_node->next = NULL;
    new_node->type = strdup(attr_type);
    if (new_node->type == NULL)
        return -1;
    crt_field_count++;
    if (field_list == NULL) {
        last_field = field_list = new_node;
        return get_type_size(attr_type);
    }
    last_field->next = new_node;
    last_field = new_node;
    return get_type_size(attr_type);
}


static int compare_tuple(struct tuple_node *tuple)
{
    struct field_node *i1, *i2;

    for (i1 = field_list, i2 = tuple->field_list ; i1 != NULL && i2 != NULL;
            i1 = i1->next, i2 = i2->next) {
        if (strcmp(i1->type, i2->type))
            return 0;
    }
    if (i2 != i1)
        return 0;
    return 1;
}


static int find_existing_tuple(int is_neighbor_tuple)
{
    int i;
    if (tuple_list == NULL)
        return -1;

    struct tuple_node *iterator;
    for (iterator = tuple_list, i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        if (compare_tuple(iterator)) {
            if (is_neighbor_tuple)
                iterator->is_neighbor_tuple = 1;
            return i;
        }
    }
    return -1;
}


static void warn_tuple(FILE *file, struct tuple_node *tuple)
{
    fprintf(file, "<");
    struct field_node *iterator;
    for (iterator = tuple->field_list; iterator != NULL;
            iterator = iterator->next) {
        fprintf(file, "%s", iterator->type);
        if (iterator->next)
            fprintf(file, ", ");
    }
    fprintf(file, ">");
}


static int add_tuple(int is_neighbor_tuple)
{
    struct tuple_node *new_tuple = malloc(sizeof(struct tuple_node));
    static struct tuple_node *neighbor_tuple = NULL;
    if (new_tuple == NULL)
        return -1;
    new_tuple->next = NULL;
    new_tuple->field_list = field_list;
    new_tuple->is_neighbor_tuple = is_neighbor_tuple;
    if (is_neighbor_tuple) {
        if (neighbor_tuple != NULL) {
            fprintf(stderr, "Warning: neighbor tuple type redefinition: ");
            warn_tuple(stderr, new_tuple);
            fprintf(stderr, "\nPrevious definition was: ");
            warn_tuple(stderr, neighbor_tuple);
            fprintf(stderr, "\n");
        }
        neighbor_tuple = new_tuple;
    }
    field_list = NULL;

    field_count[tuple_number] = crt_field_count;
    crt_field_count = 0;
    tuple_number++;

    if (tuple_list == NULL) {
        tuple_list = last_tuple = new_tuple;
        return 0;
    }
    
    last_tuple->next = new_tuple;
    last_tuple = new_tuple;
    return 0;
}

static int count_fields(struct field_node *iterator)
{
    int count = 0;
    while (iterator != NULL) {
        count++;
        iterator = iterator->next;
    }

    return count;
}

static void print_type(struct field_node *iterator, int tuple_id)
{
    int i;
    
    print_tuple_header(header_file, tuple_id);
    print_tuple_match_types(header_file, count_fields(iterator));
    for (i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_tuple_field(header_file, i, iterator->type);
    }
    print_tuple_footer(header_file, tuple_id);
}


static int flush_tuple(int is_neighbor_tuple)
{
    if (field_list == NULL)
        return -1;
    
    int i = find_existing_tuple(is_neighbor_tuple);
    if (i >= 0)
        return i;

    if (add_tuple(is_neighbor_tuple) < 0)
        return -1;
    return tuple_number - 1;
}


void print_tuple_id(FILE *file, int is_neighbor_tuple)
{
    int id = flush_tuple(is_neighbor_tuple);
    if (id < 0) {
        fprintf(stderr, "error adding tuple\n");
        exit(-1);
    }
    last_tuple_id = id;
    if (file != NULL)
        fprintf(file, "%d", id);
}


void print_tuple_type(FILE *file, int is_neighbor_tuple)
{
    int id = flush_tuple(is_neighbor_tuple);
    if (id < 0) {
        fprintf(stderr, "error adding tuple\n");
        exit(-1);
    }
    last_tuple_id = id;
    if (file != NULL)
        fprintf(file, "tuple_%d_t ", id); 
}


int get_last_tuple_id()
{
    return last_tuple_id; 
}


static int get_basic_type_size(char *type)
{
    int basic_size = 2;
    
    if (!strncmp(type, "uint8_t", strlen("uint8_t")) || 
            !strncmp(type, "char", strlen("char")))
        basic_size = 1;

    return basic_size;
}


int get_array_length(char *type)
{
    char *position = strchr(type, '[') + 1;
    int array_length = atoi(position);

    if (get_basic_type_size(type) == 1 && array_length % 2 == 1)
        return array_length + 1;
    return array_length;
}



static int get_array_type_size(char *type)
{
    return get_array_length(type) * get_basic_type_size(type);
}


static int get_type_size(char *type)
{
    if (strchr(type, '['))
        return get_array_type_size(type);
    if (!strcmp(type, "uint8_t"))
        return 2;
    if (!strcmp(type, "uint16_t"))
        return 2;
    if (!strcmp(type, "uint32_t"))
        return 4;
    if (!strcmp(type, "char"))
        return 2;
    if (!strcmp(type, "float"))
        return 2;
    if (!strcmp(type, "lqi"))
        return 2;
    if (!strcmp(type, "rssi"))
        return 2;

    return 0;
}



static int serialize_tuple_fields(FILE *out, struct field_node *i, int *size)
{
    int n;
    *size = 0;
    for (n = 0; i != NULL; i = i->next) {
        int s = get_type_size(i->type);
        if (s == 0)
            continue;
        n++;
        *size += s;
        fprintf(out, "%s\n", i->type);
    }
    return n;
}


static void print_field_types(struct field_node *iterator, int tuple_id)
{
    int i;

    print_field_types_array_header(code_file, tuple_id);

    for (i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_field_type(code_file, iterator->type);
    }

    print_field_types_array_footer(code_file, tuple_id);
}


static void print_field_sizes(struct field_node *iterator, int tuple_id)
{
    int i;

    print_field_sizes_array_header(code_file, tuple_id);

    for (i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_field_size(code_file, get_type_size(iterator->type));
    }

    print_field_sizes_array_footer(code_file, tuple_id);
}


static int internal_contains_replaceable(struct field_node *field_list)
{
    struct field_node *iterator;
    for (iterator = field_list; iterator != NULL; iterator = iterator->next)
        if (!strcmp(iterator->type, "rssi") || !strcmp(iterator->type, "lqi"))
            return 1;
    return 0;
}


int contains_replaceable(int tuple_id)
{
    struct tuple_node *iterator;
    int i;

    for (iterator = tuple_list, i = 0; iterator != NULL &&  i < tuple_id;
            iterator = iterator->next, i++);
    if (iterator == NULL || i != tuple_id)
        return 0;
    return internal_contains_replaceable(iterator->field_list);
}


void print_tuples()
{
    struct tuple_node *iterator;
    int i;

    for (iterator = tuple_list, i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_type(iterator->field_list, i);
        print_tuple_cmp_function(code_file, i, iterator->field_list);
        print_tuple_copy_function(code_file, i, iterator->field_list);
        if (internal_contains_replaceable(iterator->field_list))
            print_tuple_replace_function(code_file, i, iterator->field_list);
//        print_tuple_istemplate_function(code_file, i, iterator->field_list);
    }

    print_header_field_types_function(code_file);
    for (iterator = tuple_list, i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_field_types(iterator->field_list, i);
    }
    print_footer_field_types_function(code_file, tuple_number);

    print_header_field_sizes_function(code_file);
    for (iterator = tuple_list, i = 0; iterator != NULL;
            iterator = iterator->next, i++) {
        print_field_sizes(iterator->field_list, i);
    }
    print_footer_field_sizes_function(code_file, tuple_number);
}


static void serialize_tuple_types(FILE *out)
{
    struct tuple_node *iterator;
    int i;
    for (i = 0, iterator = tuple_list; iterator != NULL;
            iterator = iterator->next, i++) {
        int n, size;
        n = serialize_tuple_fields(out, iterator->field_list, &size);
        char *type = "tuple";
        if (iterator->is_neighbor_tuple)
            type = "neighborTuple";
        // TODO remove 6 (representing tuple header)
        fprintf(out, "%s done - tuple_%d_t: %d field(s) and %d bytes\n\n", 
                type, i, n, 6 + size + n + n % 2);
    }
}


static void deserialize_tuple_types(FILE *in)
{
    char buf[256];
    tuple_number = 0;
    int field_size = 0;
    int max_size = 0;
    int max_neighbor = 0;

    while (!feof(in)) {
        fgets(buf, sizeof(buf), in);
        if (feof(in))
            break;
        int basic_tuple = !strncmp(buf, "tuple done", strlen("tuple done")); 
        int neighbor_tuple = !strncmp(buf, "neighborTuple done",
                strlen("neighborTuple done")); 
        if (basic_tuple || neighbor_tuple) {
            add_tuple(neighbor_tuple);
            if (field_size > max_size) {
                max_size = field_size;
                max_size_tuple = tuple_number - 1;
            }
            if (field_size > max_neighbor && neighbor_tuple) {
                max_neighbor = field_size;
                max_neighbor_tuple = tuple_number - 1;
            }
            field_size = 0;
            continue;
        }
        if (strlen(buf) == 0)
            continue;
        buf[strlen(buf) - 1] = 0;
        if (get_type_size(buf) == 0)
            continue;
        field_size += add_attribute(buf);
    }
}

int load_types(char *filename)
{
    FILE *types_file = fopen(filename, "r");
    if (types_file == NULL)
        return -1;
    deserialize_tuple_types(types_file);
    fclose(types_file);
    return 0;
}

int save_types(char *filename)
{
    FILE *types_file = fopen(filename, "w");
    if (types_file == NULL)
        return -1;
    serialize_tuple_types(types_file);
    fclose(types_file);
    return 0;
}




