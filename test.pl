:- discontiguous mor/4.
:- discontiguous id/3.
:- discontiguous compose/4.

:- table mor/4.

mor(Category, A, Id, A) :- id(Category, Id, A).
mor(Category, A, Morphism, C) :-
    mor(Category, A, Factor1, B),
    mor(Category, B, Factor2, C),
    compose(Category, Factor1, Factor2, Morphism).

upos(word("They",  1), pron).
upos(word("buy",   2), verb).
upos(word("and",   3), cconj).
upos(word("sell",  4), verb).
upos(word("books", 5), noun).

% Category ud
id(ud, [], word(_, _)).
compose(ud, Subpath1, Subpath2, Path) :- append(Subpath1, Subpath2, Path).
mor(ud, word("buy", 2), [nsubj], word("They", 1)).
mor(ud, word("buy", 2), [conj], word("sell", 4)).
mor(ud, word("buy", 2), [obj], word("books", 5)).
mor(ud, word("sell", 4), [cc], word("and", 3)).

% Category dep
mor(dep, A, Path, B) :- mor(ud, A, Path, B).
mor(dep, Word1, [conj], Word2) :- mor(ud, Word2, [conj], Word1). % conj is syntactically symmetric
mor(dep, A, Path, Destination) :- % conj semantics
    mor(dep, A, [conj], B),
    mor(ud, B, Path, Destination).

nominal(Word) :- upos(Word, noun).
nominal(Word) :- upos(Word, pron).

% Category link
id(link, [], Noun) :- nominal(Noun).
compose(link, Subpath1, Subpath2, Path) :- append(Subpath1, Subpath2, Path).
mor(link, Noun1, [Verb], Noun2) :-
    nominal(Noun1),
    nominal(Noun2),
    mor(dep, Verb, [nsubj], Noun1),
    mor(dep, Verb, [obj], Noun2),
    upos(Verb, verb).
