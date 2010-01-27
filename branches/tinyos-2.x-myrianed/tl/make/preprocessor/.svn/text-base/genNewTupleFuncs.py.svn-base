

from Classes import *
import sys

realDataTypes = {
'TYPE_UINT16':'uint16_t',
'TYPE_UINT8':'uint8_t',
'TYPE_CHAR':'char',
'TYPE_STR':'char[]',
'TYPE_FLOAT':'float'
}

fieldUnionAccessor = {
'TYPE_UINT16':'int16',
'TYPE_UINT8':'int8',
'TYPE_CHAR':'c',
'TYPE_STR':'str',
'TYPE_FLOAT':'flt'
}


def genNewTupleFunc(tFmt, isCapabilityTuple):

  if isCapabilityTuple == "FALSE":
    code = "void newTuple_%FMT_NAME(Tuple *t, "
  else:
    code = "void newCapTuple_%FMT_NAME(Tuple *t, "

  # Create parameter list
  fieldNr = 0
  for field in tFmt.getFields():
    code += realDataTypes[field] + " f" + str(fieldNr)
    if (fieldNr + 1) != tFmt.nrFields(): code += ', '
    fieldNr += 1
  code += ') {\n'

  # Copy field values
  fieldNr = 0
  for field in tFmt.getFields():

    line = "  t->fields[%FIELD_NR]." + fieldUnionAccessor[field] + " = f%FIELD_NR;\n"
    line = line.replace("%FIELD_NR", str(fieldNr))
    fieldNr += 1
    code += line

  # Set formatID
  code += """

  t->fmtID = %FMT_NAME;
  t->isCapabilityTuple = %IS_CAP_TUPLE;
  t->isNeighborTuple = FALSE;
}

"""
  code = code.replace('%FMT_NAME', tFmt.name)
  code = code.replace('%IS_CAP_TUPLE', isCapabilityTuple)
  return code


def genNewTupleFuncs(tFmts):
  code = ""

  # create newTuple() funcs
  for tFmt in tFmts.getArray():
    code += genNewTupleFunc(tFmt, "FALSE")

  # create newCapTuple() funcs
  for tFmt in tFmts.getArray():
    code += genNewTupleFunc(tFmt, "TRUE")
  return code

