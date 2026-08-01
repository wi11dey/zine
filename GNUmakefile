AWK ?= awk
TYPST ?= typst
MPOST ?= mpost

Zine.pdf: zine.svg

%.svg: %.mp
	$(MPOST) $<
	$(RM) $*.log

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf %.html: %.typ
	$(TYPST) compile --features html $< $@

udpipe/src_lib_only/udpipe.cpp:
	$(MAKE) -C $(@D) $(@F) CXX=/usr/bin/clang++
