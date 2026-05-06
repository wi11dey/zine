{-# LANGUAGE OverloadedStrings #-}

module FullReferenceSpec (spec) where

import Test.Hspec
import Prelude hiding (sin, cos, exp, log, tan, sqrt)
import MathTeXEngine
import MathTeXEngine.Parser.TeXExpr hiding (Group)
import qualified MathTeXEngine.Parser.TeXExpr as Expr
import MathTeXEngine.Engine.TeXElements hiding (Group, TeXChar)
import qualified MathTeXEngine.Engine.TeXElements as TE
import MathTeXEngine.Engine.Layout
import MathTeXEngine.Engine.LayoutContext
import MathTeXEngine.Fonts.FontFamily
import Data.Text (Text)
import qualified Data.Text as T

-- Helper functions
char :: Char -> TeXExpr
char c = mkTeXExpr Char [TeXChar c]

symbol :: Char -> TeXExpr  
symbol c = mkTeXExpr Symbol [TeXChar c]

digit :: Char -> TeXExpr
digit c = mkTeXExpr Digit [TeXChar c]

group :: [TeXExpr] -> TeXExpr
group = mkTeXExpr Expr.Group

spaced :: TeXExpr -> TeXExpr
spaced e = mkTeXExpr Spaced [e]

frac :: TeXExpr -> TeXExpr -> TeXExpr
frac num den = mkTeXExpr Frac [num, den]

sqrtE :: TeXExpr -> TeXExpr
sqrtE e = mkTeXExpr Sqrt [e]

decorated :: TeXExpr -> Maybe TeXExpr -> Maybe TeXExpr -> TeXExpr
decorated base sub super = 
    mkTeXExpr Decorated [base, maybe TeXNothing id sub, maybe TeXNothing id super]

underover :: TeXExpr -> Maybe TeXExpr -> Maybe TeXExpr -> TeXExpr
underover base under over =
    mkTeXExpr UnderOver [base, maybe TeXNothing id under, maybe TeXNothing id over]

integral :: TeXExpr -> Maybe TeXExpr -> Maybe TeXExpr -> TeXExpr
integral sym lower upper =
    mkTeXExpr Integral [sym, maybe TeXNothing id lower, maybe TeXNothing id upper]

font :: Text -> TeXExpr -> TeXExpr
font name e = mkTeXExpr Font [TeXString name, e]

delimiter :: Char -> TeXExpr
delimiter c = mkTeXExpr Delimiter [TeXChar c]

delimited :: Char -> TeXExpr -> Char -> TeXExpr
delimited left content right =
    group [delimiter left, content, delimiter right]

textMode :: TeXExpr -> TeXExpr
textMode e = mkTeXExpr Expr.TextMode [e]

-- Accent helper
accent :: Char -> Char -> TeXExpr
accent base accentChar = mkTeXExpr Symbol [TeXChar base, TeXChar accentChar]

-- Space helpers
negThinSpace = mkTeXExpr Spaced [TeXString "-0.16667"]  -- \!
thinSpace = mkTeXExpr Spaced [TeXString "0.16667"]      -- \,
medSpace = mkTeXExpr Spaced [TeXString "0.27778"]       -- \;
quad = mkTeXExpr Spaced [TeXString "1.0"]               -- \quad
qquad = mkTeXExpr Spaced [TeXString "2.0"]              -- \qquad

spec :: Spec
spec = describe "Full Julia reference tests (pre-parsed)" $ do
    
    describe "Accents" $ do
        it "renders \\dot{Q} \\dot{q}" $ do
            let expr = group 
                    [ accent 'Q' '̇', char ' ', accent 'q' '̇' ]
            shouldNotThrowLayout expr
            
        it "renders \\vec{A} \\vec{a}" $ do
            let expr = group
                    [ accent 'A' '⃗', char ' ', accent 'a' '⃗' ]
            shouldNotThrowLayout expr
            
        it "renders \\bar{L} \\bar{l}" $ do
            let expr = group
                    [ accent 'L' '̄', char ' ', accent 'l' '̄' ]
            shouldNotThrowLayout expr
    
    describe "Delimiters" $ do
        it "renders (1 + 2) (\\frac{1}{2})" $ do
            let expr = group
                    [ delimiter '(', digit '1', spaced (symbol '+'), digit '2', delimiter ')'
                    , char ' '
                    , delimiter '(', frac (digit '1') (digit '2'), delimiter ')'
                    ]
            shouldNotThrowLayout expr
            
        it "renders \\left[a + b\\right] \\left[\\frac{a}{b}\\right]" $ do
            let expr = group
                    [ delimiter '[', char 'a', spaced (symbol '+'), char 'b', delimiter ']'
                    , char ' '
                    , delimiter '[', frac (char 'a') (char 'b'), delimiter ']'
                    ]
            shouldNotThrowLayout expr
            
        it "renders nested delimiters" $ do
            let expr = group
                    [ delimiter '{'
                    , digit '1', spaced (symbol '+')
                    , delimiter '['
                    , digit '2', spaced (symbol '+')
                    , delimiter '('
                    , digit '3', spaced (symbol '+'), digit '4'
                    , delimiter ')'
                    , delimiter ']'
                    , delimiter '}'
                    ]
            shouldNotThrowLayout expr
    
    describe "Fonts" $ do
        it "renders \\mathrm{bonjour}" $ do
            let expr = font "mathrm" (group [char 'b', char 'o', char 'n', char 'j', char 'o', char 'u', char 'r'])
            shouldNotThrowLayout expr
            
        it "renders \\mathbb{R} \\mathbb{Q} \\mathbb{C}" $ do
            let expr = group
                    [ font "mathbb" (char 'R'), char ' '
                    , font "mathbb" (char 'Q'), char ' '
                    , font "mathbb" (char 'C')
                    ]
            shouldNotThrowLayout expr
            
        it "renders \\mathcal{N} \\mathcal{K}" $ do
            let expr = group
                    [ font "mathcal" (char 'N'), char ' '
                    , font "mathcal" (char 'K')
                    ]
            shouldNotThrowLayout expr
    
    describe "Fractions" $ do
        it "renders \\frac{a + b + c}{c + b + a}" $ do
            let expr = frac
                    (group [char 'a', spaced (symbol '+'), char 'b', spaced (symbol '+'), char 'c'])
                    (group [char 'c', spaced (symbol '+'), char 'b', spaced (symbol '+'), char 'a'])
            shouldNotThrowLayout expr
            
        it "renders \\frac{a}{A + B + C}" $ do
            let expr = frac
                    (char 'a')
                    (group [char 'A', spaced (symbol '+'), char 'B', spaced (symbol '+'), char 'C'])
            shouldNotThrowLayout expr
            
        it "renders \\frac{j - f}{f - j}" $ do
            let expr = frac
                    (group [char 'j', spaced (symbol '−'), char 'f'])
                    (group [char 'f', spaced (symbol '−'), char 'j'])
            shouldNotThrowLayout expr
    
    describe "Functions" $ do
        it "renders \\sin{\\omega} + \\cos{\\theta}" $ do
            let sinF = mkTeXExpr Symbol [TeXString "sin"]
                cosF = mkTeXExpr Symbol [TeXString "cos"]
                expr = group
                    [ sinF, delimiter '{', symbol 'ω', delimiter '}'
                    , spaced (symbol '+')
                    , cosF, delimiter '{', symbol 'θ', delimiter '}'
                    ]
            shouldNotThrowLayout expr
            
        it "renders \\exp{\\log{2}} = 2" $ do
            let expF = mkTeXExpr Symbol [TeXString "exp"]
                logF = mkTeXExpr Symbol [TeXString "log"]
                expr = group
                    [ expF, delimiter '{', logF, delimiter '{', digit '2', delimiter '}', delimiter '}'
                    , spaced (symbol '=')
                    , digit '2'
                    ]
            shouldNotThrowLayout expr
    
    describe "Infix operators" $ do
        it "renders T + V" $ do
            let expr = group [char 'T', spaced (symbol '+'), char 'V']
            shouldNotThrowLayout expr
            
        it "renders 7 - 2" $ do
            let expr = group [digit '7', spaced (symbol '−'), digit '2']
            shouldNotThrowLayout expr
            
        it "renders v \\cdot w" $ do
            let expr = group [char 'v', spaced (symbol '·'), char 'w']
            shouldNotThrowLayout expr
            
        it "renders E = m c^2" $ do
            let expr = group
                    [ char 'E', spaced (symbol '='), char 'm', char ' '
                    , decorated (char 'c') Nothing (Just (digit '2'))
                    ]
            shouldNotThrowLayout expr
    
    describe "Integrals" $ do
        it "renders \\int_a^b" $ do
            let expr = integral (symbol '∫') (Just (char 'a')) (Just (char 'b'))
            shouldNotThrowLayout expr
            
        it "renders \\int \\int \\int" $ do
            let expr = group
                    [ integral (symbol '∫') Nothing Nothing, char ' '
                    , integral (symbol '∫') Nothing Nothing, char ' '
                    , integral (symbol '∫') Nothing Nothing
                    ]
            shouldNotThrowLayout expr
    
    describe "Punctuation" $ do
        it "renders x!" $ do
            let expr = group [char 'x', char '!']
            shouldNotThrowLayout expr
            
        it "renders 23.17" $ do
            let expr = group [digit '2', digit '3', char '.', digit '1', digit '7']
            shouldNotThrowLayout expr
            
        it "renders 10,000" $ do
            let expr = group [digit '1', digit '0', char ',', digit '0', digit '0', digit '0']
            shouldNotThrowLayout expr
    
    describe "Spaces" $ do
        it "renders a \\! b" $ do
            let expr = group [char 'a', negThinSpace, char 'b']
            shouldNotThrowLayout expr
            
        it "renders a \\; b" $ do
            let expr = group [char 'a', medSpace, char 'b']
            shouldNotThrowLayout expr
            
        it "renders a \\quad b" $ do
            let expr = group [char 'a', quad, char 'b']
            shouldNotThrowLayout expr
            
        it "renders a \\qquad b" $ do
            let expr = group [char 'a', qquad, char 'b']
            shouldNotThrowLayout expr
    
    describe "Square roots" $ do
        it "renders \\sqrt{2}" $ do
            let expr = sqrtE (digit '2')
            shouldNotThrowLayout expr
            
        it "renders \\sqrt{\\frac{1}{2}}" $ do
            let expr = sqrtE (frac (digit '1') (digit '2'))
            shouldNotThrowLayout expr
            
        it "renders \\sqrt{b^2 - 4ac}" $ do
            let expr = sqrtE $ group
                    [ decorated (char 'b') Nothing (Just (digit '2'))
                    , spaced (symbol '−')
                    , digit '4', char 'a', char 'c'
                    ]
            shouldNotThrowLayout expr
            
        it "renders \\sqrt{1 + \\frac{A + B}{J + U}}" $ do
            let expr = sqrtE $ group
                    [ digit '1', spaced (symbol '+')
                    , frac
                        (group [char 'A', spaced (symbol '+'), char 'B'])
                        (group [char 'J', spaced (symbol '+'), char 'U'])
                    ]
            shouldNotThrowLayout expr
    
    describe "Subscripts and superscripts" $ do
        it "renders V^1_2" $ do
            let expr = decorated (char 'V') (Just (digit '2')) (Just (digit '1'))
            shouldNotThrowLayout expr
            
        it "renders U_{ij}" $ do
            let expr = decorated (char 'U') (Just (group [char 'i', char 'j'])) Nothing
            shouldNotThrowLayout expr
            
        it "renders W^{(i + j)}" $ do
            let expr = decorated (char 'W') Nothing
                    (Just (group [delimiter '(', char 'i', spaced (symbol '+'), char 'j', delimiter ')']))
            shouldNotThrowLayout expr
            
        it "renders x_L x_y x_{y \\rightarrow 0}" $ do
            let expr = group
                    [ decorated (char 'x') (Just (char 'L')) Nothing, char ' '
                    , decorated (char 'x') (Just (char 'y')) Nothing, char ' '
                    , decorated (char 'x') 
                        (Just (group [char 'y', spaced (symbol '→'), digit '0']))
                        Nothing
                    ]
            shouldNotThrowLayout expr
            
        it "renders N_\\nu L_\\nu A_\\nu J_\\nu" $ do
            let expr = group
                    [ decorated (char 'N') (Just (symbol 'ν')) Nothing, char ' '
                    , decorated (char 'L') (Just (symbol 'ν')) Nothing, char ' '
                    , decorated (char 'A') (Just (symbol 'ν')) Nothing, char ' '
                    , decorated (char 'J') (Just (symbol 'ν')) Nothing
                    ]
            shouldNotThrowLayout expr
            
        it "renders ^{87} Rb" $ do
            let expr = group
                    [ decorated (mkTeXExpr Expr.Group []) Nothing (Just (group [digit '8', digit '7']))
                    , char ' ', char 'R', char 'b'
                    ]
            shouldNotThrowLayout expr
    
    describe "Symbols" $ do
        it "renders Greek alphabet" $ do
            let expr = group
                    [ symbol 'α', char ' ', symbol 'β', char ' ', symbol 'γ', char ' '
                    , symbol 'δ', char ' ', symbol 'ε', char ' ', symbol 'ω', char ' '
                    , symbol 'θ', char ' ', symbol 'φ', char ' ', symbol 'φ', char ' ', symbol 'ψ'
                    ]
            shouldNotThrowLayout expr
            
        it "renders capital Greek" $ do
            let expr = group
                    [ symbol 'Γ', char ' ', symbol 'Δ', char ' ', symbol 'Ω', char ' '
                    , symbol 'Θ', char ' ', symbol 'Φ', char ' ', symbol 'Ψ'
                    ]
            shouldNotThrowLayout expr
            
        it "renders special symbols" $ do
            let expr = group
                    [ symbol '∇', char ' ', spaced (symbol '→'), char ' '
                    , spaced (symbol '≠'), char ' ', spaced (symbol '≤'), char ' '
                    , symbol 'ℏ'
                    ]
            shouldNotThrowLayout expr
    
    describe "Under/over operations" $ do
        it "renders \\sum_{n = 1}^{m^2}" $ do
            let expr = underover (symbol '∑')
                    (Just (group [char 'n', spaced (symbol '='), digit '1']))
                    (Just (decorated (char 'm') Nothing (Just (digit '2'))))
            shouldNotThrowLayout expr
            
        it "renders \\sum_{N = 1}^{M^2}" $ do
            let expr = underover (symbol '∑')
                    (Just (group [char 'N', spaced (symbol '='), digit '1']))
                    (Just (decorated (char 'M') Nothing (Just (digit '2'))))
            shouldNotThrowLayout expr
            
        it "renders \\prod_{n \\neq m}" $ do
            let expr = underover (symbol '∏')
                    (Just (group [char 'n', spaced (symbol '≠'), char 'm']))
                    Nothing
            shouldNotThrowLayout expr
            
        it "renders \\prod_{N \\neq M}" $ do
            let expr = underover (symbol '∏')
                    (Just (group [char 'N', spaced (symbol '≠'), char 'M']))
                    Nothing
            shouldNotThrowLayout expr

-- Helper function to test layout generation doesn't throw
shouldNotThrowLayout :: TeXExpr -> Expectation
shouldNotThrowLayout expr = do
    let result = layout defaultLayoutState expr
    case result of
        CharElem _ -> return ()
        SpaceElem _ -> return ()
        VLineElem _ -> return ()
        HLineElem _ -> return ()
        GroupElem _ -> return ()
  where
    defaultLayoutState = LayoutState defaultFontFamily [] MathMode