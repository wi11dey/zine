{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Language.Zine.MathematicsSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text)
import Data.Void (Void)
import GHC.Hs (HsExpr (..), HsLit (..), mkHsIsString, noExtField)
import GHC.Hs.Dump (BlankEpAnnotations (..), BlankSrcSpan (..), showAstData)
import GHC.Hs.Extension (GhcPs)
import GHC.ThToHs (convertToHsExpr)
import GHC.Types.Basic (Origin (FromSource))
import GHC.Types.SourceText (SourceText (NoSourceText))
import GHC.Types.SrcLoc (noSrcSpan, unLoc)
import GHC.Utils.Outputable (showSDocUnsafe)
import Language.Haskell.TH (mkName, varE)
import qualified Language.Haskell.TH as TH
import Language.Zine.Mathematics
import Test.Hspec
import Text.Megaparsec (ParseErrorBundle, eof, parse)

spec :: Spec
spec = do
  describe "number" $ do
    it "parses zero as an integer literal" $ do
      expected <- expectedExpression <$> [|0|]
      parseExpression number "0" `shouldBe` Right expected

    it "parses integers larger than a machine word" $ do
      expected <- expectedExpression <$> [|123456789012345678901234567890|]
      parseExpression number "123456789012345678901234567890" `shouldBe` Right expected

    it "consumes trailing whitespace" $ do
      expected <- expectedExpression <$> [|42|]
      parseExpression number "42 \t\n" `shouldBe` Right expected

    it "requires at least one digit" $
      parseExpression number "" `shouldSatisfy` isLeft

    it "leaves a following token available to its caller" $ do
      expectedNumber <- expectedExpression <$> [|42|]
      expectedSymbol <- expectedExpression <$> [|$(varE (mkName "alpha"))|]
      let numberThenSymbol = do
            value <- dumpExpression <$> number
            name <- dumpExpression <$> symbol
            pure (value, name)
      parseAll numberThenSymbol "42alpha" `shouldBe` Right (expectedNumber, expectedSymbol)

  describe "symbol" $ do
    it "represents a single letter as an overloaded string literal" $ do
      expected <- expectedExpression <$> [|"x"|]
      parseExpression symbol "x" `shouldBe` Right expected

    it "represents a single Unicode letter as an overloaded string literal" $ do
      expected <- expectedExpression <$> [|"α"|]
      parseExpression symbol "α" `shouldBe` Right expected

    it "represents a longer identifier as a variable" $ do
      expected <- expectedExpression <$> [|$(varE (mkName "alpha"))|]
      parseExpression symbol "alpha" `shouldBe` Right expected

    it "joins qualified names with apostrophes" $ do
      expected <- expectedExpression <$> [|$(varE (mkName "arrow'r'long"))|]
      parseExpression symbol "arrow.r.long" `shouldBe` Right expected

    it "treats qualified single-letter components as a variable" $ do
      expected <- expectedExpression <$> [|$(varE (mkName "a'b"))|]
      parseExpression symbol "a.b" `shouldBe` Right expected

    it "rejects an incomplete qualified name" $
      parseExpression symbol "arrow." `shouldSatisfy` isLeft

parseAll :: Parser a -> Text -> Either (ParseErrorBundle Text Void) a
parseAll parser = parse (parser <* eof) "<test>"

-- HsExpr has no Eq instance; compare its structure without source annotations.
dumpExpression :: HsExpr GhcPs -> String
dumpExpression = showSDocUnsafe . showAstData BlankSrcSpan BlankEpAnnotations

expectedExpression :: TH.Exp -> String
expectedExpression expression =
  case convertToHsExpr FromSource noSrcSpan expression of
    Left _ -> error ("convertToHsExpr failed for: " ++ TH.pprint expression)
    Right expected -> dumpExpression $ case unLoc expected of
      -- TH string literals become HsString; our parser explicitly overloads them.
      HsLit _ (HsString _ value) -> HsOverLit noExtField (mkHsIsString NoSourceText value)
      result -> result

parseExpression :: Parser (HsExpr GhcPs) -> Text -> Either (ParseErrorBundle Text Void) String
parseExpression parser = parseAll (dumpExpression <$> parser)
