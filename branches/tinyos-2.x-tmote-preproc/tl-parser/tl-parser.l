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
 * *	$Id: tl-parser.l 843 2009-05-18 08:46:04Z sguna $
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
decimal [0-9]+
filename [^\/:*?<>|"]+
space [ \t\r\n]*

%{
#include <stdio.h>
#include "tuple-type.h"
#include "attribution.h"
#include "file_searcher.h"
#include "header-stack.h"
#include "constants-table.h"
#include "symbol-table.h"


extern int yy_flex_debug;

void exit_error(int line, char *text);
static void echo();
static void print_position();

char identifier[IDENTIFIER_SIZE];
int from_declaration;
int in_pointer;
int tuple_source;
char *crt_file;
static int call_level = 0;
int is_neighbor_tuple;

enum {
    FROM_INITIAL,
    FROM_FUNCTION,
    FROM_ATTRIBUTION,
    FROM_ISTYPE
};

char **arg_v;
int arg_n = 0;
int last_file;
int size_specified = 0;
int lineno = 0;

%}

%option stack
%array

%x in_C_comment in_Cpp_comment wait_attribution in_string wait_value_type wait_begin_value preprocessor
%s wait_type_list type_list identifier_list value in_call wait_value wait_end wait_decl_value pointer_dest in_func_args wait_istype_args istype_identifier istype_comma istype_tuple wait_istype_end waitistype_end array_size wait_include_type wait_filename define_identifier define_value undef_identifier


%%

<wait_attribution,wait_value_type,wait_begin_value>"/*" | 
"/*" { echo(); yy_push_state(in_C_comment); }

<in_C_comment>"\\*/" { echo(); }

<in_C_comment>"*/" { echo(); yy_pop_state(); } 

<wait_attribution,wait_value_type,wait_begin_value>"//" |
"//" { echo(); yy_push_state(in_Cpp_comment); }

<in_Cpp_comment>"\r\n"|"\n" { 
    if (!inside_header())
        lineno++; 
    echo();
    yy_pop_state();
}

<in_C_comment,in_Cpp_comment>. { echo(); }

<in_C_comment,in_Cpp_comment>"\r\n"|"\n" { 
    if (!inside_header())
        lineno++; 
    echo();
}

<in_call>"\r\n"|"\n" {
    if (!inside_header())
        lineno++; 
    append_text(yytext);
}

<in_call>[ \t\r]+ { append_text(yytext); } 

[ \t]+ { echo(); }

<preprocessor,wait_filename,wait_include_type,define_identifier,define_value>"\r\n"|"\n" {
    if (!inside_header())
        lineno++; 
    echo();
    BEGIN INITIAL;
}

"\r\n"|"\n" {
    if (!inside_header())
        lineno++; 
    echo();
}

; {
    BEGIN INITIAL;
    REJECT;
}

\{ {
    echo();
    push_symbol_level();
    BEGIN INITIAL;
}

"}" {
    echo();
    pop_symbol_level();
    BEGIN INITIAL;
}

<INITIAL># {
    echo();
    BEGIN preprocessor;
}

<preprocessor>"include" {
    echo();
    BEGIN wait_include_type;
}

<wait_include_type>"<" {
    echo();
    BEGIN preprocessor;
}

<wait_include_type>"\"" {
    echo();
    BEGIN wait_filename;
}

<wait_filename>"\"" {
    echo();
    BEGIN preprocessor;
}

<wait_filename>{filename} {
    echo();
    open_header(arg_v, arg_n, yytext, YY_CURRENT_BUFFER, YY_BUF_SIZE);
    BEGIN INITIAL;
}

<preprocessor>"define" {
    echo();
    BEGIN define_identifier;
}

<preprocessor>"undef" {
    echo();
    BEGIN undef_identifier;
}

<undef_identifier>{identifier} {
    echo();
    remove_constant(yytext);
    BEGIN preprocessor;
}

<define_identifier>{identifier} {
    echo();
    strncpy(identifier, yytext, IDENTIFIER_SIZE);
    BEGIN define_value;
}

<define_value>[0-9]+ {
    echo();
    add_constant(identifier, atoi(yytext));
    BEGIN preprocessor;
}

<preprocessor,wait_filename,wait_include_type,define_identifier,define_value>. { echo(); }


"isOfType" {
    if (!inside_header())
        BEGIN wait_istype_args;
}

<wait_istype_args>"(" {
    echo();
    BEGIN istype_identifier;
}

<istype_identifier>{identifier} {
    echo();
    fprintf(yyout, "->type");
    BEGIN istype_comma;
}

<istype_comma>"," {
    fprintf(yyout, " == ");
    BEGIN istype_tuple;
}

<istype_tuple>"NeighborTuple"|"tuple" {
    reset_att_buffer();
    tuple_source = FROM_ISTYPE;
    new_tuple();
    is_neighbor_tuple = !strcmp(yytext, "NeighborTuple");
    BEGIN wait_type_list;
}

<waitistype_end>")" {
    echo();
    BEGIN INITIAL;
}

<wait_istype_args,istype_identifier,istype_comma,istype_tuple,waitistype_end>. {
    exit_error(lineno, yytext);
}

<INITIAL>"NeighborTuple"|"tuple" {
    if (!inside_header()) {
        reset_att_buffer();
        tuple_source = FROM_INITIAL;
        yymore();
        new_tuple();
        is_neighbor_tuple = !strcmp(yytext, "NeighborTuple"); 
        BEGIN wait_type_list;
    }
}

<wait_attribution,pointer_dest>"NeighborTuple" {
    tuple_source = FROM_ATTRIBUTION;
    yymore();
    new_tuple();
    is_neighbor_tuple = 1;
    BEGIN wait_type_list;
}

<wait_attribution,pointer_dest>"tuple" {
    tuple_source = FROM_ATTRIBUTION;
    yymore();
    new_tuple();
    is_neighbor_tuple = 0;
    BEGIN wait_type_list;
}

<wait_type_list>"<" {
    yytext[0] = 0;
    BEGIN type_list; 
}


<type_list>">" {
    /* discard current character */
    yyleng = strlen(yytext) - 1;
    yytext[yyleng] = 0;
   
    if ((strstr(yytext, "rssi") != NULL || strstr(yytext, "lqi"))
            && strchr(yytext, '[') != NULL)
        exit_error(lineno, "rssi and lqi fields cannot be arrays");
    if (add_attribute(yytext) == 0)
        exit_error(lineno, yytext);

    identifier[0] = 0;
    in_pointer = 0;
    switch (tuple_source) {
        case FROM_ATTRIBUTION:
            print_tuple_type(yyout, is_neighbor_tuple);
            BEGIN INITIAL;
            break;

        case FROM_FUNCTION:
            print_tuple_type(yyout, is_neighbor_tuple);
            BEGIN in_func_args;
            break;

        case FROM_ISTYPE:
            print_tuple_id(yyout, is_neighbor_tuple);
            BEGIN wait_istype_end;
            break;

        case FROM_INITIAL:
        default:
            print_tuple_type(yyout, is_neighbor_tuple);
            BEGIN identifier_list;
            break;
    }
}

<type_list>{identifier} { yymore(); }

<type_list>"[" { 
    yymore();
    size_specified = 0;
    BEGIN array_size;
}

<array_size>{decimal} {
    if (size_specified)
        exit_error(lineno, "only one number or constant allowed for array field specification");
    if (atoi(strrchr(yytext, '[') + 1) == 0)
        exit_error(lineno, "0-size arrays are not supported for array fields");
    size_specified = 1;
    yymore();
}

<array_size>{identifier} {
    if (size_specified)
        exit_error(lineno, "only one number or constant allowed for array field specification");

    int real_value;
    int position = strrchr(yytext, '[') - yytext + 1;

    if (!get_constant(yytext + position, &real_value))
        exit_error(lineno, "constant not defined in array field specification");

    size_specified = 1;
    char buffer[IDENTIFIER_SIZE];
    snprintf(buffer, IDENTIFIER_SIZE, "%d", real_value);
    yytext[position] = 0;
    strcat(yytext, buffer);
    yyleng = strlen(yytext);
    yymore();
}

<array_size>"]" {
    yymore(); 
    BEGIN type_list;
}

<type_list>, {
    /* discard current character */
    yyleng = strlen(yytext) - 1;
    yytext[yyleng] = 0;

    if ((strstr(yytext, "rssi") != NULL || strstr(yytext, "lqi"))
            && strchr(yytext, '[') != NULL)
        exit_error(lineno, "rssi and lqi fields cannot be arrays");
    if (add_attribute(yytext) == 0)
        exit_error(lineno, yytext);
} 

<array_size,type_list>. { exit_error(lineno, yytext); }


<identifier_list>{identifier} {
    if (!in_pointer)
        strncpy(identifier, yytext, IDENTIFIER_SIZE);
    echo();
}

<identifier_list>"*" {
    in_pointer = 1;
    echo();
}

<identifier_list>= {
    add_symbol(identifier, get_last_tuple_id());
    if (!in_pointer) {
        if (identifier[0] == 0)
            exit_error(lineno, yytext); 
        from_declaration = 1;
        BEGIN wait_value_type;
    } else {
        echo();
        BEGIN pointer_dest;
    }
}

<identifier_list>, {
    add_symbol(identifier, get_last_tuple_id());
    identifier[0] = 0;
    echo();
}

<pointer_dest,identifier_list>; {
    if (!in_pointer)
        add_symbol(identifier, get_last_tuple_id());
    echo();
    flush_attribution(yyout);
    in_pointer = 0;
    BEGIN INITIAL;
}


<pointer_dest>, {
    if (!in_pointer)
        add_symbol(identifier, get_last_tuple_id());
    in_pointer = 0;
    echo();
    BEGIN identifier_list;
}

<pointer_dest>. { echo(); }

<wait_decl_value>"(" {
    begin_attribution(identifier);
    BEGIN wait_value;
}

<wait_decl_value>. { exit_error(lineno, yytext); }

<INITIAL>"typedef" {
    if (!inside_header()) {
        echo();
    }
}


<INITIAL>("*"{space})?{identifier}({space}"["{space}({decimal}|{identifier}){space}"]")? {
    if (!inside_header()) {
        strncpy(identifier, yytext, IDENTIFIER_SIZE);
        yymore();
        from_declaration = 0;
        BEGIN wait_attribution;
    }
}


<wait_attribution,wait_value_type,wait_begin_value>"\r\n"|"\n" {
    if (!inside_header())
        lineno++; 
    yymore();
}

<wait_attribution,wait_value_type,wait_begin_value>[ \t\r]+ { yymore();}

<wait_attribution>= {
    yymore();
    reset_att_buffer();
    BEGIN wait_value_type;
}

<wait_value_type>"isOfType" {
    yyleng = strlen(yytext) - strlen("isOfType");
    yytext[strlen(yytext) - strlen("isOfType")] = 0;
    echo();
    BEGIN wait_istype_args;
}


<wait_value_type>"newTuple" {
    reset_field_counter(identifier, "0");
    BEGIN wait_begin_value;
}


<wait_attribution>"(" {
    echo();
    BEGIN in_func_args;
}


<in_func_args>"NeighborTuple"|"tuple" {
    tuple_source = FROM_FUNCTION;
    is_neighbor_tuple = !strcmp(yytext, "NeighborTuple");
    yymore();
    new_tuple();
    BEGIN wait_type_list;
}

<in_func_args>")" {
    echo();
    BEGIN INITIAL;
}

<wait_attribution,wait_value_type,wait_begin_value>\{ {
    echo();
    push_symbol_level();
    BEGIN INITIAL;
}

<wait_type_list,identifier_list,wait_attribution,wait_value_type>. {
    echo();
    BEGIN INITIAL;
}


<wait_begin_value>"(" {
    begin_attribution(identifier);
    BEGIN wait_value;
}



<wait_value>{identifier} { 
    if (set_value_function(yytext))
        exit_error(lineno, yytext);
}

<wait_value>"(" { 
    if (begin_set_attribute())
        exit_error(lineno, yytext);
    yy_push_state(in_call);
    call_level = 1;
}

<wait_value>, { flush_member(); }

<wait_value>")" {
    flush_member();
    if (!from_declaration)
        BEGIN wait_end;
    else
        BEGIN identifier_list;
}

<wait_value>. { exit_error(lineno, yytext); } 


<in_call>"\"" { append_text(yytext); yy_push_state(in_string); }

<in_call>"(" { 
    append_text(yytext); 
    yy_push_state(in_call);
    call_level++;
}

<in_call>")" { 
    call_level--;
    if (call_level != 0)
        append_text(yytext); 
    yy_pop_state(); 
}

<in_call>. { append_text(yytext); }

<in_string>"\\\"" { append_text(yytext); }

<in_string>"\"" { append_text(yytext); yy_pop_state(); }

<in_string>. { append_text(yytext); }


<wait_end>; {
    flush_attribution(yyout);
    BEGIN INITIAL;
} 

<wait_end>. { exit_error(lineno, yytext); }

. { echo(); }

%%

void exit_error(int line, char *text)
{
    fprintf(stderr, "%s:%d: syntax error before `%s'\n", crt_file, line + 1, text);
    exit(-1);
}


static void echo()
{
    if (inside_header())
        return;
    ECHO;
}


static void print_position()
{
    if (inside_header())
        return;
    fprintf(yyout, "#line %d \"%s\"\n", lineno + 1, crt_file);
}


int yywrap()
{
    if (inside_header()) {
        close_header(YY_CURRENT_BUFFER);
        return 0;
    }

    int i;
    fclose(yyin);
    fclose(yyout);
    pop_symbol_level();
    push_symbol_level();
    
    char *in = NULL; 
    for (i = last_file; i < arg_n; i++) {
        if (arg_v[i][0] == '-')
            continue;
        in = find_file(arg_v, arg_n, arg_v[i]);
        if (in != NULL) {
            last_file = i + 1;
            break;
        }
    }

    if (in == NULL) {
        return 1;
    }
  
    yyin = fopen(in, "r");
    if (yyin == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", in);
        exit(-1);
    }
    
    char *out = prefix_filename(in, "___"); 
//    printf("parsing '%s' to '%s'...\n", in, out);
    yyout = fopen(out, "w");
    if (yyout == NULL) {
        fprintf(stderr, "unable to open file '%s'\n", out);
        exit(-1);
    }

    new_constant_table();
    
    free(crt_file);
    crt_file = in;
    lineno = 0;
    print_position();
    free(out);
    i++;
    BEGIN INITIAL;

    return 0;
}


int main(int argc, char *argv[])
{
    if (argc < 3) {
        printf("Usage:\n\t tl-parser tuple_file file1 %cfile2 %cfile3 %c...%c%c%c\n",
        '[', '[', '[', ']', ']', ']');
        return -1;
    }
    arg_n = argc;
    arg_v = argv;

    load_types(argv[1]);
    char *in = NULL;
    int i;
    for (i = 2; i < arg_n; i++) {
        if (arg_v[i][0] == '-')
            continue;
        in = find_file(arg_v, arg_n, arg_v[i]);
        if (in != NULL) {
            last_file = i + 1;
            break;
        }
    }
    
    /* add default neighbor tuple type (don't mark it as neighbor tuple
       in order to prevent the redefinition of the  constant for the neighbor
       tuple size */
    add_attribute("uint16_t");
    print_tuple_type(NULL, 0);

    if (in != NULL) {

        yyin = fopen(in, "r");
        if (yyin == NULL) {
            fprintf(stderr, "tl-parser: unable to open file '%s'\n", in);
            return -1;
        }

        char *out = prefix_filename(in, "___");
//        printf("parsing '%s' to '%s'...\n", in, out);
        yyout = fopen(out, "w");
        if (yyout == NULL) {
            fprintf(stderr, "tl-parser: unable to open file '%s'\n", out);
            exit(-1);
        }

        crt_file = in;
        free(out);
        print_position();

        push_symbol_level();
        yylex();
        free(crt_file);
    }

    if (save_types(argv[1])) {
        fprintf(stderr, "tl-parser: unable to save types\n");
        return -1;
    }
    return 0;
}

