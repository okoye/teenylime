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
 * *	$Id: tuple-print.h 843 2009-05-18 08:46:04Z sguna $
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


#ifndef __TUPLE_PRINT_H
#define __TUPLE_PRINT_H

#include <stdio.h>
#include "tuple-type.h"

void print_file_headers(FILE *header_file, FILE *code_file, char *filename,
        char *new_name);
void print_file_footers(FILE *header_file, FILE *code_file,
        int max_size_tuple, int max_neighbor_tuple);

void print_tuple_header(FILE *header_file, int tuple_id);
void print_tuple_match_types(FILE *header_file, int count);
void print_tuple_field_faker(FILE *header_file);
void print_tuple_field(FILE *header_file, int field_id, char *field_type);
void print_tuple_footer(FILE *header_file, int tuple_id);

void print_cmp_function(FILE *code_file, int tuple_number);
void print_tuple_copy_function(FILE *code_file, int tuple_id,
        struct field_node *field_list);
void print_replace_function(FILE *code_file, int tuple_number);
void print_istemplate_function(FILE *header_file, FILE *code_file,
        int tuple_number);
void print_sizeof_function(FILE *code_file, int tuple_number);
void print_copy_function(FILE *code_file, int tuple_number);

void print_tuple_cmp_function(FILE *code_file, int tuple_id,
        struct field_node *field_list);
void print_tuple_replace_function(FILE *code_file, int tuple_id,
        struct field_node *field_list);
void print_tuple_istemplate_function(FILE *code_file, int tuple_id,
        struct field_node *field_list);

void print_field_count(FILE *code_file, int field_count[],
        int tuple_number);

void print_header_field_sizes_function(FILE *code_file);
void print_footer_field_sizes_function(FILE *code_file, int tuple_number);
void print_field_sizes_array_header(FILE *code_file, int type_id);
void print_field_sizes_array_footer(FILE *code_file, int type_id);
void print_field_size(FILE *code_file, int size);

void print_header_field_types_function(FILE *code_file);
void print_footer_field_types_function(FILE *code_file, int tuple_number);
void print_field_types_array_header(FILE *code_file, int type_id);
void print_field_types_array_footer(FILE *code_file, int type_id);
void print_field_type(FILE *code_file, char *type);

#endif
