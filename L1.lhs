== $L_1$

First, let's get some annoyances out of the way. Since we're leaving all conntation to the human, discourse words are

> module L1 where

/*

> import Data.Maybe
> import Language.Nanopass
> import Language.Haskell.TH
> import qualified L0

*/

> [deflang|
> ((Stripped w) from L0:UD
>   (* Dependency
>     (- Punct)
>     (- Discourse))
>   (* UPOS
>     (- PUNCT)
>     (- X)))|]
>
> $(newDeclarationGroup)
>
> [defpass|(from L0:UD to Stripped)|]
>
> lower ∷ L0.DependencyTree w → Maybe (DependencyTree w)
> lower = descendDependencyTree xlate
>   where
>     xlate = Xlate
>       { onDependencyDiscourse = Nothing
>       , onDependencyPunct = Nothing
>       , onUPOSPUNCT = Nothing
>       , onUPOSX = Nothing
>       , onDependencyTree = \(L0.DependencyTree dep pos word children) →
>           Just $
>             DependencyTree <$>
>               descendDependency xlate dep <*>
>               descendUPOS xlate pos <*>
>               pure word <*>
>               pure (mapMaybe (descendDependencyTree xlate) children)
>       , onDependency = const Nothing
>       , onUPOS = const Nothing
>       }
