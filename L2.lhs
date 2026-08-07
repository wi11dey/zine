== $L_2$

Now for the first structural change, though still bookeeping: splitting out any roots that may be internal in the tree. This should generally not happen, but will give a good feel for the more progressive enrichments ahead

> module L2 where

/*

> import Data.Maybe
> import Language.Nanopass
> import Language.Haskell.TH
> import qualified L1

*/

> [deflang|
> ((Rooted w) from L1:Stripped)|]
>
> $(newDeclarationGroup)
>
> [defpass|(from L1:Stripped to Rooted)|]
>
> lower ∷ L1.DependencyTree w → DependencyTree w
> lower = descendDependencyTreeI xlate
>   where
>     xlate = XlateI
>       { onDependencyI = const Nothing
>       , onDependencyTreeI = const Nothing
>       , onUPOSI = const Nothing
>       }
