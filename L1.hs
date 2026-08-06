module L1 where

import Data.Maybe
import Language.Nanopass
import qualified L0

[deflang|
((Stripped w) from L0:UD
  (* Dependency
    (- Punct)
    (- Discourse))
  (* UPOS
    (- PUNCT)
    (- X)))|]

$(pure [])

[defpass|(from L0:UD to Stripped)|]

lower ∷ L0.DependencyTree w → Maybe (DependencyTree w)
lower = descendDependencyTree xlate
  where
    xlate = Xlate
      { onDependencyDiscourse = Nothing
      , onDependencyPunct = Nothing
      , onUPOSPUNCT = Nothing
      , onUPOSX = Nothing
      , onDependency = const Nothing
      , onDependencyTree = Just . \case
          L0.Root pos word children →
            Root <$> descendUPOS xlate pos <*> pure word <*> pure (mapMaybe lower children)
          L0.Branch dep pos word children →
            Branch <$> descendDependency xlate dep <*> descendUPOS xlate pos <*> pure word <*> pure (mapMaybe lower children)
      , onUPOS = const Nothing
      }
