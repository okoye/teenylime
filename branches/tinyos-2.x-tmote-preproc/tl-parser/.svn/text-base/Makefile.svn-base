CC=gcc
FLEX=flex
CFLAGS=-c -Wall
FLEXFLAGS=--noyy_top_state --nounput 

TLPARSER_SOURCES=tl-parser.c tuple-type.c attribution.c tuple-print.c file_searcher.c header-stack.c constants-table.c symbol-table.c
TLPARSER_HEADERS=$(TLPARSER_SOURCES:.c=.h)
TLPARSER_OBJECTS=$(TLPARSER_SOURCES:.c=.o)
TLPARSER=tl-parser


CREATE_CODE_SOURCES=create-code.c tuple-type.c tuple-print.c file_searcher.c
CREATE_CODE_HEADERS=tuple-type.c tuple-print.c
CREATE_CODE_OBJECTS=$(CREATE_CODE_SOURCES:.c=.o)
CREATE_CODE=create-code

CONFPARSER_SOURCES=conf-parser.c conf-search.c file_searcher.c
CONFPARSER_HEADERS=conf-search.h file_searcher.h
CONFPARSER_OBJECTS=$(CONFPARSER_SOURCES:.c=.o)
CONFPARSER=conf-parser

RENAME_SOURCES=rename-id.c file_searcher.c
RENAME_OBJECTS=$(RENAME_SOURCES:.c=.o)
RENAME=rename-id


EXECUTABLES=$(TLPARSER) $(CREATE_CODE) $(CONFPARSER) $(RENAME)
OBJECTS=$(TLPARSER_OBJECTS) $(CREATE_CODE_OBJECTS) $(CONFPARSER_OBJECTS) $(RENAME_OBJECTS)

all: $(EXECUTABLES)

$(TLPARSER): $(TLPARSER_OBJECTS) $(TLPARSER_HEADERS)
	$(CC) $(TLPARSER_OBJECTS) -o $@

tl-parser.c: tl-parser.l
	$(FLEX) $(FLEXFLAGS) --header-file=tl-parser-struct.h -o $@ $<

$(CONFPARSER): $(CONFPARSER_OBJECTS) $(CONFPARSER_HEADERS)
	$(CC) $(CONFPARSER_OBJECTS) -o $@

$(CREATE_CODE): $(CREATE_CODE_OBJECTS) $(CREATE_CODE_HEADERS)
	$(CC) $(CREATE_CODE_OBJECTS) -o $@

$(RENAME): $(RENAME_OBJECTS)
	$(CC) $(RENAME_OBJECTS) -o $@

.c.o: 
	$(CC) $(CFLAGS) $< -o $@

.l.c:
	$(FLEX) $(FLEXFLAGS) -o $@ $<


clean:
	rm -f $(EXECUTABLES) $(OBJECTS) tl-parser.c conf-parser.c rename-id.c tl-parser-struct.h
