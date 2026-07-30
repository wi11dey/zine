AWK ?= awk
TYPST ?= typst

%.typ: lhs2typ.awk %.lhs
	$(AWK) -f $^ > $@

%.pdf: %.typ
	$(TYPST) compile $< $@
