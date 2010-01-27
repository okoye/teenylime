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
 * *	$Id: rename-id.l 843 2009-05-18 08:46:04Z sguna $
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
#include <string.h>
#include "file_searcher.h"

extern int yy_flex_debug;

char **arg_v;
int arg_n = 0;
int last_file;

%}

%option stack
%array

%x in_C_comment in_Cpp_comment in_string preprocessor
%s new_line 


%%


"/*" { ECHO; yy_push_state(in_C_comment); }

<in_C_comment>"\\*/" { ECHO; }

<in_C_comment>"*/" { ECHO; yy_pop_state(); } 

"//" { ECHO; yy_push_state(in_Cpp_comment); }

<in_Cpp_comment>"\r\n"|"\n" { ECHO; yy_pop_state(); }

<in_C_comment,in_Cpp_comment>. { ECHO; }

<in_C_comment,in_Cpp_comment>"\r\n"|"\n" { ECHO; }

"\"" { ECHO; yy_push_state(in_string); }

<in_string>"\\\"" { ECHO; } 

<in_string>"\"" { ECHO; yy_pop_state(); }

<in_string>. { ECHO; } 

"\r\n"|"\n" { ECHO; BEGIN new_line; }

[ \t]+ { ECHO; }

[;{] { ECHO; BEGIN INITIAL; }


<new_line>"#" { ECHO; BEGIN preprocessor; } 

<preprocessor>"\r\n"|"\n" { ECHO; BEGIN new_line; }
<preprocessor>. { ECHO; }


{identifier} {
    int i, found = 0;
    char component_name[256];
    for (i = 1; i < arg_n; i++) {
        if (arg_v[i][0] == '-')
            continue;
        char *filename = extract_filename(arg_v[i]);
        strncpy(component_name, filename, 256);
        if (!strcmp(component_name + strlen(component_name) - 3, ".nc"))
            component_name[strlen(component_name) - 3] = 0;
        if (!strcmp(yytext, component_name)) {
            fprintf(yyout, "TL_%s", yytext);
            found = 1;
            break;
        }
    }
    if (!found)
        ECHO;
}

. { ECHO; }

%%


static void remove_prev()
{
    if (arg_v[last_file][0] == '-')
        return;
    char *tmp = prefix_filename(arg_v[last_file], "___");
    char *prev = find_file(arg_v, arg_n, tmp);
    free(tmp);
    if (prev == NULL) {
        free(prev);
        return;
    }
    remove(prev);
    free(prev);
}


int yywrap()
{
    if (last_file > 1)
        remove_prev();

    fclose(yyin);
    fclose(yyout);
   
    int i;
    char *in = NULL, *tmp;
    for (i = last_file + 1; i < arg_n; i++) {
        if (arg_v[i][0] == '-')
            continue;
        tmp = prefix_filename(arg_v[i], "___");
        in = find_file(arg_v, arg_n, tmp);
        free(tmp);
        if (in != NULL) {
            last_file = i;
            break;
        }
    }

    if (in == NULL) {
        printf("done!\n");
        return 1;
    }

    yyin = fopen(in, "r");
    if (yyin == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", in);
        exit(-1); 
    }

    char *out = strdup(in);
    replace_prefix(out, "TL_");
//    printf("parsing '%s' to '%s'...\n", in, out);

    yyout = fopen(out, "w");
    if (yyout == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", out);
        return -1;
    }
    fprintf(yyout, "#line 1 \"%s\"\n", in);
    free(in);
    free(out);
    i++;
    BEGIN INITIAL;

    return 0;
}


int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage:\n\t rename_id configuration %cmodule1 %cmodule2 %c...%c%c%c\n",
        '[', '[', '[', ']', ']', ']');
        return -1;
    }
    arg_n = argc;
    arg_v= argv;

    char *in = find_file(arg_v, arg_n, arg_v[1]);
    yyin = fopen(in, "r");
    if (yyin == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", in);
        return -1;
    }
    last_file = 1;

    char *out = prefix_filename(in, "TL_");
//    printf("parsing '%s' to '%s'...\n", in, out);
    yyout = fopen(out, "w");
    if (yyout == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", out);
        return -1;
    }
    fprintf(yyout, "#line 1 \"%s\"\n", in);
    free(in);
    free(out);
    yylex();
    remove_prev();
    return 0;
}

