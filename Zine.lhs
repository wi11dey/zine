 #import "@preview/unidep:0.1.4": dependency-tree
 #import "@preview/xarrow:0.4.0": xarrow
 #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

 #let hs(module) = {
    let source = read(module + ".hs")
    source = source
        .split("\n")
        .filter(line => line != "$(pure [])")
        .filter(line => not line.starts-with("module "))
        .filter(line => not line.starts-with("import "))
        .join("\n")
    raw(source.trim(), lang: "haskell", block: true)
}

 #set raw(theme: bytes(```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>foreground</key><string>#000000</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key><string>keyword, storage.type, entity.other.inherited-class</string>
      <key>settings</key>
      <dict>
        <key>fontStyle</key><string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key><string>entity</string>
      <key>settings</key>
      <dict>
        <key>fontStyle</key><string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key><string>comment</string>
      <key>settings</key>
      <dict>
        <key>foreground</key><string>#666666</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
```.text))
 #show raw: set text(font: "New Computer Modern", size: 1.2em)

 #show raw.where(block: true): it => pad(x: 3em, it)

 #set text(lang: "en")
 #set par(justify: true, first-line-indent: 1.5em)
 #show title: set align(center)
 #show figure: it => pad(y: 8pt, it)
 #set figure.caption(separator: [. ])
 #show figure.caption: set text(style: "italic") // it => align(center, block(width: 60%)[#emph(it)])

 #title[#image("zine.svg", width: 3in, alt: "zine") _source_]

 #pad(x: 0.75in, bottom: 1em, outline(title: none))

Zine is a human-computer interaction language for philosophy. It is interesting in that its syntax is natural people language; in fact, most human languages can be used. Nevertheless, it is precise.

 #figure(image("zines.jpg", width: 100% + 2em, height: 2in, fit: "cover"), caption: [Zines from the seventies. @zines

Zine can also mean Zine Is Not Emacs, which I wrote this in.])

Zine is also a very good what-you-see-is-what-you-get editor for Typst @typst technical writing.

With the widespread usage of LLMs the bullshit machine is running at full steam, and nuance is swept under probabalism.

If we contrapose the continental traditions with the analytical tradition, broadly taken to include mathematics all the natural sciences. In the analytical tradition, the rejection of accepting all statements as true is so strong that there is .

Even a mediocre engineer can contribute, while philosophy still takes enough discipline of the mind that prevention of falsehood is accomplished in the field through massive exclusion.

In physics, the tenth grade student can understand the Rutherford model of the atom and accept it as a fact upon which to build without

Science requires fixing a model first

Haskell is the glue, so that you can think about the parts in isolation. Category theory style #lorem(50)

 #let imports = [

> module Main where
>
> import Prelude hiding (id, (.), read, Word)
> import qualified Prelude
> import Data.Kind (Constraint, Type)
> import Control.Arrow
> import Data.Maybe
> import Data.MultiMap (MultiMap, (!))
> import qualified Data.MultiMap as MultiMap

Typst is used for parsing

> import qualified Typst.Syntax

> import System.IO.Unsafe
> import qualified Language.C.Inline.Cpp as Cpp
> import Foreign.C.String
> import Foreign.Marshal.Alloc

> import Conllu.Parse
> import Conllu.Type (CW(..), Rel(..), AW, Sent(..))
> import qualified Conllu.Type as CoNLLU
> import qualified Conllu.DeprelTagset as D
> import Conllu.UposTagset ()
> import qualified Conllu.UposTagset as U

Intermediate representations

> import qualified L0
> import qualified L1
> import qualified L2

> type Word = CW AW

> Cpp.context Cpp.cppCtx
> Cpp.include "<iostream>"
> Cpp.include "<sstream>"
> Cpp.include "<udpipe.cpp>"

]

This resolves a nominal into a specific noun

> resolve ∷ Nominal → Noun

> newtype Dependency source target = Dependency (source → ([Rel], target))

Because Dependency is generic on any source or target, coreference can be handled separately on a PoS layer I bet

> --instance Category Dependency where
> --  id = Dependency $ \source → ([], source)
> --  (Dependency a) . (Dependency b) = Dependency $ \source →
> --    let (relations, intermediate) = b source
> --        (relations', target) = a intermediate
> --    in (relations ++ relations', target)

Dependency parsing happens sentence-by-sentence

> type Syntax = [Sentence]

UDPipe (maybe see https://github.com/fpco/inline-c), lazily

> dependencyParse ∷ Text → Syntax

Functor from the tree-category of Dependency to a meaningful category. See below @dependency-tree-topos -- use Prolog

> understand ∷ Syntax → Maybe Semantics

> explain ∷ Semantics → Syntax

Maxima here, which needs a ECL FFI or general Lisp IPC

> simplify ∷ Math → Math -- Maxima

Yi, The keybindings part

> interpret ∷ Input → Command

Yi, stuff from EditorM for example

> execute ∷ Command → State → State

Custom, using typst-layout, which needs rust FFI or some (??) IPC

> view ∷ State → DisplayList

WebRender ofc, which needs rust FFI (see https://github.com/harpocrates/inline-rust) or general Rust IPC

> webrender ∷ DisplayList → GL

> typstLayout ∷ Typst.Syntax.Markup → DisplayList

> createFrame ∷ IO GLContext

> read ∷ IO Input

The main interaction loop

> main ∷ IO ()
> main = do
>   frame ← createFrame
>   let interactionLoop state = do
>         display ((webrender . view) state) frame
>         input ← read
>         let state' = (execute . interpret) input state
>         interactionLoop state'
>   interactionLoop initialState

Profane definitions of types

> newtype GL = GL { display ∷ GLContext → IO () }

Haskell default and glue:
- Prolog (NLP <-> Topos <-> FOL).
    Maybe this can be in native Haskell or scheme
- Lisp (CAS)
    Better interop with scheme
- Rust (rendering)
- C++ (text tagging, Firefox IPDL)
    Can be done with udpipe-rs

lol maybe idris instead of haskell -> scheme
  -> rust marwood or other scheme implementation for display list, udpipe-rs
  -> prolog with call/cc
  -> lisp direct interop with scheme lists but embedded via ecl2

if they're all separate, you could get a prolog repl, an ECL repl, and a GHCI repl

maybe prolog translates directly into lispy things

haskell -> prolog -> lisp

 #set heading(numbering: "1.")

= Philosophy and sheaf theory

For example, epistemology, at its most basic, can be considered

 #figure(diagram($"Fact" edge(->) & "Knowledge"$))

Need to think about the pushout of rooted words, which would connect subjects to objects via some actual relation. Because of the categorical structure of Dependency, only the dependency paths between two different tokens matters. Pushouts can be related to specific morphisms, and will probably be through things like verbs

If I was to use sheaf theory here, then I've broken the problem into:
- Local semantics
- gluing, including coreference probably
- Global semantics

Globally, I want to extract stuff like

> newtype Epistemology = Epistemology (Set Fact → Knowledge)

What is true about both the local semantics and the global semantics? Both subcategories of Hask, likely, as they both need to be representable internally by the computer ultimately.

So what is Epistemology? It's a subcategory with only two objects and it goes unidirectionally. pushouts are what two epistemic systems have in common and pullbacks are the dual

what about hegel

> dialectic ∷ (Thesis, Thesis) → Maybe Thesis

metaphysics: what is?
epistemology: what is knowledge?
ethics: what is just/right/needful?

probably can't constrain this too much -- maybe it's literally just collections of morphisms between two Hask objects

```haskell
type Philosophy a b = [a → b]
```

ok now we might be getting somewhere, as I can also make morphisms from local semantics via pushouts through a tree root in the dependency parse. I don't necessarily have to ask from whence nouns came from (this is restricted to humans), just the relationships defined between them.

= Universal dependencies

These are all the thirty-seven relations in the Universal Dependencies grammar @ud.

I'm currently just considering the input as CoNLL-U, wherever it comes from. For English and other well-resourc, UDPipe 1 is probably sufficient.

This version keeps reloading the model, which is slow. I'm thinking I should keep a global cache of the models and never unload them, and manage that from C++. Also, errors should get propagated up somehow; right now, they just get printed out to the host process' standard error.

> {-# NOINLINE udPipe #-}
>
> udPipe ∷ FilePath → String → String
> udPipe modelPath sentence = unsafePerformIO do
>   withCString modelPath \cModel → withCString sentence \cSentence → do
>       output ← [Cpp.exp| char* { [&]() -> char* {
>       using namespace ufal::udpipe;
>
>       model* m = model::load($(char* cModel));
>       if (!m) {
>         return strdup("");
>       }
>
>       pipeline p(
>         m,
>         "tokenizer=ranges",
>         pipeline::DEFAULT,
>         pipeline::DEFAULT,
>         "conllu"
>       );
>
>       std::istringstream input($(char* cSentence));
>       std::ostringstream output;
>       std::string error;
>
>       bool succeeded = p.process(input, output, error);
>       if (!succeeded) {
>         std::cerr << error << '\n';
>       }
>
>       delete m;
>       return strdup(succeeded ? output.str().c_str() : "");
>     }() } |]
>       result ← peekCString output
>       free output
>       pure result
>
> parse ∷ FilePath → String → Either String CoNLLU.Doc
> parse modelPath = parseConllu "" . udPipe modelPath

= Nanopass

Kent Dyvbig's _nanopass_ framework @nanopass. I use Marseille Bouchard Demko's nanopass Haskell implementation here.

 #include("L0.typ")

This language is a tree, while CoNLL-U is a flat format. Therefore,

> docToL0 ∷ CoNLLU.Doc → [L0.DependencyTree Word]
> docToL0 = concatMap sentenceToL0
>   where
>     sentenceToL0 sentence =
>       let idToChildren = MultiMap.fromList do
>             word@(_rel → Just rel) ← _words sentence
>             return (_head rel, (_deprel rel, word))
>           toTree rootId = do
>             (dep, child) ← idToChildren ! rootId
>             return $
>               L0.DependencyTree
>                 (toEnum $ fromEnum dep)
>                 (toEnum $ fromEnum $ fromMaybe U.X $ _upos child)
>                 child $
>                 toTree $ _id child
>       in toTree $ CoNLLU.SID 0

We convert between `hs-conllu`'s and $L_0$'s representations of `UPOS` and dependency relations via the integral `Enum` representation.

> deriving instance Enum (L0.UPOS w)
> deriving instance Enum (L0.Dependency w)

 #include("L1.typ")
 #include("L2.typ")

= Category theory

== Definitions

If you're already familiar with categories and their representation in Haskell, you can skip this section. (There is already `Control.Category`, but it is necessarily a _wide_ category, where its objects are always $"Ob"(bold("Hask"))$.)

Haskell categories

> class Category (k ∷ Type → Type → Type) where
>   type Ob k (a ∷ Type) ∷ Constraint
>   id ∷ Ob k a ⇒ k a a
>   (.) ∷ (Ob k a, Ob k b, Ob k c) ⇒ k b c → k a b → k a c
> 
> instance Category (→) where
>   type Ob (→) a = ()
>   id x = x
>   (g . f) x = g (f x)

Using CoNLL-U

```prolog
mor(Category, A, A) :- id(Category, A).
mor(Category, A, C) :- mor(Category, A, B), mor(Category, B, C).
```

== A Dependency Tree Topos <dependency-tree-topos>

This is the core (Hegelian and category-theoretic) claim: *every noun is a verb-morphism between two other nouns*. For example, $"Nothing" xarrow("Knowledge") "Something"$.

 #block(sticky: true)[Consider the dependency tree parse of the following sentence]

 #figure(dependency-tree(```
