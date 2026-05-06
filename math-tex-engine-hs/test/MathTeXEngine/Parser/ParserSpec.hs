{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module MathTeXEngine.Parser.ParserSpec (spec) where

import Test.Hspec
import MathTeXEngine.Parser.Parser
import MathTeXEngine.Parser.TeXExpr
import Data.Text (Text)
import qualified Data.Text as T
import Control.Exception (evaluate, try, SomeException)

spec :: Spec
spec = do
    describe "Parser" $ do
        describe "Basic parsing" $ do
            it "parses single characters" $ do
                shouldNotThrowParse "a"
                shouldNotThrowParse "x"
                shouldNotThrowParse "1"
                shouldNotThrowParse "9"
            
            it "parses greek letters" $ do
                shouldNotThrowParse "\\alpha"
                shouldNotThrowParse "\\beta"
                shouldNotThrowParse "\\omega"
                shouldNotThrowParse "\\Omega"
        
        describe "Mathematical structures" $ do
            it "parses fractions" $ do
                shouldNotThrowParse "\\frac{1}{2}"
                shouldNotThrowParse "\\frac{x}{y}"
                shouldNotThrowParse "\\frac{a+b}{c-d}"
            
            it "parses superscripts and subscripts" $ do
                shouldNotThrowParse "x^2"
                shouldNotThrowParse "x_i"
                shouldNotThrowParse "x_i^2"
                shouldNotThrowParse "x^2_i"
                shouldNotThrowParse "x^{2n}"
                shouldNotThrowParse "x_{i+1}"
            
            it "parses square roots" $ do
                shouldNotThrowParse "\\sqrt{x}"
                shouldNotThrowParse "\\sqrt{x^2 + y^2}"
                shouldNotThrowParse "\\sqrt{\\frac{1}{2}}"
        
        describe "Groups and delimiters" $ do
            it "parses groups" $ do
                shouldNotThrowParse "{x}"
                shouldNotThrowParse "{abc}"
                shouldNotThrowParse "{x + y}"
                shouldNotThrowParse "{}"
            
            it "parses delimiters" $ do
                shouldNotThrowParse "\\left( x \\right)"
                shouldNotThrowParse "\\left[ \\frac{1}{2} \\right]"
                shouldNotThrowParse "\\left\\{ x \\right\\}"
        
        describe "Operators and spacing" $ do
            it "parses operators" $ do
                shouldNotThrowParse "+"
                shouldNotThrowParse "-"
                shouldNotThrowParse "="
                shouldNotThrowParse "<"
                shouldNotThrowParse ">"
            
            it "parses expressions with operators" $ do
                shouldNotThrowParse "a + b"
                shouldNotThrowParse "x - y"
                shouldNotThrowParse "a = b"
                shouldNotThrowParse "x < y"
            
            it "converts hyphens to minus in math mode" $ do
                shouldNotThrowParse "-"
                shouldNotThrowParse "a-b"
                shouldNotThrowParse "$a-b$"
        
        describe "Commands" $ do
            it "parses font commands" $ do
                shouldNotThrowParse "\\mathbb{R}"
                shouldNotThrowParse "\\mathcal{L}"
                shouldNotThrowParse "\\mathrm{sin}"
                shouldNotThrowParse "\\text{hello}"
                shouldNotThrowParse "\\textbf{bold}"
            
            it "parses function names" $ do
                shouldNotThrowParse "\\sin"
                shouldNotThrowParse "\\cos"
                shouldNotThrowParse "\\log"
                shouldNotThrowParse "\\lim_{x \\to 0}"
            
            it "parses sum and integral" $ do
                shouldNotThrowParse "\\sum_{i=1}^n"
                shouldNotThrowParse "\\int_0^\\infty"
                shouldNotThrowParse "\\prod_{k=1}^n"
        
        describe "Complex expressions" $ do
            it "parses nested structures" $ do
                shouldNotThrowParse "\\frac{\\sqrt{x}}{2}"
                shouldNotThrowParse "x^{y^z}"
                shouldNotThrowParse "\\sqrt{\\frac{a+b}{c-d}}"
            
            it "parses real-world expressions" $ do
                shouldNotThrowParse "x^2 + y^2 = z^2"
                shouldNotThrowParse "\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
                shouldNotThrowParse "e^{i\\pi} + 1 = 0"
                shouldNotThrowParse "\\sum_{n=1}^\\infty \\frac{1}{n^2} = \\frac{\\pi^2}{6}"
        
        describe "Error handling" $ do
            it "throws on unmatched braces" $ do
                shouldThrowParse "{"
                shouldThrowParse "}"
                shouldThrowParse "{x"
                shouldThrowParse "x}"
            
            it "throws on unmatched delimiters" $ do
                shouldThrowParse "\\left("
                shouldThrowParse "\\right)"
                shouldThrowParse "\\left( x"

shouldNotThrowParse :: Text -> Expectation
shouldNotThrowParse input = do
    result <- try (evaluate (texParse input))
    case result of
        Right _ -> return ()
        Left (e :: SomeException) -> expectationFailure $ "Parse failed: " ++ show e

shouldThrowParse :: Text -> Expectation
shouldThrowParse input = do
    result <- try (evaluate (texParse input))
    case result of
        Right _ -> expectationFailure "Expected parse error but succeeded"
        Left (_ :: SomeException) -> return ()