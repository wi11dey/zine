{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Language.Zine.MathematicsSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text)
import Data.Void (Void)
import GHC.Data.FastString (unpackFS)
import GHC.Hs (HsExpr (..), HsLit (..), HsOverLit (..), OverLitVal (..))
import GHC.Hs.Extension (GhcPs)
import GHC.Types.Name.Occurrence (occNameString)
import GHC.Types.Name.Reader (rdrNameOcc)
import GHC.Types.SourceText (il_value)
import GHC.Types.SrcLoc (unLoc)
import Language.Haskell.TH (mkName, varE)
import qualified Language.Haskell.TH as TH
import Language.Zine.Mathematics
import Test.Hspec
import Text.Megaparsec (ParseErrorBundle, eof, parse)

spec :: Spec
spec = do
  describe "number" $ do
    it "parses zero as an integer literal" $ do
      expected <- [|0|]
      parseExpression number "0" `shouldBe` Right expected

    it "parses integers larger than a machine word" $ do
      expected <- [|123456789012345678901234567890|]
      parseExpression number "123456789012345678901234567890" `shouldBe` Right expected

    it "consumes trailing whitespace" $ do
      expected <- [|42|]
      parseExpression number "42 \t\n" `shouldBe` Right expected

    it "requires at least one digit" $
      parseExpression number "" `shouldSatisfy` isLeft

    it "leaves a following token available to its caller" $ do
      expectedNumber <- [|42|]
      expectedSymbol <- [|$(varE (mkName "alpha"))|]
      let numberThenSymbol = do
            value <- asTH <$> number
            name <- asTH <$> symbol
            pure (value, name)
      parseAll numberThenSymbol "42alpha" `shouldBe` Right (expectedNumber, expectedSymbol)

  describe "symbol" $ do
    it "represents a single letter as a string literal" $ do
      expected <- [|"x"|]
      parseExpression symbol "x" `shouldBe` Right expected

    it "represents a single Unicode letter as a string literal" $ do
      expected <- [|"α"|]
      parseExpression symbol "α" `shouldBe` Right expected

    it "represents a longer identifier as a variable" $ do
      expected <- [|$(varE (mkName "alpha"))|]
      parseExpression symbol "alpha" `shouldBe` Right expected

    it "joins qualified names with apostrophes" $ do
      expected <- [|$(varE (mkName "arrow'r'long"))|]
      parseExpression symbol "arrow.r.long" `shouldBe` Right expected

    it "treats qualified single-letter components as a variable" $ do
      expected <- [|$(varE (mkName "a'b"))|]
      parseExpression symbol "a.b" `shouldBe` Right expected

    it "rejects an incomplete qualified name" $
      parseExpression symbol "arrow." `shouldSatisfy` isLeft

parseAll :: Parser a -> Text -> Either (ParseErrorBundle Text Void) a
parseAll parser = parse (parser <* eof) "<test>"

-- Keep the existing expectations while checking GHC's parsed constructors.
asTH :: HsExpr GhcPs -> TH.Exp
asTH (HsOverLit _ OverLit {ol_val = HsIntegral literal}) = TH.LitE (TH.IntegerL (il_value literal))
asTH (HsLit _ (HsString _ value)) = TH.LitE (TH.StringL (unpackFS value))
asTH (HsVar _ name) = TH.VarE (mkName (occNameString (rdrNameOcc (unLoc name))))
asTH (OpApp _ lhs operator rhs) = TH.UInfixE (asTH (unLoc lhs)) (asTH (unLoc operator)) (asTH (unLoc rhs))
asTH _ = error "unexpected GHC expression in parser result"

parseExpression :: Parser (HsExpr GhcPs) -> Text -> Either (ParseErrorBundle Text Void) TH.Exp
parseExpression parser = parseAll (asTH <$> parser)
