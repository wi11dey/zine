STACK ?= stack
AWK ?= awk
TYPST ?= typst
MPOST ?= mpost

.PHONY: all

all: Zine.pdf Zine.lhs udpipe/src_lib_only/udpipe.cpp
	$(STACK) build

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
