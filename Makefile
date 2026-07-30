STACK ?= stack
AWK ?= awk
TYPST ?= typst
MPOST ?= mpost

.PHONY: all doc

all: Zine.pdf zine.svg
	$(STACK) build

%.svg: %.mp
	$(MPOST) $<
	$(RM) $(basename $<).log

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf: %.typ
	$(TYPST) compile $< $@
