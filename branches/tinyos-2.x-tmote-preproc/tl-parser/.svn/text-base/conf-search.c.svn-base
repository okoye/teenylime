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
 * *	$Id: conf-search.c 843 2009-05-18 08:46:04Z sguna $
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
#include <stdio.h>
#include <stdlib.h>
#include "conf-search.h"
#include "file_searcher.h"

struct conf_node {
    char *original;
    char *identifier;
    struct conf_node *next;
};


struct conf_node *conf_list = NULL, *last_conf, *next_conf_iterator;


char *get_next_conf(char **argv, int argc)
{
    if (next_conf_iterator == NULL)
        return NULL;
    char *location= NULL;
    for (; next_conf_iterator != NULL && location == NULL;
            next_conf_iterator = next_conf_iterator->next) {
        location = find_file(argv, argc, next_conf_iterator->original);
    }

    return location;
}


static struct conf_node *search_conf(char *identifier)
{
    struct conf_node *i;
    for (i = conf_list; i != NULL; i = i->next) {
        if (!strcmp(i->identifier, identifier)) {
            return i;
        }
    }
    return NULL;
}


static struct conf_node *alloc_node(char *identifier)
{
    struct conf_node *result = malloc(sizeof(struct conf_node));
    result->original = strdup(identifier);
    result->identifier = strdup(identifier);
    result->next = NULL;
    return result;
}

void add_conf(char *identifier)
{
    if (search_conf(identifier) != NULL)
        return;
    if (conf_list == NULL) {
        next_conf_iterator = conf_list = last_conf = alloc_node(identifier); 
        return;
    }
    last_conf->next = alloc_node(identifier);
    last_conf = last_conf->next;
}


void rename_conf(char *identifier, char *alias)
{
    if (identifier == NULL) {
        exit(-1);
    }
    struct conf_node *conf = search_conf(identifier);
    free(conf->identifier);
    conf->identifier = strdup(alias);
}


void mark_conf(char *identifier)
{
    if (is_teenylime(identifier))
        return;
    struct conf_node *conf = search_conf(identifier);
    if (conf == NULL) {
        fprintf(stderr, "configuration %s not found!\n", identifier);
        exit(-1);
    }
}


void print_confs(char **argv, int argc)
{
    struct conf_node *i;
    for (i = conf_list; i != NULL; i = i->next) {
        if (!strcmp(i->original, "TLObjectsParsed"))
            continue;
        char *location = find_file(argv, argc, i->original);
        if (location != NULL) {
            printf("%s ", i->original);
            free(location);
        }
    }
}


int is_teenylime(char *identifier)
{
    struct conf_node *conf = search_conf(identifier);
    if (conf == NULL)
        return 0;
    if (!strcmp(conf->original, TEENYLIME))
        return 1;
    if (!strcmp(conf->original, TUPLE_SPACE))
        return 1;
    if (!strcmp(conf->original, TEENYLIME_SYS))
        return 1;
    return 0;
}

