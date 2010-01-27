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
 * *	$Id: tuple-type.h 843 2009-05-18 08:46:04Z sguna $
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


#ifndef __TUPLE_TYPE_H
#define __TUPLE_TYPE_H

#include <stdio.h>
#include "tl-parser.h"

struct field_node {
    char *type;
    struct field_node *next;
};

struct tuple_node {
    struct field_node *field_list;
    struct tuple_node *next;
    int is_neighbor_tuple;
};


int open_files(char *filename);
void close_files();

void new_tuple();
int add_attribute(char *attr_type);
void print_tuple_id(FILE *file, int is_neighbor_tuple);
int contains_replaceable(int tuple_id);
void print_tuple_type(FILE *file, int is_neighbor_tuple);
int get_last_tuple_id();

int load_types(char *filename);
int get_array_length(char *field_type);
void print_tuples();
int save_types(char *filename);


#endif
