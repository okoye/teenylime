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
 * *	$Id: file_searcher.c 843 2009-05-18 08:46:04Z sguna $
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


#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include "file_searcher.h"

static char *make_path(char *path, char *name, int header)
{
    char *result = malloc(strlen(path) + strlen(name) + 5);
    strcpy(result, path);
    if (result[strlen(result) - 1] != '/')
        strcat(result, "/");
    strcat(result, name);
    if (!header) {
        if (!strcmp(result + strlen(result) - 3, ".nc"))
            return result;
        strcat(result, ".nc");
    }
    return result;
}


static char *try_path_exists(char *full_path)
{
    struct stat stat_buf;
    if (stat(full_path, &stat_buf) == -1) {
        free(full_path);
        return NULL;
    }
    return full_path;
}


static char *find_generic_file(char **argv, int argc, char *name, int header)
{
    int i;
    char *result = try_path_exists(make_path(".", name, header));
    if (result != NULL) {
        return result;
    }
    for (i = 1; i < argc; i++) {
        if (strncmp(argv[i], "-I", 2))
            continue;
        char *path = make_path(argv[i] + 2, name, header);
        result = try_path_exists(path);
        if (result != NULL)
            return result;
    }

    return result;
}


char *find_file(char **argv, int argc, char *name)
{
    return find_generic_file(argv, argc, name, 0);
}


char *find_header_file(char **argv, int argc, char *name)
{
    return find_generic_file(argv, argc, name, 1);
}


char *extract_filename(char *path)
{
    char *r = strrchr(path, '/');
    if (r == NULL)
        return path;
    return r + 1;
}


char *prefix_filename(char *path, char *prefix)
{
    char *result = malloc(strlen(path) + strlen(prefix) + 1);
    char *filename = extract_filename(path);
    int dir_length = filename - path;
    strncpy(result, path, dir_length);
    result[dir_length] = '\0';
    strcat(result, prefix);
    strcat(result, filename);
    return result;
}


char *replace_prefix(char *path, char *new_prefix)
{
    char *filename = extract_filename(path);
    strncpy(filename, new_prefix, strlen(new_prefix));
    return path;
}