1	They	they	PRON	PRP	Case=Nom|Number=Plur|Person=3|PronType=Prs	2	nsubj	_	TokenRange=0:4
2	buy	buy	VERB	VBP	Mood=Ind|Tense=Pres|VerbForm=Fin	0	root	_	TokenRange=5:8
3	and	and	CCONJ	CC	_	4	cc	_	TokenRange=9:12
4	sell	sell	VERB	VBP	Mood=Ind|Tense=Pres|VerbForm=Fin	2	conj	_	TokenRange=13:17
5	books	book	NOUN	NNS	Number=Plur	2	obj	_	SpaceAfter=No|TokenRange=18:23
```.text, level-height: 0.6, show-upos: true, show-root: false))

See Welsh

 #figure(dependency-tree(```
1	Wyt	bod	VERB	verb	Mood=Ind|Number=Sing|Person=2|Tense=Pres|VerbForm=Fin	0	root	_	TokenRange=0:3
2	ti	ti	PRON	indep	Number=Sing|Person=2|PronType=Prs	1	nsubj	_	SpaceAfter=No|TokenRange=4:6
3	'n	yn	AUX	impf	_	4	aux	_	TokenRange=6:8
4	nofio	nofio	NOUN	verbnoun	Number=Sing|VerbForm=Vnoun	1	xcomp	_	TokenRange=9:14
5	gyda	gyda	ADP	prep	_	7	case	_	TokenRange=15:19
6	dy	ti	PRON	dep	Number=Sing|Person=2|Poss=Yes|PronType=Prs	7	nmod:poss	_	TokenRange=20:22
7	ffrindiau	ffrind	NOUN	noun	Gender=Fem|Number=Plur	4	nmod	_	TokenRange=23:32
8	yfory	yfory	ADV	adv	_	7	advmod	_	SpaceAfter=No|TokenRange=33:38
9	?	?	PUNCT	punct	_	1	punct	_	SpaceAfter=No|TokenRange=38:39
```.text, level-height: 0.6, show-upos: true, show-root: false))

 #block(sticky: true)[Let's define the type of dependency trees.]

> data DependencyTree a = DependencyTree {
>   word ∷ a,
>   children ∷ [(Rel, DependencyTree a)]
> } deriving Functor

From this, you could construct the free category $cal(D)$ with paths as morphisms. We get the following morphisms in $bold("Cat")$:

 #figure(diagram($cal(D) edge(T, "hook->") & cal(T)$))

To any dependency parse, we can associate a category, say $cal(D)$, by considering the objects as words (and their indices) and the morphisms as dependencies. To be precise, $"Ob"(cal(D))={("They", 1),("buy", 2),...}$ and $"mor"(cal(D))={(("buy", 2), [italic("nsubj")], ("They", 1)),...}$. I'll use $"buy"_2 xarrow("nsubj") "They"_2$ as notation for ${(("buy", 2), italic("nsubj"), ("They", 1))} in "mor"(cal(D))$ from here forward.

Topos of local truth constructed in just one sentence. First add necessary pushouts of morphisms through relation words to construct just noun phrases as objects in the category. Objects are nominals that are related to

The category of elementary topoi $bold("Top")$ is a $2$-subcategory of the $2$-category $bold("Cat")$

Maybe--
Terminal object: "this"/unrestricted PRON
Binary products: different sentences, indicates that two independent clauses can be broken up
Equalizer: CCONJ/union
Exponential: linguistic recursion/which
Omega: "itself" all nouns
Sub object classifier: X--copula-->"itself"

Existential quantification would use "this", whereas the default is just universal. i.e. Red is bright vs this red is bright.

Now that I have a sheaf topos, I would like to be able to glue it together into a general understanding. The glue will inevitably have a nonzero cohomology in which case we will fail to synthesize a global understanding. But say we have a global understanding; then we can understand how different parts fit together by alternating between natural language representation and the categorical.

Once I have a local topos, I can attempt gluing using some kind of ACL2 combo or H-M unification, or both. I will need to figure this out later, and the exact system by which the local, overfit, understanding gets generalized to the global will determine the cohomology.

Maybe have a two-level sheaf attempting to glue sentences together in one argument, using some natural deduction and coreference (H-M unification there?) in the glue between sentences which are part of a topos. Then, can try a different kind of glue to see how two arguments fit together, and which way the functors go between them. Maybe the higher level isn't even a sheaf and just a topology defined on it.

= Feeling the elephant

= Diagrams

== 3D

////// APPENDICES //////
 #[
 #counter(heading).update(0)
 #set heading(numbering: "A.")
 #show heading.where(level: 1): it => [#pagebreak() Appendix #counter(heading).display("A.") #it.body]

= Referenced packages

The following imports were used in this Literate Haskell source file.

 #imports

= Stubs

> resolve = undefined
> dependencyParse = undefined
> understand = undefined
> explain = undefined
> simplify = undefined
> interpret = undefined
> execute = undefined
> view = undefined
> webrender = undefined
> createFrame = undefined
> read = undefined
> initialState = undefined
> dialectic = undefined
> typstLayout = undefined
>
> data Nominal = Nominal
> data Noun = Noun
> data Sentence = Sentence
> data Text = Text
> data Semantics = Semantics
> data Math = Math
> data Input = Input
> data Command = Command
> data State = State
> data DisplayListItem = DisplayListItem
> type DisplayList = [DisplayListItem]
> data GLContext = GLContext
> data Set a = Set
> data Fact = Fact
> data Knowledge = Knowledge
> data Thesis = Thesis

]

 #pagebreak()
 #bibliography(bytes(```bib
