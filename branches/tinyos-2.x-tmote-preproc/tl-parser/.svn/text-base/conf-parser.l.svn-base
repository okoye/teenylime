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
 * *	$Id: conf-parser.l 843 2009-05-18 08:46:04Z sguna $
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



identifier [a-zA-Z_][a-zA-Z0-9_]*

%{
#include <stdio.h>
#include "conf-search.h"
#include "file_searcher.h"

extern int yy_flex_debug;

void exit_error(int line, char *text);
static void change_source(char *identifier);
FILE *next_file();
char *source = NULL;
char *crt_file = NULL;
static char *last_conf = NULL;

int new_component;

char **gargv;
int gargc;

%}

%option stack
%option yylineno
%array

%x in_C_comment in_Cpp_comment in_string preprocessor
%s component_identifier component_alias in_call new_line wait_link after_identifier alias wait_destination wait_ts wait_dot wait_endline wait_attribution 


%%


"/*" { yy_push_state(in_C_comment); }

<in_C_comment>"\\*/" { ; }

<in_C_comment>"*/" { yy_pop_state(); } 

"//" { yy_push_state(in_Cpp_comment); }

<in_Cpp_comment>"\r\n"|"\n" { yy_pop_state(); }

<in_C_comment,in_Cpp_comment>. { ; }

<in_C_comment,in_Cpp_comment>"\r\n"|"\n" { ; }

"\"" { yy_push_state(in_string); }

<in_string>"\\\"" { ; } 

<in_string>"\"" { yy_pop_state(); }

<in_string>. { ; } 

<INITIAL>"\r\n"|"\n" { BEGIN new_line; }

"\r\n"|"\n" { ; }

[ \t]+ { ; }

[;{}] { BEGIN INITIAL; }


<new_line>"#" { BEGIN preprocessor; } 

<preprocessor>"\r\n"|"\n" { BEGIN new_line; }
<preprocessor>. { ; }

<new_line>"module" {
        yyin = next_file();
        if (yyin == NULL)
            return 0;
        BEGIN INITIAL;
        yyrestart(yyin);
    }
    
"interface"|"components" {
    new_component = 0;
    BEGIN component_identifier;
}



<component_identifier>"new" { ; }


<component_identifier>{identifier} {
    new_component = 1;
    BEGIN after_identifier;
    add_conf(yytext);
    if (last_conf != NULL)
        free(last_conf);
    last_conf = strdup(yytext);
}


<after_identifier,in_call>"(" { yy_push_state(in_call); }
<in_call>")" { yy_pop_state(); }


<after_identifier>"as" { BEGIN alias; }
<alias,after_identifier>, { BEGIN component_identifier; }

<alias>{identifier} { rename_conf(last_conf, yytext); }


<wait_destination>{identifier} {
    if (is_teenylime(yytext))
        BEGIN wait_dot;
}


<wait_attribution>{identifier} {
    if (is_teenylime(source))
        mark_conf(yytext);
    if (is_teenylime(yytext))
        mark_conf(source);
    BEGIN wait_endline;
}


<wait_dot>"." { BEGIN wait_ts; }

<wait_dot>. { BEGIN wait_endline; }


<wait_ts>{identifier} { 
    if (!strcmp(TUPLE_SPACE, yytext));
        mark_conf(source);
    BEGIN wait_endline;
}

<wait_ts>. { BEGIN wait_endline; }


<INITIAL,new_line>{identifier} { 
    change_source(yytext); 
    BEGIN wait_link; 
}


<wait_link>"->" { BEGIN wait_destination;}

<wait_link>= { BEGIN wait_attribution; }


. { ; }

%%

void exit_error(int line, char *text)
{
    fprintf(stderr, "%s:%d: syntax error: \"%s\"\n", crt_file, line, text);
    exit(-1);
}


static void change_source(char *identifier)
{
    if (source != NULL)
        free(source);
    source = strdup(identifier);
}


FILE *next_file()
{
    yyin = NULL;
    do {
        char *in = get_next_conf(gargv, gargc);
        if (in == NULL)
            return NULL;
        yyin = fopen(in, "r");
        if (crt_file != NULL)
            free(crt_file);
        crt_file = in;
        
    } while (yyin == NULL);
    return yyin;
}


int yywrap()
{
    if (next_file() == NULL)
        return 1;
    BEGIN INITIAL;
    return 0;
}


int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage:\n\t conf-parser configuration\n");
        return -1;
    }
    gargc = argc;
    gargv = argv;

    int i, found = 0;
    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            found = 1;
            break;
        }
    }
    if (!found) {
        printf("Usage:\n\t conf-parser configuration\n");
        return -1;
    }
    crt_file = find_file(argv, argc, argv[i]);
    yyin = fopen(crt_file, "r");
    if (yyin == NULL) {
        fprintf(stderr, "unable to open file: '%s'\n", argv[1]);
        return -1;
    }
    yylex();
    free(crt_file);
    print_confs(argv, argc);
    return 0;
}

