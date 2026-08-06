module L1 where

import Language.Nanopass
import qualified L0

[deflang|
(LambdaLet from L0.Lambda
  (* Expr
    (+ Let
      (+ (& String Expr))
      Expr)))|]

$(pure [])

[defpass|(from LambdaLet to Lambda)|]

compile :: L0.Expr -> Expr
compile = runIdentity . descendExpr xlate
  where
  xlate :: Xlate Identity -- type signature unneeded, but included for explanatory purposes
  xlate = Xlate
    -- the onExprLet is required because nanopass couldn't find an automatic translation
    { onExprLet = \binds body -> pure $ foldr unlet body binds
    -- the `onExpr` member allows us to optionally override the default translation when necessary
    , onExpr = const Nothing -- we don't need to override anything
    }
  unlet body (x, e) = (Lam x body) `App` e
