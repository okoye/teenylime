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
 * *	$Id: constants-table.c 843 2009-05-18 08:46:04Z sguna $
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


#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct constant_node {
    char *identifier;
    int value;
    struct constant_node *next, *prev;
};


static struct constant_node *constant_table = NULL, *last_entry = NULL;


static void delete_table(struct constant_node *node)
{
    if (node == NULL)
        return;
    delete_table(node->next);
    free(node->identifier);
    free(node);
}


void new_constant_table()
{
    if (constant_table != NULL)
        delete_table(constant_table);
    constant_table = NULL;
    last_entry = NULL;
}


static struct constant_node *search_constant(char *identifier,
        struct constant_node *node)
{
    if (node == NULL)
        return NULL;
    if (!strcmp(node->identifier, identifier))
        return node;
    return search_constant(identifier, node->next);
}


int get_constant(char *identifier, int *value)
{
    struct constant_node *node = search_constant(identifier, constant_table);
    if (node == NULL)
        return 0;
    if (value != NULL)
        *value = node->value;
    return 1;
}


void remove_constant(char *identifier)
{
    struct constant_node *node = search_constant(identifier, constant_table);
    if (node == NULL)
        return;
    if (node == constant_table) {
        constant_table = node->next;
        constant_table->prev = NULL;
        last_entry = NULL;
    } else {
        if (node->next)
            node->next->prev = node->prev;
        node->prev->next = node->next;
    }
    free(node->identifier);
    free(node);
}


void add_constant(char *identifier, int value)
{
    if (search_constant(identifier, constant_table))
        return;
    struct constant_node *new_node = malloc(sizeof(struct constant_node));
    new_node->identifier = strdup(identifier);
    new_node->value = value;
    new_node->prev = last_entry;
    new_node->next = NULL;
    if (constant_table == NULL)
        constant_table = new_node;
    else
        last_entry->next = new_node;
    last_entry = new_node;
}


