// This is not a standard header file
// This file is processed only by the TeenyLime preprocessor.

// ===== FORMAT IDs ===== //
// Each tuple format has a unique ID
// Define your format IDs here.
// currently, format ID must be smaller than 64

// System formats, please don't remove
#define NULL_FMT 0
#define STD_NGH_FMT 1

// Application defined formatIDs
#define TUPLE_2_FMT 2
#define TUPLE_3_FMT 3
#define TUPLE_4_FMT 4
#define BIG_TUPLE 5


// ===== TUPLE FORMATS ===== //
// Define your tuple formats here

// tupleFmt(name, fieldType0, fieldType1, ..):
// @param name: the name of the tuple format
// @param fieldTypeN:
// Possible field types are: TYPE_UINT16, TYPE_UINT8, TYPE_CHAR, TYPE_FLOAT, EXPIRE_IN, LOGICAL_TIME

// System formats, please don't remove
tupleFmt(STD_NGH_FMT, TYPE_UINT16)

// Application defined tuple formats
tupleFmt(TUPLE_2_FMT, TYPE_UINT16, TYPE_UINT16)
tupleFmt(TUPLE_3_FMT, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16)
tupleFmt(TUPLE_4_FMT, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16)
tupleFmt(BIG_TUPLE, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16, TYPE_UINT16)


// ===== More settings ===== //

// -> useStdReactionFunc(name):
// For tuple formats <name>, do not generate optimized functions for the
// triggering of reactions. Use a standard function instead.
// This decreases the size of the binary, but makes OUT operations slower.

// -> useStdQueryFunc(name):
// For the following tuple formats, do not generate optimized query
// functions. Use standard function instead.
// This decreases the size of the binary, but makes RD and IN operations slower.

// Note that query code generation can be turned on or off all together by
// changing QUERY_METHOD in TLConf.h


useStdReactionFunc(STD_NGH_FMT)
useStdQueryFunc(STD_NGH_FMT)
//useStdReactionFunc(TUPLE_3_FMT)
//useStdQueryFunc(TUPLE_3_FMT)


