


TUPLE_FMT_KEYW = 'tupleFmt'
DEFINE_KEYW = "#define"
TUPLE_SIZE_KEYW = "TUPLE_SIZE"

TIMESTAMP_KEYW = "LOGICAL_TIME"
EXPIRE_IN_KEYW = "EXPIRE_IN"

NO_TIMESTAMP_KEYW = "NO_LOGICAL_TIME"
NO_EXPIRE_IN_KEYW = "NO_EXPIRE_IN"

USE_STD_REACTION_KEYW = "useStdReactionFunc"
USE_STD_QUERY_KEYW = "useStdQueryFunc"

error = ""

# Simple function to extract the arguments of a command with name <keyw>
# Assume a command format like keyw(arg0, arg1, ...)
def getArgs(line, keyw):
  error = ""
  # Increase cursor position to first parameter
  start = len(keyw) + 1
  line = line[start:]
  match = line.find(')')
  if match < 0:
    error = 'Closing bracket not found\n'
    return -1

  # Truncate line at closing bracket
  line = line[:match]

  # Create array containing all arguments
  return line.split(',');


# TODO: use python's built-in dictionary module
class Define:
  name = ""
  value = 0
  def __init__(self,nm, v):
    self.name = nm
    self.value = v


class Defines:
  definitions = []

  # add a definition
  def add(self, name, value):
    newDef = Define(name, value)
    self.definitions.append(newDef)

  # Look up the value of a definition from the list
  def getValue(self, name):
    for definition in self.definitions:
      if definition.name == name:
        return definition.value
    return -1

  # Return all definitions
  def getDefsArray(self):
    return self.definitions

  # Load #define's from file
  def load(self, line):
    error = ""

    # Find DEFINE_KEYW
    match = line.find(DEFINE_KEYW)
    if (match < 0): return ""

    # Move cursor after DEFINE_KEYW, extract arguments
    line = line[match+len(DEFINE_KEYW):]
    args = line.split()
    if (len(args) != 2):
      return "Malformed #define\n"

    # Add to existing definitions
    self.add(args[0], args[1])

    return ""


class TupleFmt:
  name = ""
  fieldTypes = []
  timeStampField = NO_TIMESTAMP_KEYW
  expireInField = NO_EXPIRE_IN_KEYW
  useStdQuery = 0
  useStdReactionFunc = 0
  fmtID = ""

  def __init__(self, name):
    self.name = name
    self.fieldTypes = []
    self.timeStampField = NO_TIMESTAMP_KEYW
    self.expireInField = NO_EXPIRE_IN_KEYW
    self.fmtID = 0

  def addField(self, type):
    if type == TIMESTAMP_KEYW:
      self.timeStampField = len(self.fieldTypes)
    if type == EXPIRE_IN_KEYW:
      self.expireInField = len(self.fieldTypes)
    self.fieldTypes.append(type)

  def nrFields(self):
    return len(self.fieldTypes)

  def getFields(self):
    return self.fieldTypes

  # Get the field nr of the expireIn field
  def getExpireInField(self):
    return self.expireInField

  # Get the field nr of the timestamp field
  def getTimestampField(self):
    return self.timeStampField

  def getFieldType(self, i):
    return self.fieldTypes[i]



class TupleFmts:
  fmts = []
  highestFmtID = 0

  def add(self, tupleFmt):
    self.fmts.append(tupleFmt)

  def getArray(self):
    return self.fmts

  def getByFmtID(self, fmtID):
    for fmt in self.fmts:
      if fmt.fmtID == fmtID: return fmt
    return None

  def getHighestFmtID(self):
    return int(self.highestFmtID)

  def nrFmts(self):
    return int(self.getHighestFmtID()) + 1

  # Replace tuple format
  def useStdQuery(self,name):
    for f in self.fmts:
      if f.name == name:
        f.useStdQuery = 1
        return f
    return None

  # Replace tuple format
  def useStdReactionFunc(self,name):
    for f in self.fmts:
      if f.name == name:
        f.useStdReactionFunc = 1
        return f
    return None

  # Try to match the names of the tuple fmts to the definitions
  # The corresponding formatID is stored with each tuple format
  def setFmtIDs(self, defines):
    max = 0
    error = ""
    for fmt in self.fmts:
      fmtID = int(defines.getValue(fmt.name))
      if (fmtID < 0):
        error += "Unknown tuple format name: %s\n" %fmt.name
        continue
      fmt.fmtID = fmtID
      if fmtID > max: max = fmtID
    self.highestFmtID = max
    self.error = error
    return error

  # Load tuple format
  def load(self, line):
    currentLine = 0
    fmts = []

    if line.startswith(TUPLE_FMT_KEYW):
      args = getArgs(line, TUPLE_FMT_KEYW)
      if args < 0: return error
      if len(args) == 0: return 'To few arguments\n'

      # First parameter is the name of the tuple format
      tFmt = TupleFmt(args.pop(0))
      # Then handle the data types of the fields
      for field in args:
        tFmt.addField(field.strip())
      self.add(tFmt)

    elif line.startswith(USE_STD_QUERY_KEYW):
      args = getArgs(line, USE_STD_QUERY_KEYW)
      if args < 0: return error
      if len(args) != 1: return  'Nr arguments unequal to 1\n'
      result = self.useStdQuery(args[0])
      if result == None: return "Tuple format name not found"

    elif line.startswith(USE_STD_REACTION_KEYW):
      args = getArgs(line, USE_STD_REACTION_KEYW)
      if args < 0: return error
      if len(args) != 1: return  'Nr arguments unequal to 1\n'
      result = self.useStdReactionFunc(args[0])
      if result == None: return "Tuple format name not found"

    else:
      return "Unknown command"

    return ""


