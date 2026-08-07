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
>     lowerNode = descendNode xlate
>
>     xlate = Xlate
>       { onDependencyDiscourse = Nothing
>       , onDependencyPunct = Nothing
>       , onUPOSPUNCT = Nothing
>       , onUPOSX = Nothing
>       , onDependency = const Nothing
>       , onNode = Just . \case
>           L0.Node dep pos word children →
>             Node <$> descendDependency xlate dep <*> descendUPOS xlate pos <*> pure word <*> pure (mapMaybe lowerNode children)
>       , onDependencyTree = Just . \case
>           L0.TreeRoot pos word children →
>             TreeRoot <$> descendUPOS xlate pos <*> pure word <*> pure (mapMaybe lowerNode children)
>       , onUPOS = const Nothing
>       }
