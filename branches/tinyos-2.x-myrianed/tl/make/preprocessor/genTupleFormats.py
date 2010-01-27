

from Classes import *


# === Code generation function for the tuple formats file === #

def genDefines(defines):
  code = '\n// Definitions of format ID\'s\n'
  for definition in defines.getDefsArray():
    code += DEFINE_KEYW + ' ' + definition.name + ' ' + definition.value + "\n"
  return code

def genFieldCounts(tFmts):
  code = '\n// Definitions of nr of fields per tuple\n'
  for tFmt in tFmts.getArray():
    code += DEFINE_KEYW + ' ' + tFmt.name + '_FIELD_COUNT ' + str(tFmt.nrFields()) + "\n"
  return code

def genTupleFormats(tFmts):
  code = '\n// Format data array\n'
  code += 'format_t formats[] = {\n'
  for i in range(tFmts.getHighestFmtID() + 1):
    tFmt = tFmts.getByFmtID(i)

    if tFmt == None:
      code += '// ID not used. \n{},\n'
      continue

    code += '// ' + tFmt.name + '\n{'

    # Write data types
    code += '{'
    nrFields = 0
    for field in tFmt.getFields():
      code += field
      nrFields += 1
      if nrFields != tFmt.nrFields():
        code += ', '
    code += '}, '

    # Write nr fields
    code += str(tFmt.nrFields()) + ', '

    # Write tuple size
    code += TUPLE_SIZE_KEYW + "(" + str(tFmt.nrFields()) +"), "

    # Write expireIn and timestamp positions
    code += str(tFmt.getTimestampField()) + ", "
    code += str(tFmt.getExpireInField())

    code += '},\n'

  code += '};\n\n'
  return code

