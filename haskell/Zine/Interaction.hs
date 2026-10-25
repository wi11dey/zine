{-# LANGUAGE OverloadedStrings #-}

module Zine.Interaction where

import Data.Text (Text)
import Data.Void (Void)
import GHC.Driver.Env.Types (HscEnv (..))
import GHC.Driver.Monad (GhcMonad (..))
import GHC.Hs (GhciLStmt)
import GHC.Hs.Extension (GhcPs)
import GHC.Runtime.Context (InteractiveContext (..))
import GHC.Runtime.Eval (execStmt')
import GHC.ThToHs (convertToHsExpr)
import Language.Haskell.TH
import Text.Megaparsec
import Text.Megaparsec.Char

type Parser = Parsec Void Text

restoreSession :: (GhcMonad m) => HscEnv -> m ()
restoreSession saved = do
  current <- getSession
  setSession $
    saved
      { -- Ensure the internal name counter stays monotonically increasing
        hsc_IC = (hsc_IC saved) {ic_mod_index = ic_mod_index (hsc_IC current)}
      }

-- | A single letter is a variable.
variable :: Parser Exp
variable = do
  name <- letterChar
  return $ LitE (StringL [name])

operator :: Parser Exp
operator = do
  name <- some letterChar
  return $ VarE (mkName name)

fromTypstMath :: Parser Exp
fromTypstMath = undefined

toGhciLStmt :: Exp -> GhciLStmt GhcPs
toGhciLStmt = undefined
