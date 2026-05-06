{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine.Parser.TokenSpec (spec) where

import Test.Hspec
import MathTeXEngine.Parser.Token
import Data.Text (Text)
import qualified Data.Text as T

spec :: Spec
spec = do
    describe "Tokenizer" $ do
        describe "Basic tokens" $ do
            it "tokenizes single characters" $ do
                tokenize "a" `shouldBe` [(0, 1, TChar 'a')]
                tokenize "x" `shouldBe` [(0, 1, TChar 'x')]
                tokenize "1" `shouldBe` [(0, 1, TChar '1')]
            
            it "tokenizes special characters" $ do
                tokenize "^" `shouldBe` [(0, 1, TCaret)]
                tokenize "_" `shouldBe` [(0, 1, TUnderscore)]
                tokenize "{" `shouldBe` [(0, 1, TLCurly)]
                tokenize "}" `shouldBe` [(0, 1, TRCurly)]
                tokenize "$" `shouldBe` [(0, 1, TDollar)]
            
            it "tokenizes primes" $ do
                tokenize "'" `shouldBe` [(0, 1, TPrimes 1)]
                tokenize "''" `shouldBe` [(0, 2, TPrimes 2)]
                tokenize "'''" `shouldBe` [(0, 3, TPrimes 3)]
        
        describe "Commands" $ do
            it "tokenizes simple commands" $ do
                tokenize "\\alpha" `shouldBe` [(0, 6, TCommand "\\alpha")]
                tokenize "\\frac" `shouldBe` [(0, 5, TCommand "\\frac")]
                tokenize "\\sqrt" `shouldBe` [(0, 5, TCommand "\\sqrt")]
            
            it "tokenizes single-char commands" $ do
                tokenize "\\{" `shouldBe` [(0, 2, TCommand "\\{")]
                tokenize "\\}" `shouldBe` [(0, 2, TCommand "\\}")]
                tokenize "\\ " `shouldBe` [(0, 2, TCommand "\\ ")]
            
            it "tokenizes newline commands" $ do
                tokenize "\\\\" `shouldBe` [(0, 2, TNewline)]
                tokenize "\\n" `shouldBe` [(0, 2, TNewline)]
        
        describe "Delimiters" $ do
            it "tokenizes left delimiters" $ do
                tokenize "\\left(" `shouldBe` [(0, 6, TLeft "(")]
                tokenize "\\left[" `shouldBe` [(0, 6, TLeft "[")]
                tokenize "\\left." `shouldBe` [(0, 6, TLeft ".")]
                tokenize "\\left\\{" `shouldBe` [(0, 8, TLeft "\\{")]
            
            it "tokenizes right delimiters" $ do
                tokenize "\\right)" `shouldBe` [(0, 7, TRight ")")]
                tokenize "\\right]" `shouldBe` [(0, 7, TRight "]")]
                tokenize "\\right." `shouldBe` [(0, 7, TRight ".")]
                tokenize "\\right\\}" `shouldBe` [(0, 9, TRight "\\}")]
        
        describe "Complex expressions" $ do
            it "tokenizes multiple tokens" $ do
                tokenize "x^2" `shouldBe` 
                    [(0, 1, TChar 'x'), (1, 1, TCaret), (2, 1, TChar '2')]
                
                tokenize "\\frac{1}{2}" `shouldBe`
                    [ (0, 5, TCommand "\\frac")
                    , (5, 1, TLCurly)
                    , (6, 1, TChar '1')
                    , (7, 1, TRCurly)
                    , (8, 1, TLCurly)
                    , (9, 1, TChar '2')
                    , (10, 1, TRCurly)
                    ]
            
            it "tokenizes expressions with spaces" $ do
                tokenize "a + b" `shouldBe`
                    [ (0, 1, TChar 'a')
                    , (1, 1, TChar ' ')
                    , (2, 1, TChar '+')
                    , (3, 1, TChar ' ')
                    , (4, 1, TChar 'b')
                    ]