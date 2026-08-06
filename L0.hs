module L0 where

import Language.Nanopass

[deflang|
(Lambda
  (Expr
    (Var String)
    (Lam String Expr)
    (App Expr Expr)
  ))|]
