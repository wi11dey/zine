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
    calculusTests

commutativeTests :: Spec
commutativeTests = describe "Commutative operations" $ do
  it "Add" $ do
    let input = "{1 + 2}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ECommutative (EAtom (AInteger "1")) " + " (EAtom (AInteger "2"))))])

  it "Sequence" $ do
    let input = "{1 + 2 + 3}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ECommutative (ECommutative (EAtom (AInteger "1")) " + " (EAtom (AInteger "2"))) " + " (EAtom (AInteger "3"))))])

  it "Ellipsis" $ do
    let input = "{1 + 2 + ...}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ECommutative (ECommutative (EAtom (AInteger "1")) " + " (EAtom (AInteger "2"))) " + " (EAtom (AIdent "..."))))])

quantumTests :: Spec
quantumTests = describe "Quantum notation" $ do
  it "Bra" $ do
    let input = "{<psi|}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EBra (EAtom (AIdent "psi"))))])

  it "Ket" $ do
    let input = "{|psi>}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EKet (EAtom (AIdent "psi"))))])

  it "Projection" $ do
    let input = "{<psi|psi>}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EProjection (EAtom (AIdent "psi")) (EAtom (AIdent "psi"))))])

intervalTests :: Spec
intervalTests = describe "Interval notation" $ do
  it "Open" $ do
    let input = "{(1..2)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '(' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ')'))])

  it "Clopen" $ do
    let input = "{[1..2)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '[' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ')'))])

  it "Clopen other way" $ do
    let input = "{(1..2]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '(' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ']'))])

  it "Closed" $ do
    let input = "{[1..1]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EInterval '[' (EAtom (AInteger "1")) (EAtom (AInteger "1")) ']'))])

negationTests :: Spec
negationTests = describe "Negation" $ do
  it "Negation" $ do
    let input = "{-x}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENegation (EAtom (AIdent "x"))))])

  it "No double negation" $ do
    let input = "{--x}"
    -- This should fail to parse correctly as double negation is not allowed
    pendingWith "tree-sitter expects ERROR node, ignoring"

  it "Double negation with parens" $ do
    let input = "{-(-x)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENegation (EParens (ENegation (EAtom (AIdent "x"))))))])

  it "Superscript" $ do
    let input = "{2^-x}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Superscript (BAtom (AInteger "2")) (BNegation (EAtom (AIdent "x")))))))])

scriptTests :: Spec
scriptTests = describe "Scripts" $ do
  it "Subscript" $ do
    let input = "{2_2}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AInteger "2"))))))])

  it "Double Subscript" $ do
    let input = "{2_2_2}"
    -- The parser is right-associative, so 2_2_2 is parsed as 2_(2_2)
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AScript (Subscript (BAtom (AInteger "2")) (BAtom (AInteger "2")))))))))])

setTests :: Spec
setTests = describe "Set notation" $ do
  it "Set" $ do
    let input = "{[x|x]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ESetBuilder (EAtom (AIdent "x")) (EAtom (AIdent "x"))))])

  it "Continuation" $ do
    let input = "{[1,2,...]}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ESet [EElem (EAtom (AInteger "1")), EElem (EAtom (AInteger "2")), EEllipsis]))])

spanTests :: Spec
spanTests = describe "Spans" $ do
  it "Span" $ do
    let input = "def{convergent}"
    runParser pTextEof input `shouldBe` Just (Text [TSpan "def" (Text [TWord "convergent"])])

  it "Embedded span" $ do
    let input = "A def{convergent sequence} is notated as {asdf}"
    runParser pTextEof input `shouldBe` Just (Text [TWord "A", TSpan "def" (Text [TWord "convergent", TWord "sequence"]), TWord "is", TWord "notated", TWord "as", TMath (MInline (EAtom (AIdent "asdf")))])

  it "Keywords on their own" $ do
    let input = "A def b"
    runParser pTextEof input `shouldBe` Just (Text [TWord "A", TWord "def", TWord "b"])

noncommutativeTests :: Spec
noncommutativeTests = describe "Noncommutative operations" $ do
  it "Multiplications" $ do
    let input = "{sin k a}"
    -- Left-associative juxtaposition: (sin k) a
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (ENoncomm (EAtom (AIdent "sin")) (EAtom (AIdent "k"))) (EAtom (AIdent "a"))))])

  it "Grouping" $ do
    let input = "{sin  k a}"
    -- Different grouping with double space - tree-sitter parses as (sin (k a))
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (EAtom (AIdent "sin")) (ENoncomm (EAtom (AIdent "k")) (EAtom (AIdent "a")))))])

  it "Nested grouping" $ do
    let input = "{sin   k  a b}"
    -- Triple and double spaces for nested grouping - tree-sitter parses as (sin (k (a b)))
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (EAtom (AIdent "sin")) (ENoncomm (EAtom (AIdent "k")) (ENoncomm (EAtom (AIdent "a")) (EAtom (AIdent "b"))))))])

  it "Unnested for comparison" $ do
    let input = "{sin k  a b}"
    -- Mixed spacing - tree-sitter parses as ((sin k) (a b))
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (ENoncomm (EAtom (AIdent "sin")) (EAtom (AIdent "k"))) (ENoncomm (EAtom (AIdent "a")) (EAtom (AIdent "b")))))])

  it "Fully unnested for comparison" $ do
    let input = "{sin k a b}"
    -- All single spaces
    runParser pText input `shouldBe` Just (Text [TMath (MInline (ENoncomm (ENoncomm (ENoncomm (EAtom (AIdent "sin")) (EAtom (AIdent "k"))) (EAtom (AIdent "a"))) (EAtom (AIdent "b"))))])

parensTests :: Spec
parensTests = describe "Parentheses" $ do
  it "One" $ do
    let input = "{(1)}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EAtom (AInteger "1"))))])

  it "Two" $ do
    let input = "{((1))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (EAtom (AInteger "1")))))])

  it "Three" $ do
    let input = "{(((1)))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (EParens (EAtom (AInteger "1"))))))])

  it "With interval" $ do
    let input = "{(((1..2)))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (EInterval '(' (EAtom (AInteger "1")) (EAtom (AInteger "2")) ')'))))])

  it "With broken interval" $ do
    let input = "{(((1..)))}"
    -- This should error in tree-sitter but may parse differently in yine
    pendingWith "tree-sitter expects ERROR node, ignoring"

  it "Multiplication" $ do
    let input = "{(((1)(1)))}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EParens (EParens (ENoncomm (EParens (EAtom (AInteger "1"))) (EParens (EAtom (AInteger "1")))))))])

polynomialTests :: Spec
polynomialTests = describe "Polynomials" $ do
  it "Quadratic" $ do
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

  it "Series" $ do
    let input = "{a_n x^n + ... + a_0}"
    runParser pText input `shouldBe` 
      Just (Text [TMath (MInline 
        (ECommutative 
          (ECommutative 
            (ENoncomm 
              (EAtom (AScript (Subscript (BAtom (AIdent "a")) (BAtom (AIdent "n"))))) 
              (EAtom (AScript (Superscript (BAtom (AIdent "x")) (BAtom (AIdent "n"))))))
            " + "
            (EAtom (AIdent "...")))
          " + "
          (EAtom (AScript (Subscript (BAtom (AIdent "a")) (BAtom (AInteger "0")))))))])

calculusTests :: Spec
calculusTests = describe "Calculus" $ do
  it "Integrals" $ do
    let input = "{int}"
    runParser pText input `shouldBe` Just (Text [TMath (MInline (EAtom (AIdent "int")))])