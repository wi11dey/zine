module Zine.Interaction where

import Data.Text (Text)
import Data.Void (Void)
import GHC.Driver.Env.Types (HscEnv (..))
import GHC.Driver.Monad (GhcMonad (..))
import GHC.Hs (GhciLStmt)
import GHC.Hs.Extension (GhcPs)
import GHC.Runtime.Context (InteractiveContext (..))
import GHC.Runtime.Eval (execStmt')
import Text.Megaparsec (Parsec)

type Parser = Parsec Void Text

restoreSession :: (GhcMonad m) => HscEnv → m ()
restoreSession saved = do
  current ← getSession
  let restoredContext =
        (hsc_IC saved)
          { ic_mod_index = ic_mod_index (hsc_IC current)
          }
  setSession $ saved {hsc_IC = restoredContext}

fromTypst :: Text -> GhciLStmt GhcPs
fromTypst = undefined
