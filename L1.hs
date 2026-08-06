module L1 where

import Data.Functor.Identity
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

compile ∷ Expr → L0.Expr
compile = runIdentity . descendExpr xlate
  where
  xlate = Xlate
    -- the onExprLet is required because nanopass couldn't find an automatic translation
    { onExprLet = \binds body → do
        binds' ← traverse descendBinding binds
        body' ← descendExpr xlate body
        pure $ foldr unlet body' binds'
    -- the `onExpr` member allows us to optionally override the default translation when necessary
    , onExpr = const Nothing -- we don't need to override anything
    }
  descendBinding (x, e) = do
    e' ← descendExpr xlate e
    pure (x, e')
  unlet (x, e) body = (L0.Lam x body) `L0.App` e
