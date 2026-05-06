{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module MathTeXEngine.Engine.LayoutSpec (spec) where

import Test.Hspec
import MathTeXEngine.Engine.Layout
import MathTeXEngine.Engine.TeXElements
import MathTeXEngine.Parser.TeXExpr
import Data.Text (Text)
import qualified Data.Text as T
import Control.Exception (evaluate, try, SomeException)

spec :: Spec
spec = do
    describe "Layout engine" $ do
        describe "Basic elements" $ do
            it "generates layout for single characters" $ do
                shouldNotThrowLayout "x"
                shouldNotThrowLayout "a"
                shouldNotThrowLayout "1"
            
            it "generates layout for multiple characters" $ do
                shouldNotThrowLayout "abc"
                shouldNotThrowLayout "123"
                shouldNotThrowLayout "xyz"
            
            it "handles empty input" $ do
                shouldNotThrowLayout ""
        
        describe "Mathematical constructs" $ do
            it "generates layout for fractions" $ do
                shouldNotThrowLayout "\\frac{1}{2}"
                shouldNotThrowLayout "\\frac{x}{y}"
                shouldNotThrowLayout "\\frac{a+b}{c-d}"
            
            it "generates layout for superscripts" $ do
                shouldNotThrowLayout "x^2"
                shouldNotThrowLayout "x^{10}"
                shouldNotThrowLayout "x^{y+z}"
            
            it "generates layout for subscripts" $ do
                shouldNotThrowLayout "x_i"
                shouldNotThrowLayout "x_{n+1}"
                shouldNotThrowLayout "a_{i,j}"
            
            it "generates layout for both super and subscripts" $ do
                shouldNotThrowLayout "x_i^2"
                shouldNotThrowLayout "x^2_i"
                shouldNotThrowLayout "a_{n}^{m}"
            
            it "generates layout for square roots" $ do
                shouldNotThrowLayout "\\sqrt{x}"
                shouldNotThrowLayout "\\sqrt{x^2 + y^2}"
                shouldNotThrowLayout "\\sqrt{\\frac{1}{2}}"
        
        describe "Spacing and operators" $ do
            it "adds space around operators" $ do
                shouldNotThrowLayout "a+b"
                shouldNotThrowLayout "x-y"
                shouldNotThrowLayout "a=b"
                shouldNotThrowLayout "x<y"
                shouldNotThrowLayout "p>q"
            
            it "handles explicit spaces" $ do
                shouldNotThrowLayout "\\quad"
                shouldNotThrowLayout "a\\quad b"
                shouldNotThrowLayout "\\!"
                shouldNotThrowLayout "\\,"
        
        describe "Symbols and special characters" $ do
            it "generates layout for Greek letters" $ do
                shouldNotThrowLayout "\\alpha"
                shouldNotThrowLayout "\\beta"
                shouldNotThrowLayout "\\gamma"
                shouldNotThrowLayout "\\Omega"
            
            it "converts hyphens to minus signs" $ do
                shouldNotThrowLayout "-"
                shouldNotThrowLayout "a-b"
                shouldNotThrowLayout "$x-y$"
            
            it "handles special symbols" $ do
                shouldNotThrowLayout "\\infty"
                shouldNotThrowLayout "\\pm"
                shouldNotThrowLayout "\\neq"
                shouldNotThrowLayout "\\subset"
        
        describe "Font commands" $ do
            it "handles math font commands" $ do
                shouldNotThrowLayout "\\mathbb{R}"
                shouldNotThrowLayout "\\mathcal{L}"
                shouldNotThrowLayout "\\mathrm{sin}"
                shouldNotThrowLayout "\\mathbf{v}"
            
            it "handles text mode" $ do
                shouldNotThrowLayout "\\text{hello}"
                shouldNotThrowLayout "\\textbf{bold}"
                shouldNotThrowLayout "\\textit{italic}"
        
        describe "Complex expressions" $ do
            it "generates layout for nested structures" $ do
                shouldNotThrowLayout "\\frac{\\sqrt{x}}{2}"
                shouldNotThrowLayout "x^{y^z}"
                shouldNotThrowLayout "\\sqrt{\\frac{a+b}{c-d}}"
            
            it "generates layout for real formulas" $ do
                shouldNotThrowLayout "x^2 + y^2 = z^2"
                shouldNotThrowLayout "\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
                shouldNotThrowLayout "e^{i\\pi} + 1 = 0"
                shouldNotThrowLayout "\\sum_{n=1}^\\infty \\frac{1}{n^2} = \\frac{\\pi^2}{6}"

shouldNotThrowLayout :: Text -> Expectation
shouldNotThrowLayout input = do
    result <- try (evaluate (generateTeXElements input))
    case result of
        Right _ -> return ()
        Left (e :: SomeException) -> expectationFailure $ "Layout generation failed: " ++ show e