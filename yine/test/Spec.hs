{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Test.Hspec
import Parser.Incremental
import Yi.Lexer.Zine

-- Helper to run parser and extract result
runParser :: Parser Char a -> String -> Maybe a
runParser p input = 
  case run (mkProcess p) input of
    (result, _) -> Just result
    
-- Helper to partially parse (for debugging)
parsePartial :: Parser Char a -> String -> Maybe (a, String)
parsePartial p input = Nothing  -- TODO: implement if needed

-- Test helpers to match expected structures
testParse :: (Eq a, Show a) => String -> Parser Char a -> a -> Spec
testParse name parser expected = 
  it name $ runParser parser name `shouldBe` Just expected

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "Yi.Lexer.Zine Parser Tests" $ do
    commutativeTests
    quantumTests
    intervalTests
    negationTests
    scriptTests
    setTests
    spanTests
    noncommutativeTests
    parensTests
    polynomialTests

commutativeTests :: Spec
commutativeTests = describe "Commutative operations" $ do
  it "parses simple addition" $ do
    let input = "{1 + 2}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ECommutative (EAtom (AInteger "1")) " + " (EAtom (AInteger "2"))))])

  it "parses chained addition" $ do
    let input = "{1 + 2 + 3}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ECommutative (ECommutative (EAtom (AInteger "1")) " + " (EAtom (AInteger "2"))) " + " (EAtom (AInteger "3"))))])

quantumTests :: Spec
quantumTests = describe "Quantum notation" $ do
  it "parses bra notation" $ do
    let input = "{<psi|}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EBra (EAtom (AIdent "psi"))))])

  it "parses ket notation" $ do
    let input = "{|psi>}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EKet (EAtom (AIdent "psi"))))])

  it "parses projection notation" $ do
    let input = "{<psi|psi>}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EProjection (EAtom (AIdent "psi")) (EAtom (AIdent "psi"))))])

intervalTests :: Spec
intervalTests = describe "Interval notation" $ do
  it "parses open interval" $ do
    let input = "{(1..2)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '(' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ')'))])

  it "parses half-open interval [)" $ do
    let input = "{[1..2)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '[' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ')'))])

  it "parses half-open interval (]" $ do
    let input = "{(1..2]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '(' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ']'))])

  it "parses closed interval" $ do
    let input = "{[1..1]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '[' (EAtom (AInteger "1")) (EAtom (AInteger "1")) ']'))])

negationTests :: Spec
negationTests = describe "Negation" $ do
  it "parses simple negation" $ do
    let input = "{-x}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENegation (EAtom (AIdent "x"))))])

  it "parses parenthesized double negation" $ do
    let input = "{-(-x)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENegation (EParens (ENegation (EAtom (AIdent "x"))))))])

  it "parses negation in superscript" $ do
    let input = "{2^-x}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Superscript (BAtom (AInteger "2")) (BNegation (EAtom (AIdent "x")))))))])

scriptTests :: Spec
scriptTests = describe "Scripts" $ do
  it "parses simple subscript" $ do
    let input = "{2_2}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AInteger "2"))))))])

  it "parses nested subscripts" $ do
    let input = "{2_2_2}"
    -- The parser is right-associative, so 2_2_2 is parsed as 2_(2_2)
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AInteger "2")))))))))])

setTests :: Spec
setTests = describe "Set notation" $ do
  it "parses set builder notation" $ do
    let input = "{[x|x]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ESetBuilder (EAtom (AIdent "x")) (EAtom (AIdent "x"))))])

  it "parses set with ellipsis" $ do
    let input = "{[1,2,...]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ESet [EElem (EAtom (AInteger "1")), EElem (EAtom (AInteger "2")), EEllipsis]))])

spanTests :: Spec
spanTests = describe "Spans" $ do
  it "parses definition span" $ do
    let input = "def{convergent}"
    runParser pText input `shouldBe` Just (Text [TSpan "def" (Text [TWord "convergent"])])

  it "parses mixed text with spans" $ do
    let input = "A subsequence def{convergent}"
    runParser pText input `shouldBe` Just (Text [TWord "A", TWord "subsequence", TWord "def{convergent}"])

noncommutativeTests :: Spec
noncommutativeTests = describe "Noncommutative operations" $ do
  it "parses simple juxtaposition" $ do
    let input = "{sin k a}"
    -- Left-associative juxtaposition: (sin k) a
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (ENoncomm (EAtom (AIdent "sin")) (EAtom (AIdent "k"))) (EAtom (AIdent "a"))))])

parensTests :: Spec
parensTests = describe "Parentheses" $ do
  it "parses single parentheses" $ do
    let input = "{(1)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EAtom (AInteger "1"))))])

  it "parses double parentheses" $ do
    let input = "{((1))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (EAtom (AInteger "1")))))])

  it "parses triple parentheses" $ do
    let input = "{(((1)))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (EParens (EAtom (AInteger "1"))))))])

polynomialTests :: Spec
polynomialTests = describe "Polynomials" $ do
  it "parses quadratic formula" $ do
    let input = "{a x^2 + b x + c}"
    runParser pText input `shouldBe` 
      Just (Text [TMath (MInline 
        (ECommutative 
          (ECommutative 
            (ENoncomm (EAtom (AIdent "a")) (EAtom (AScript (Superscript (BAtom (AIdent "x")) (BAtom (AInteger "2"))))))
            " + "
            (ENoncomm (EAtom (AIdent "b")) (EAtom (AIdent "x"))))
          " + "
          (EAtom (AIdent "c"))))])