#!/usr/bin/python

# My first python program. Please change if you notice weird code ;)

import sys
from Classes import *
from genQueryFunctions import *
from genTupleFormats import *
from genNewTupleFuncs import *



srcPath = sys.argv[1] + '/'
dstPath = sys.argv[2] + '/'


tFmtsFilenameSrc = 'TupleDefs.h'
tFmtsFilename = 'TupleFormats.h'
newTupleFilename = 'NewTuple.h'
queriesFilename = 'Queries.h'

# The characters that indicate start of comment
COMMENT_KEYW = '//'


defines = Defines()
tFmts = TupleFmts()

def error(filename, my_error):
  # Errors are output to stderr, or we wont see the newlines
  sys.stderr.write(filename + ': ' + my_error + "\n")
  # Output something to standard output, to make the makefile stop:
  print "Err"



# === C header file functions === #

def genHeader(filename):
  upFilename = filename.upper().replace('.','_')
  code = '\n// This file has been generated. Please don\'t edit\n\n'
  code += '#ifndef ' + upFilename + '\n'
  code += '#define ' + upFilename + '\n\n\n'
  return code

def genFooter(filename):
  upFilename = filename.upper().replace('.','_')
  return '\n\n#endif // ' + upFilename + '\n'



def load(filename):
  global defines
  global tFmts
  currentLine = 1
  file = open(filename, 'r')
  for line in file:

    err = ""
    line = line.strip()
    if line.startswith(DEFINE_KEYW):
      err = defines.load(line)
    elif line.startswith(TUPLE_FMT_KEYW):
      err = tFmts.load(line)
    elif line.startswith(USE_STD_REACTION_KEYW):
      err = tFmts.load(line)
    elif line.startswith(USE_STD_QUERY_KEYW):
      err = tFmts.load(line)
    elif  not line == "" and not line.startswith(COMMENT_KEYW):
      err = "Unknown command"

    if err:
      error(filename, 'Error on line %d: %s "%s"' %(currentLine, err, line))
    currentLine += 1

  file.close()


# === Start Preprocessing! === #

tFmtsFile = open(dstPath + tFmtsFilename, 'w')
queriesFile = open(dstPath + queriesFilename, 'w')
newTupleFile = open(dstPath + newTupleFilename, 'w')

# === Load File === #
load(srcPath + tFmtsFilenameSrc)


# === Process data === #
# Not so much to do yet...
err = tFmts.setFmtIDs(defines)
if err: error(srcPath + tFmtsFilenameSrc, err)



# === Write Tuple Formats to file === #
code = genHeader(tFmtsFilename)
code += "#define NR_FORMATS " + str(tFmts.nrFmts()) + "\n\n"
code += genDefines(defines)
code += genFieldCounts(tFmts)
code += "\n#define " + TUPLE_SIZE_KEYW + "(fieldCount) fieldCount * sizeof(field_t) + sizeof(Tuple)\n\n"
code += genTupleFormats(tFmts)
code += genFooter(tFmtsFilename)
tFmtsFile.write(code)
tFmtsFile.close()


# === Write Query Functions to file === #
code = genHeader(queriesFilename)
code += '#include "' + tFmtsFilename + '"\n\n'
code += genCmpFuncs(tFmts)
code += genQueryFuncs(tFmts)
code += genTriggerReactionFuncs(tFmts)

code += genFooter(queriesFilename)
queriesFile.write(code)
queriesFile.close()


# === Write functions create new tuples to file === #
code = genHeader(newTupleFilename)
#code += '#include "' + tFmtsFilename + '"\n\n'
code += genNewTupleFuncs(tFmts)

code += genFooter(newTupleFilename)
newTupleFile.write(code)
newTupleFile.close()


