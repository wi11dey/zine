== L1

First, let's get some annoyances out of the way. Since ZINE leaves all conntation to the human, discourse words are

> module L1 where

 #let l1imports = [

> import Data.Maybe
> import Language.Nanopass
> import Language.Haskell.TH
> import qualified L0

]

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
>       , onDependency = const Nothing
>       , onDependencyTree = \(L0.DependencyTree dep pos word children) →
>           Just $
>             DependencyTree <$>
>               descendDependency xlate dep <*>
>               descendUPOS xlate pos <*>
>               pure word <*>
>               pure (mapMaybe (descendDependencyTree xlate) children)
>       , onUPOS = const Nothing
>       }