@article{ud,
  title={Universal dependencies},
  author={De Marneffe, Marie-Catherine and Manning, Christopher D and Nivre, Joakim and Zeman, Daniel},
  journal={Computational linguistics},
  volume={47},
  number={2},
  pages={255--308},
  year={2021}
}
@misc{zines,
  author={Jake},
  title={Fanzines from the 1970s},
  howpublished={\url{https://www.flickr.com/photos/stillunusual/21224199545}},
  note={Licensed under CC BY 2.0 (\url{https://creativecommons.org/licenses/by/2.0/deed.en})},
  year={2015},
  month=sep
}
@article{typst,
  title={Typst: A Modern Typesetting Engine for Science},
  author={Voynov, Andrey and Corbi, Alberto and L{\'o}pez-Oliver, Pau and Gil Oliva, David},
  year={2026},
  publisher={Universidad Internacional de La Rioja}
}
@InProceedings{udpipe,
  author    = {Straka, Milan  and  Strakov\'{a}, Jana},
  title     = {Tokenizing, POS Tagging, Lemmatizing and Parsing UD 2.0 with UDPipe},
  booktitle = {Proceedings of the CoNLL 2017 Shared Task: Multilingual Parsing from Raw Text to Universal Dependencies},
  month     = {August},
  year      = {2017},
  address   = {Vancouver, Canada},
  publisher = {Association for Computational Linguistics},
  pages     = {88--99},
  url       = {http://www.aclweb.org/anthology/K/K17/K17-3009.pdf}
}
@inproceedings{udeplambda,
  title={Universal semantic parsing},
  author={Reddy, Siva and T{\"a}ckstr{\"o}m, Oscar and Petrov, Slav and Steedman, Mark and Lapata, Mirella},
  booktitle={Proceedings of the 2017 Conference on Empirical Methods in Natural Language Processing},
  pages={89--101},
  year={2017}
}
@inproceedings{heinecke2019,
  author = {Heinecke, Johannes and Tyers, Francis M.},
  title = {{Development of a Universal Dependencies treebank for Welsh}},
  year = {2019},
  booktitle = {{Proceedings of the Celtic Language Technology Workshop}},
  publisher = {European Association for Machine Translation},
  address = {Dublin},
  pages = {21--31},
  url = {https://www.aclweb.org/anthology/W19-6904},
}
@inproceedings{nanopass,
  title={A nanopass framework for commercial compiler development},
  author={Keep, Andrew W and Dybvig, R Kent},
  booktitle={Proceedings of the 18th ACM SIGPLAN international conference on Functional programming},
  pages={343--350},
  year={2013}
}
```.text), title: [References], style: "nature")

// Local Variables:
// outline-regexp: "^=+"
// End:
