{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Language.Zine.MathematicsSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text)
import Data.Void (Void)
import Language.Haskell.TH (mkName, varE)
import Language.Zine.Mathematics
import Test.Hspec
import Text.Megaparsec (ParseErrorBundle, eof, parse)

spec :: Spec
spec = do
  describe "number" $ do
    it "parses zero as an integer literal" $ do
      expected <- [|0|]
      parseAll number "0" `shouldBe` Right expected

    it "parses integers larger than a machine word" $ do
      expected <- [|123456789012345678901234567890|]
      parseAll number "123456789012345678901234567890" `shouldBe` Right expected

    it "consumes trailing whitespace" $ do
      expected <- [|42|]
      parseAll number "42 \t\n" `shouldBe` Right expected

    it "requires at least one digit" $
      parseAll number "" `shouldSatisfy` isLeft

    it "leaves a following token available to its caller" $ do
      expectedNumber <- [|42|]
      expectedSymbol <- [|$(varE (mkName "alpha"))|]
      let numberThenSymbol = do
            value <- number
            name <- symbol
            pure (value, name)
      parseAll numberThenSymbol "42alpha" `shouldBe` Right (expectedNumber, expectedSymbol)

  describe "symbol" $ do
    it "represents a single letter as a string literal" $ do
      expected <- [|"x"|]
      parseAll symbol "x" `shouldBe` Right expected

    it "represents a single Unicode letter as a string literal" $ do
      expected <- [|"α"|]
      parseAll symbol "α" `shouldBe` Right expected

    it "represents a longer identifier as a variable" $ do
      expected <- [|$(varE (mkName "alpha"))|]
      parseAll symbol "alpha" `shouldBe` Right expected

    it "joins qualified names with apostrophes" $ do
      expected <- [|$(varE (mkName "arrow'r'long"))|]
      parseAll symbol "arrow.r.long" `shouldBe` Right expected

    it "treats qualified single-letter components as a variable" $ do
      expected <- [|$(varE (mkName "a'b"))|]
      parseAll symbol "a.b" `shouldBe` Right expected

    it "rejects an incomplete qualified name" $
      parseAll symbol "arrow." `shouldSatisfy` isLeft

parseAll :: Parser a -> Text -> Either (ParseErrorBundle Text Void) a
parseAll parser = parse (parser <* eof) "<test>"
