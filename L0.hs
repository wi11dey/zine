module L0 where

import Language.Nanopass
import qualified Conllu.DeprelTagset as D

[deflang|
(Lambda
  (Expr
    (Var String)
    (Lam String Expr)
    (App Expr Expr)
    (Word D:EP)
  ))|]
