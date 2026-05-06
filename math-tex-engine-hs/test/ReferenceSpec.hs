{-# LANGUAGE OverloadedStrings #-}

module ReferenceSpec (spec) where

import Test.Hspec
import Prelude hiding (sin, cos, exp, log, tan, sqrt)
import MathTeXEngine
import MathTeXEngine.Parser.TeXExpr hiding (Group)
import qualified MathTeXEngine.Parser.TeXExpr as Expr
import MathTeXEngine.Engine.TeXElements hiding (Group, TeXChar)
import qualified MathTeXEngine.Engine.TeXElements as TE
import MathTeXEngine.Engine.Layout
import MathTeXEngine.Engine.LayoutContext
import Data.Text (Text)
import qualified Data.Text as T

-- Helper to create common expressions
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
    mkTeXExpr Expr.Group [delimiter left, content, delimiter right]

-- Greek letters
alpha = symbol 'α'
beta = symbol 'β'
gamma = symbol 'γ'
delta = symbol 'δ'
epsilon = symbol 'ε'
omega = symbol 'ω'
theta = symbol 'θ'
phi = symbol 'φ'
varphi = symbol 'φ'  -- Using same as phi for now
psi = symbol 'ψ'

capitalGamma = symbol 'Γ'
capitalDelta = symbol 'Δ'
capitalOmega = symbol 'Ω'
capitalTheta = symbol 'Θ'
capitalPhi = symbol 'Φ'
capitalPsi = symbol 'Ψ'

-- Operators and relations
plus = spaced $ symbol '+'
minus = spaced $ symbol '−'
cdot = spaced $ symbol '·'
eq = spaced $ symbol '='
neq = spaced $ symbol '≠'
leq = spaced $ symbol '≤'
rightarrow = spaced $ symbol '→'
nabla = symbol '∇'
hbar = symbol 'ℏ'

-- Functions
sinF = mkTeXExpr Symbol [TeXString "sin"]
cosF = mkTeXExpr Symbol [TeXString "cos"]
expF = mkTeXExpr Symbol [TeXString "exp"]
logF = mkTeXExpr Symbol [TeXString "log"]
tanF = mkTeXExpr Symbol [TeXString "tan"]

-- Spaces
thinSpace = mkTeXExpr Spaced [TeXString "0.16667"]  -- \!
medSpace = mkTeXExpr Spaced [TeXString "0.27778"]   -- \;
quad = mkTeXExpr Spaced [TeXString "1.0"]           -- \quad
qquad = mkTeXExpr Spaced [TeXString "2.0"]          -- \qquad

spec :: Spec
spec = describe "Reference tests (pre-parsed)" $ do
    
    describe "Accents" $ do
        it "renders dot accent" $ do
            let expr = mkTeXExpr Expr.Group 
                    [ mkTeXExpr Symbol [TeXChar 'Q', TeXChar '̇']  -- Q with combining dot
                    , char ' '
                    , mkTeXExpr Symbol [TeXChar 'q', TeXChar '̇']   -- q with combining dot
                    ]
            shouldNotThrowLayout expr
    
    describe "Delimiters" $ do
        it "renders simple parentheses" $ do
            let expr = mkTeXExpr Expr.Group
                    [ delimiter '('
                    , digit '1'
                    , plus
                    , digit '2'
                    , delimiter ')'
                    , char ' '
                    , delimiter '('
                    , frac (digit '1') (digit '2')
                    , delimiter ')'
                    ]
            shouldNotThrowLayout expr
            
        it "renders brackets with fractions" $ do
            let expr = mkTeXExpr Expr.Group
                    [ delimiter '['
                    , char 'a'
                    , plus
                    , char 'b'
                    , delimiter ']'
                    , char ' '
                    , delimiter '['
                    , frac (char 'a') (char 'b')
                    , delimiter ']'
                    ]
            shouldNotThrowLayout expr
    
    describe "Fonts" $ do
        it "renders mathrm" $ do
            let expr = font "mathrm" (group [char 'b', char 'o', char 'n', char 'j', char 'o', char 'u', char 'r'])
            shouldNotThrowLayout expr
            
        it "renders mathbb" $ do
            let expr = mkTeXExpr Expr.Group
                    [ font "mathbb" (char 'R')
                    , char ' '
                    , font "mathbb" (char 'Q')
                    , char ' '
                    , font "mathbb" (char 'C')
                    ]
            shouldNotThrowLayout expr
    
    describe "Fractions" $ do
        it "renders complex fraction" $ do
            let expr = frac 
                    (mkTeXExpr Expr.Group [char 'a', plus, char 'b', plus, char 'c'])
                    (mkTeXExpr Expr.Group [char 'c', plus, char 'b', plus, char 'a'])
            shouldNotThrowLayout expr
    
    describe "Functions" $ do
        it "renders trig functions" $ do
            let expr = mkTeXExpr Expr.Group
                    [ sinF, delimiter '{', omega, delimiter '}'
                    , plus
                    , cosF, delimiter '{', theta, delimiter '}'
                    ]
            shouldNotThrowLayout expr
    
    describe "Infix operators" $ do
        it "renders addition" $ do
            let expr = mkTeXExpr Expr.Group [char 'T', plus, char 'V']
            shouldNotThrowLayout expr
            
        it "renders E=mc^2" $ do
            let expr = mkTeXExpr Expr.Group
                    [ char 'E'
                    , eq
                    , char 'm'
                    , char ' '
                    , decorated (char 'c') Nothing (Just (digit '2'))
                    ]
            shouldNotThrowLayout expr
    
    describe "Integrals" $ do
        it "renders integral with limits" $ do
            let expr = integral (symbol '∫') (Just (char 'a')) (Just (char 'b'))
            shouldNotThrowLayout expr
            
        it "renders triple integral" $ do
            let expr = mkTeXExpr Expr.Group
                    [ integral (symbol '∫') Nothing Nothing
                    , char ' '
                    , integral (symbol '∫') Nothing Nothing
                    , char ' '
                    , integral (symbol '∫') Nothing Nothing
                    ]
            shouldNotThrowLayout expr
    
    describe "Subscripts and superscripts" $ do
        it "renders V^1_2" $ do
            let expr = decorated (char 'V') (Just (digit '2')) (Just (digit '1'))
            shouldNotThrowLayout expr
            
        it "renders complex subscript" $ do
            let expr = decorated (char 'x') 
                    (Just (mkTeXExpr Expr.Group [char 'y', rightarrow, digit '0']))
                    Nothing
            shouldNotThrowLayout expr
    
    describe "Symbols" $ do
        it "renders Greek letters" $ do
            let expr = mkTeXExpr Expr.Group
                    [ alpha, char ' ', beta, char ' ', gamma, char ' '
                    , delta, char ' ', epsilon, char ' ', omega, char ' '
                    , theta, char ' ', phi, char ' ', varphi, char ' ', psi
                    ]
            shouldNotThrowLayout expr
            
        it "renders capital Greek" $ do
            let expr = mkTeXExpr Expr.Group
                    [ capitalGamma, char ' ', capitalDelta, char ' '
                    , capitalOmega, char ' ', capitalTheta, char ' '
                    , capitalPhi, char ' ', capitalPsi
                    ]
            shouldNotThrowLayout expr
    
    describe "Under/over operations" $ do
        it "renders sum with limits" $ do
            let expr = underover (symbol '∑')
                    (Just (mkTeXExpr Expr.Group [char 'n', eq, digit '1']))
                    (Just (decorated (char 'm') Nothing (Just (digit '2'))))
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