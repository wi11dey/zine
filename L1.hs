module L1 where

import qualified Prelude
import Prelude hiding (Word)
import Data.Data (Data)
import Data.Generics (everywhere', mkT)
import Language.Nanopass
import qualified L0

[deflang|
((Stripped w) from L0:UD
  (* Dependency
    (- Punct)))|]

$(pure [])

[defpass|(from L0:UD to Stripped)|]

deriving instance Data w ⇒ Data (L0.DependencyTree w)
deriving instance Data w ⇒ Data (L0.Dependency w)
deriving instance Data w ⇒ Data (L0.UPOS w)

lower ∷ ∀ w. Data w ⇒ L0.DependencyTree w → DependencyTree w
lower =
  descendDependencyTreeI XlateI
    { onDependencyPunctI = undefined
    , onDependencyI = const Nothing
    , onDependencyTreeI = const Nothing
    , onUPOSI = const Nothing
    }
    . everywhere'
      (mkT
        (Prelude.filter
          (\(dependency, _) → case dependency of
            L0.Punct → False
            _ → True)
        ∷ [(L0.Dependency w, L0.DependencyTree w)] → [(L0.Dependency w, L0.DependencyTree w)]))
