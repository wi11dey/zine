== $L_2$

Now for the first structural change, though still bookeeping: splitting out any roots that may be internal in the tree. This should generally not happen, but will give a good feel for the more progressive enrichments ahead

/*

> module L2 where
>
> import Language.Nanopass
> import Language.Haskell.TH
> import Control.Monad.Trans.Maybe
> import Control.Monad.Trans.Writer
> import Control.Applicative
> import Control.Monad.Trans.Class
> import qualified L1

*/

> [deflang|
> ((Rooted w) from L1:Stripped
>   (+ Root
>     (Root UPOS w (* DependencyTree)))
>   (* Dependency
>     (- Root)))|]
>
> $(newDeclarationGroup)
>
> [defpass|(from L1:Stripped to Rooted)|]
>
> lower ∷ L1.DependencyTree w → [Root w]
> lower = snd . runWriter . runMaybeT . collectRoots
>   where
>     collectRoots tree@(L1.DependencyTree dep upos word children) =
>       case runWriter (runMaybeT (descendDependency xlate dep)) of
>         (Nothing, _) → do
>           upos' ← descendUPOS xlate upos
>           children' ← mapM (descendDependencyTree xlate) children
>           lift $ tell [Root upos' word children']
>           empty
>         _ → descendDependencyTree xlate tree
>     xlate = Xlate
>       { onUPOS = const Nothing
>       , onDependencyTree = const Nothing
>       , onDependency = const Nothing
>       , onDependencyRoot = empty
>       }
