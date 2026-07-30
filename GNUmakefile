STACK ?= stack
AWK ?= awk
TYPST ?= typst
MPOST ?= mpost

.PHONY: all

all: Zine.pdf
	$(STACK) build

Zine.pdf: zine.svg

%.svg: %.mp
	$(MPOST) $<
	$(RM) $*.log

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf %.html: %.typ
	$(TYPST) compile --features html $< $@
