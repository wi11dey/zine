module L1 where

import Language.Nanopass
import qualified L0

[deflang|
(LambdaLet from L0:Lambda
  (* Expr
    (+ Let
      (+ (& String Expr))
      Expr)))|]
$(pure [])

[defpass|(from LambdaLet to L0:Lambda)|]

lower ∷ Expr → L0.Expr
lower = descendExprI xlate
  where
  xlate = XlateI
    { onExprLetI = \binds body →
        foldr unlet (descendExprI xlate body) (fmap descendBinding binds)
    , onExprI = const Nothing
    , onDepI = const Nothing
    }
  descendBinding (x, e) = (x, descendExprI xlate e)
  unlet (x, e) body = (L0.Lam x body) `L0.App` e
