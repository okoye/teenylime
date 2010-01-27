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
 * *	$Id: header-stack.c 843 2009-05-18 08:46:04Z sguna $
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


#include "file_searcher.h"
#include <stdio.h>

#include "tl-parser-struct.h"


struct header_stack {
    YY_BUFFER_STATE buffer_state;
    struct header_stack *prev;
};

static struct header_stack *header_stack = NULL;


int inside_header()
{
    return header_stack != NULL;
}


static YY_BUFFER_STATE pop_header() 
{
    if (header_stack == NULL)
        return NULL;
    struct header_stack *top = header_stack;
    YY_BUFFER_STATE result = header_stack->buffer_state;
    header_stack = header_stack->prev;
    free(top);
    return result;
}


static void push_header(YY_BUFFER_STATE buffer_state)
{
    struct header_stack *top = malloc(sizeof(struct header_stack));
    top->buffer_state = buffer_state;
    top->prev = header_stack;
    header_stack = top;
}


void open_header(char **argv, int argc, char *file,
        YY_BUFFER_STATE current_buffer, int buf_size)
{
    char *full_path = find_header_file(argv, argc, file);
    if (full_path == NULL)
        return;

    push_header(current_buffer);

//    printf("parsing header %s\n", full_path);
    yyin = fopen(full_path, "r");
    yy_switch_to_buffer(yy_create_buffer(yyin, buf_size));
}


void close_header(YY_BUFFER_STATE current_buffer)
{
    yy_delete_buffer(current_buffer);
    yy_switch_to_buffer(pop_header());
}

