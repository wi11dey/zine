{-# LANGUAGE OverloadedStrings #-}

module Language.Zine.MathematicsSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text)
import Data.Void (Void)
import Language.Haskell.TH (Exp (..), Lit (..), mkName)
import Language.Zine.Mathematics
import Test.Hspec
import Text.Megaparsec (ParseErrorBundle, eof, parse)
import Text.Megaparsec.Char (string)

spec :: Spec
spec = do
  describe "sc" $ do
    it "accepts empty input" $
      parseAll sc "" `shouldBe` Right ()

    it "consumes spaces, tabs, and newlines" $
      parseAll sc " \t\n\r\n " `shouldBe` Right ()

  describe "lexeme" $ do
    it "consumes trailing whitespace and preserves the parsed value" $
      parseAll (lexeme (string "token")) "token \t\n" `shouldBe` Right "token"

    it "does not consume leading whitespace" $
      parseAll (lexeme (string "token")) " token" `shouldSatisfy` isLeft

  describe "verbatim" $ do
    it "parses a literal token with trailing whitespace" $
      parseAll (verbatim "->") "-> \n" `shouldBe` Right "->"

    it "rejects a different token" $
      parseAll (verbatim "->") "=>" `shouldSatisfy` isLeft

  describe "number" $ do
    it "parses zero as an integer literal" $
      parseAll number "0" `shouldBe` Right (LitE (IntegerL 0))

    it "parses integers larger than a machine word" $
      parseAll number "123456789012345678901234567890"
        `shouldBe` Right (LitE (IntegerL 123456789012345678901234567890))

    it "consumes trailing whitespace" $
      parseAll number "42 \t\n" `shouldBe` Right (LitE (IntegerL 42))

    it "requires at least one digit" $
      parseAll number "" `shouldSatisfy` isLeft

    it "rejects a sign" $
      parseAll number "-42" `shouldSatisfy` isLeft

    it "does not yet support decimal fractions" $
      parseAll number "3.14" `shouldSatisfy` isLeft

    it "leaves a following token available to its caller" $
      parseAll ((,) <$> number <*> symbol) "42 alpha"
        `shouldBe` Right (LitE (IntegerL 42), VarE (mkName "alpha"))

  describe "identifier'" $ do
    it "allows letters, digits, and underscores after the first letter" $
      parseAll identifier' "alpha_2" `shouldBe` Right "alpha_2"

    it "allows an initial underscore" $
      parseAll identifier' "_value2" `shouldBe` Right "_value2"

    it "accepts Unicode letters" $
      parseAll identifier' "αβ" `shouldBe` Right "αβ"

    it "consumes trailing whitespace" $
      parseAll identifier' "alpha \n" `shouldBe` Right "alpha"

    it "rejects empty input" $
      parseAll identifier' "" `shouldSatisfy` isLeft

    it "rejects an initial digit" $
      parseAll identifier' "2alpha" `shouldSatisfy` isLeft

    it "rejects punctuation inside an identifier" $
      parseAll identifier' "alpha-beta" `shouldSatisfy` isLeft

  describe "symbol'" $ do
    it "parses an unqualified identifier as a singleton path" $
      parseAll symbol' "alpha" `shouldBe` Right ["alpha"]

    it "splits a qualified symbol into path components" $
      parseAll symbol' "arrow.r.long \n" `shouldBe` Right ["arrow", "r", "long"]

    it "rejects empty path components" $
      map (parseAll symbol') ["", ".alpha", "alpha.", "alpha..beta"]
        `shouldSatisfy` all isLeft

  describe "symbol" $ do
    it "represents a single letter as a string literal" $
      parseAll symbol "x" `shouldBe` Right (LitE (StringL "x"))

    it "represents a single Unicode letter as a string literal" $
      parseAll symbol "α" `shouldBe` Right (LitE (StringL "α"))

    it "represents a longer identifier as a variable" $
      parseAll symbol "alpha" `shouldBe` Right (VarE (mkName "alpha"))

    it "joins qualified names with apostrophes" $
      parseAll symbol "arrow.r.long" `shouldBe` Right (VarE (mkName "arrow'r'long"))

    it "treats qualified single-letter components as a variable" $
      parseAll symbol "a.b" `shouldBe` Right (VarE (mkName "a'b"))

    it "rejects an incomplete qualified name" $
      parseAll symbol "arrow." `shouldSatisfy` isLeft

-- Require complete input so a successful prefix cannot hide malformed syntax.
parseAll :: Parser a -> Text -> Either (ParseErrorBundle Text Void) a
parseAll parser = parse (parser <* eof) "<test>"
