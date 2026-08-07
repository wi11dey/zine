== $L_2$

Now for the first structural change, though still bookeeping: splitting out any roots that may be internal in the tree. This should generally not happen, but will give a good feel for the more progressive enrichments ahead

/*

> module L2 where
>
> import Data.Functor.Const
> import Language.Nanopass
> import Language.Haskell.TH
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
> lower ∷ L1.DependencyTree w → Const [Root w] (DependencyTree w)
> lower = descendDependencyTree xlate
>   where
>     xlate = Xlate
>       { onDependency = const Nothing
>       , onDependencyTree = \case
>           L1.DependencyTree L1.Root _ _ _ → Nothing
>           L1.DependencyTree _ _ _ _ → Nothing
>       , onUPOS = const Nothing
>       , onDependencyRoot = undefined
>       }
