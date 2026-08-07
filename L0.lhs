== $L_0$

Let's begin by defining

> module L0 where

/*

> import Language.Nanopass

*/

> [deflang|
> ((UD w)
>   (DependencyTree (DependencyTree Dependency UPOS w (* DependencyTree)))
>   (Dependency
>     (Ref) (Acl) (Advcl) (Advmod) (Amod) (Appos) (Aux) (Case) (Ccomp) (Cc) (Clf)
>     (Compound) (Conj) (Cop) (Csubj)
>     (Dep) (Det) (Discourse) (Dislocated)
>     (Expl)
>     (Fixed) (Flat)
>     (Goeswith)
>     (Iobj)
>     (List)
>     (Mark)
>     (Nmod) (Nsubj) (Nummod)
>     (Obj) (Obl) (Orphan)
>     (Parataxis) (Punct)
>     (Reparandum) (Root)
>     (Vocative)
>     (Xcomp))
>   (UPOS
>     (ADJ) (ADP) (ADV) (AUX)
>     (CCONJ)
>     (DET)
>     (INTJ)
>     (NOUN) (NUM)
>     (PART) (PRON) (PROPN) (PUNCT)
>     (SCONJ) (SYM)
>     (VERB)
>     (X)))|]
