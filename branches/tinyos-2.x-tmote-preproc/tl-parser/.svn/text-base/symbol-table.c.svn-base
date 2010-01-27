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
 * *	$Id: symbol-table.c 843 2009-05-18 08:46:04Z sguna $
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
#include <stdlib.h>
#include "attribution.h"


struct symbol_node {
    char *identifier;
    int type;
    struct symbol_node *next;
};


struct level_node {
    struct symbol_node *symbols;
    struct level_node *prev;
};

static struct level_node * level_stack;


void push_symbol_level()
{
    struct level_node *level = malloc(sizeof(struct level_node));
    level->prev = level_stack;
    level->symbols = NULL;
    level_stack = level;
}


static void free_symbols(struct symbol_node *node)
{
    if (node == NULL)
        return;
    free_symbols(node->next);
    free(node->identifier);
    free(node);
}


void pop_symbol_level()
{
    if (level_stack == NULL)
        return;
    struct level_node *prev = level_stack->prev;
    free_symbols(level_stack->symbols);
    level_stack->symbols = NULL;
    free(level_stack);
    level_stack = prev;
}


static int find_type_on_level(char *identifier, int *result,
        struct symbol_node *symbols)
{
    if (symbols == NULL)
        return 0;
    if (!strcmp(symbols->identifier, identifier)) {
        *result = symbols->type;
        return 1;
    }
    return find_type_on_level(identifier, result, symbols->next);
}


static int find_type_on_stack(char *identifier, int *result,
        struct level_node *level)
{
    if (level == NULL)
        return 0;
    int found = find_type_on_level(identifier, result, level->symbols);
    if (found)
        return 1;
    return find_type_on_stack(identifier, result, level->prev);
}


int find_symbol_type(char *identifier, int *result)
{
    return find_type_on_stack(identifier, result, level_stack);
}

void add_symbol(char *identifier, int type)
{
    struct symbol_node *symbol = malloc(sizeof(struct symbol_node));
    symbol->identifier = strdup(identifier);
    symbol->type = type;
    symbol->next = level_stack->symbols;
    level_stack->symbols = symbol;
}

