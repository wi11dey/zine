Haskell is the glue, so that you can think about the parts in isolation

> import Prelude hiding (id, (.))
> import Control.Category

This resolves a nominal into a specific noun
> resolve :: Nominal -> Noun

> data Relation = Nsubj
>               | Obj
>               | Iobj

> newtype Dependency source target = Dependency (source -> ([Relation], target))

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

Need to think about the pushout of rooted words, which would connect subjects to objects via some actual relation. Because of the categorical structure of Dependency, only the dependency paths between two different tokens matters. Pushouts can be related to specific wor

Because Dependency is generic on any source or target, coreference can be handled separately on a PoS layer bet

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
