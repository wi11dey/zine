STACK ?= stack
AWK ?= awk
TYPST ?= typst

.PHONY: all doc

all: doc
	$(STACK) build

doc: $(patsubst %.lhs,%.pdf,$(wildcard *.lhs))

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf: %.typ
	$(TYPST) compile $< $@
