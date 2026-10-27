module Zine.Prelude
  ( module Symtegration,
  )
where

import NumericPrelude
import Symtegration

data Argument = Positional Expression
              | Named String Expression
