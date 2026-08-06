AWK ?= awk
TYPST ?= typst
MPOST ?= mpost

Zine.pdf: zine.svg $(patsubst %.lhs,%.typ,$(wildcard *.lhs))

%.svg: %.mp
	$(MPOST) $<
	$(RM) $*.log

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf %.html: %.typ
	$(TYPST) compile --features html $< $@
