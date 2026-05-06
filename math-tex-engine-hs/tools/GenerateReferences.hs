{-# LANGUAGE OverloadedStrings #-}

module Main where

import Prelude hiding (sin, cos, exp, log, tan, sqrt)
import MathTeXEngine
import MathTeXEngine.Parser.TeXExpr hiding (Group)
import qualified MathTeXEngine.Parser.TeXExpr as Expr
import MathTeXEngine.Engine.Layout
import MathTeXEngine.Engine.LayoutContext
import MathTeXEngine.Engine.TeXElements hiding (Group, TeXChar)
import MathTeXEngine.Fonts.FontFamily
import Diagrams.Prelude hiding (font)
import Diagrams.Backend.SVG
import System.Directory
import qualified Data.Text as T

-- Helper functions for creating expressions
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

font :: T.Text -> TeXExpr -> TeXExpr
font name e = mkTeXExpr Font [TeXString name, e]

-- Test cases matching Julia reference tests
testCases :: [(String, TeXExpr)]
testCases = 
    [ ("simple_fraction", frac (digit '1') (digit '2'))
    , ("complex_fraction", frac 
        (group [char 'a', spaced (symbol '+'), char 'b'])
        (group [char 'c', spaced (symbol '+'), char 'd']))
    , ("greek_letters", group
        [ symbol 'α', char ' ', symbol 'β', char ' ', symbol 'γ', char ' '
        , symbol 'δ', char ' ', symbol 'ω'
        ])
    , ("superscript", decorated (char 'x') Nothing (Just (digit '2')))
    , ("subscript", decorated (char 'x') (Just (char 'i')) Nothing)
    , ("both_scripts", decorated (char 'V') (Just (digit '2')) (Just (digit '1')))
    , ("sum_limits", underover (symbol '∑')
        (Just (group [char 'n', spaced (symbol '='), digit '1']))
        (Just (char 'm')))
    , ("integral", integral (symbol '∫') (Just (char 'a')) (Just (char 'b')))
    , ("sqrt_simple", sqrtE (char 'x'))
    , ("sqrt_fraction", sqrtE (frac (digit '1') (digit '2')))
    , ("mathbb_R", font "mathbb" (char 'R'))
    , ("equation", group 
        [ char 'E', spaced (symbol '='), char 'm', decorated (char 'c') Nothing (Just (digit '2'))
        ])
    ]

-- Render a TeXExpr to a Diagram
renderExpr :: TeXExpr -> Diagram B
renderExpr expr =
    let layoutState = LayoutState defaultFontFamily [] MathMode
        element = layout layoutState expr
    in renderTeXElement element

main :: IO ()
main = do
    createDirectoryIfMissing True "reference_output"
    
    putStrLn "Generating reference SVG files..."
    
    mapM_ generateSVG testCases
    
    putStrLn $ "Generated " ++ show (length testCases) ++ " reference files in reference_output/"
  where
    generateSVG (name, expr) = do
        let diagram = renderExpr expr # centerXY # pad 1.1
            filename = "reference_output/" ++ name ++ ".svg"
        renderSVG filename (mkWidth 400) diagram
        putStrLn $ "  - " ++ filename