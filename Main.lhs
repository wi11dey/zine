Haskell is the glue, so that you can think about the parts in isolation. Category theory style

> import Prelude hiding (id, (.))
> import Control.Category

This resolves a nominal into a specific noun
> resolve :: Nominal -> Noun

> data Relation = Nsubj
>               | Obj
>               | Iobj

> newtype Dependency source target = Dependency (source -> ([Relation], target))

Because Dependency is generic on any source or target, coreference can be handled separately on a PoS layer I bet

> instance Category Dependency where
>   id = Dependency $ \source -> ([], source)
>   (Dependency a) . (Dependency b) = Dependency $ \source ->
>     let (relations, intermediate) = a source
>         (relations', target) = b intermediate
>     in (relations ++ relations', target)

Dependency parsing happens sentence-by-sentence
> type Syntax = [Sentence]

UDPipe, lazily
> dependencyParse :: Text -> Syntax

Functor from the tree-category of Dependency to a meaningful category.
> understand :: Syntax -> Maybe Semantics

> explain :: Semantics -> Syntax

Maxima here, which needs a ECL FFI or general Lisp IPC
> simplify :: Math -> Math -- Maxima

Yi, The keybindings part
> interpret :: Input -> Command

Yi, stuff from EditorM for example
> execute :: Command -> State -> State

Custom, using typst-layout, which needs rust FFI or some (??) IPC
> view :: State -> DisplayList

WebRender ofc, which needs rust FFI or general Rust IPC
> webrender :: DisplayList -> GL

> createFrame :: IO GLContext

> read :: IO Input

The main interaction loop
> main :: IO ()
> main = do
>   frame <- createFrame
>   let interactionLoop state = do
>         display ((webrender . view) state) frame
>         input <- read
>         let state' = (execute . interpret) input state
>         interactionLoop state'
>   interactionLoop initialState

Profane definitions of types
> newtype GL = GL { display :: GLContext -> IO () }


PHILOSOPHY AND SHEAF THEORY

Need to think about the pushout of rooted words, which would connect subjects to objects via some actual relation. Because of the categorical structure of Dependency, only the dependency paths between two different tokens matters. Pushouts can be related to specific morphisms, and will probably be through things like verbs

If I was to use sheaf theory here, then I've broken the problem into:
- Local semantics
- gluing, including coreference probably
- Global semantics

Globally, I want to extract stuff like
> newtype Epistemology = Epistemology (Set Fact -> Knowledge)

What is true about both the local semantics and the global semantics? Both subcategories of Hask, likely, as they both need to be representable internally by the computer ultimately.

So what is Epistemology? It's a subcategory with only two objects and it goes unidirectionally. pushouts are what two epistemic systems have in common and pullbacks are the dual

what about hegel
> dialectic :: (Thesis * Thesis) -> Maybe Thesis

metaphysics: what is?
epistemology: what is knowledge?
ethics: what is just/right/needful?

probably can't constrain this too much -- maybe it's literally just collections of morphisms between two Hask objects
> newtype Philosophy a b = [a -> b]

ok now we might be getting somewhere, as I can also make morphisms from local semantics via pushouts through a tree root in the dependency parse. I don't necessarily have to ask from whence nouns came from (this is restricted to humans), just the relationships defined between them.
