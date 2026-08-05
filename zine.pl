:- use_module(library(process)).
:- use_module(library(readutil)).

:- dynamic upos/2.
:- dynamic udep/3.

load_text(Text) :-
    retractall(upos(_, _)),
    retractall(udep(_, _, _)),
    process_create(
        './udpipe/src/udpipe',
        ['--tokenize', '--tag', '--parse',
         'english-ewt-ud-2.5-191206.udpipe'],
        [stdin(pipe(In)), stdout(pipe(Out)), stderr(null), process(PID)]
    ),
    format(In, '~s~n', [Text]),
    close(In),
    read_string(Out, _, Conllu),
    close(Out),
    process_wait(PID, exit(0)),
    parse_conllu(Conllu),
    abolish_all_tables.

parse_conllu(Conllu) :-
    split_string(Conllu, "\n", "\r", Lines),
    findall(row(Id, Form, UPos, Head, Rel),
            (member(Line, Lines),
             split_string(Line, "\t", "", Fields),
             Fields = [IdS, Form, _, UPosS, _, _, HeadS, RelS|_],
             number_string(Id, IdS),
             number_string(Head, HeadS),
             downcase_atom(UPosS, UPos),
             atom_string(Rel, RelS)),
            Rows),
    forall(member(row(Id, Form, UPos, _, _), Rows),
           assertz(upos(word(Form, Id), UPos))),
    forall((member(row(Id, Form, _, Head, Rel), Rows),
	    Head > 0,
	    member(row(Head, HeadForm, _, _, _), Rows)),
           assertz(udep(word(HeadForm, Head), Rel, word(Form, Id)))).

mor(ud, Head, [Relation], Dependent) :-
    udep(Head, Relation, Dependent).

:- discontiguous mor/4.
:- discontiguous id/3.
:- discontiguous compose/4.

:- table mor/4.

mor(Category, A, Id, A) :- id(Category, Id, A).
mor(Category, A, Morphism, C) :-
    mor(Category, A, Factor1, B),
    mor(Category, B, Factor2, C),
    compose(Category, Factor1, Factor2, Morphism).
ob(Category, Objects) :- findall(A, mor(Category, A, _, A), Objects).
hom(Category, A, B, Morphisms) :- setof(Morphism, mor(Category, A, Morphism, B), Morphisms).

% Example
%% upos(word("They",  1), pron).
%% upos(word("buy",   2), verb).
%% upos(word("and",   3), cconj).
%% upos(word("sell",  4), verb).
%% upos(word("books", 5), noun).

% Category ud
id(ud, [], Word) :- upos(Word, _).
compose(ud, Subpath1, Subpath2, Path) :- append(Subpath1, Subpath2, Path).
% Example
%% mor(ud, word("buy", 2), [nsubj], word("They", 1)).
%% mor(ud, word("buy", 2), [conj], word("sell", 4)).
%% mor(ud, word("buy", 2), [obj], word("books", 5)).
%% mor(ud, word("sell", 4), [cc], word("and", 3)).

% Derived category dep
mor(dep, A, Path, B) :- mor(ud, A, Path, B).
mor(dep, Conjunct, [conj], Head) :-
    mor(ud, Head, [conj], Conjunct),
    mor(ud, Conjunct, [cc], _).
%% mor(dep, Word1, [conj], Word2) :- mor(ud, Word2, [conj], Word1). % conj is syntactically symmetric
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

% Check out UDepLambda from here
