mor(Category, A, A) :- id(Category, A).
mor(Category, A, C) :- mor(Category, A, B), mor(Category, B, C).

upos(word("They",  1), pron).
upos(word("buy",   2), verb).
upos(word("and",   3), cconj).
upos(word("sell",  4), verb).
upos(word("books", 5), noun).

:- table udep/3.
:- table dep/3.

udep(word("buy", 2), [nsubj], word("They", 1)).
udep(word("buy", 2), [conj], word("sell", 4)).
udep(word("buy", 2), [obj], word("books", 5)).
udep(word("sell", 4), [cc], word("and", 3)).

%% Category axioms
udep(Word, [], Word) :- Word = word(_, _). % identity
udep(A, Path, C) :- % composition
    udep(A, Subpath1, B),
    udep(B, Subpath2, C),
    append(Subpath1, Subpath2, Path).

dep(A, Path, B) :- udep(A, Path, B).

%% Symmetric over conj
dep(Word1, [conj], Word2) :- udep(Word2, [conj], Word1).

%% Semantic meaning of conj
dep(A, Path, Destination) :- dep(A, [conj], B), udep(B, Path, Destination).

nominal(Word) :- upos(Word, noun).
nominal(Word) :- upos(Word, pron).

:- table link/3.

link(Noun1, [Verb], Noun2) :-
    nominal(Noun1),
    nominal(Noun2),
    dep(Verb, [nsubj], Noun1),
    dep(Verb, [obj], Noun2),
    upos(Verb, verb).

%% Category axioms
link(Noun, [], Noun) :- nominal(Noun). % identity
link(A, Path, C) :- % composition
    link(A, Subpath1, B),
    link(B, Subpath2, C),
    append(Subpath1, Subpath2, Path).
