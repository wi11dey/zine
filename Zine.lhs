 #import "@preview/unidep:0.1.4": dependency-tree
 #import "@preview/xarrow:0.4.0": xarrow
 #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

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
 #show figure.caption: set text(style: "italic")

 #title[#image("zine.svg", width: 3in, alt: "zine") _source_]

 #pad(x: 0.75in, bottom: 1em, outline(title: none))

Zine is a language for doing philosophy. It is interesting in that its syntax is natural people language; in fact, most human languages can be used. Nevertheless, it is precise.

 #pad(
    y: 1em,
    figure(
        image("zines.jpg", width: 100% + 2em, height: 2in, fit: "cover"),
        caption: [Zines from the seventies @zines]
    )
)

In this age of LLMs, the bullshit machine is running at full steam, and all of nuance is swept under probabalism.

If we contrapose the continental traditions with the analytical tradition, broadly taken to include mathematics all the natural sciences. In the analytical tradition, the rejection of accepting all statements as true is so strong that there is .

Even a mediocre engineer can contribute, while philosophy still takes enough discipline of the mind that prevention of falsehood is accomplished in the field through massive exclusion.

In physics, the tenth grade student can understand the Rutherford model of the atom and accept it as a fact upon which to build without

Science requires fixing a model first

Haskell is the glue, so that you can think about the parts in isolation. Category theory style #lorem(50)

 #let imports = [

> import Data.Kind (Constraint, Type)
> import Prelude hiding (id, (.), read)

]

This resolves a nominal into a specific noun

> resolve ∷ Nominal → Noun

These are all the thirty-seven relations in the Universal Dependencies grammar @ud.

> data Relation = Nsubj
>               | Obj
>               | Iobj
>               deriving (Eq, Ord, Enum)

> newtype Dependency source target = Dependency (source → ([Relation], target))

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

= Category theory

== Definitions

If you're already familiar with categories and their representation in Haskell, you can skip this section. (There is already `Control.Category`, but it is necessarily a _wide_ category, where its objects are always $"Ob"(bold("Hask"))$.)

Haskell categories

> class Category (k ∷ Type → Type → Type) where
>   type Object k (a ∷ Type) ∷ Constraint
> 
>   id ∷ Object k a ⇒ k a a
> 
>   (.) ∷ (Object k a, Object k b, Object k c) ⇒ k b c → k a b → k a c
> 
> instance Category (→) where
>   type Object (→) a = ()
>   id x = x
>   (g . f) x = g (f x)

== A Dependency Tree Topos <dependency-tree-topos>

Consider a dependency tree

 #figure(dependency-tree(```
1	They	they	PRON	PRP	_	2	nsubj	_	_
2	buy	buy	VERB	VBP	_	0	root	_	_
3	and	and	CCONJ	CC	_	4	cc	_	_
4	sell	sell	VERB	VBP	_	2	conj	_	_
5	books	book	NOUN	NNS	_	2	obj	_	_
6	.	.	PUNCT	.	_	2	punct	_	_
```.text))

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
> data DisplayList = DisplayList
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
```.text), title: [References], style: "nature")

// Local Variables:
// outline-regexp: "^=+"
// End:
