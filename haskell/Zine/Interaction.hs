module Zine.Interaction where

import GHC.Driver.Env.Types (HscEnv (..))
import GHC.Driver.Monad (GhcMonad (..))
import GHC.Runtime.Context (InteractiveContext (..))
import GHC.Runtime.Eval (execStmt')

restoreSession :: (GhcMonad m) => HscEnv -> m ()
restoreSession saved = do
  current <- getSession
  setSession $
    saved
      { -- Ensure the internal name counter stays monotonically increasing
        hsc_IC = (hsc_IC saved) {ic_mod_index = ic_mod_index (hsc_IC current)}
      }
