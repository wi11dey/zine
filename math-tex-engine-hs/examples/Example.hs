{-# LANGUAGE OverloadedStrings #-}

module Main where

import MathTeXEngine
import System.Directory (createDirectoryIfMissing)

examples :: [(String, Text)]
examples =
    [ ("simple", "x^2 + y^2 = z^2")
    , ("fraction", "\\frac{a+b}{c-d}")
    , ("sqrt", "\\sqrt{1 + \\frac{1}{x^2}}")
    , ("greek", "\\alpha\\beta\\gamma = \\omega")
    , ("integral", "\\int_0^\\infty e^{-x} dx = 1")
    , ("sum", "\\sum_{i=1}^n i = \\frac{n(n+1)}{2}")
    , ("matrix", "\\mathbb{R}^{m \\times n}")
    , ("complex", "e^{i\\pi} + 1 = 0")
    ]

main :: IO ()
main = do
    createDirectoryIfMissing False "examples/output"
    
    putStrLn "Generating example SVG files..."
    
    mapM_ renderExample examples
    
    putStrLn "\nDone! Check examples/output/ for generated SVG files."
  where
    renderExample (name, tex) = do
        let path = "examples/output/" ++ name ++ ".svg"
        putStrLn $ "Rendering " ++ name ++ ": " ++ show tex
        renderTeXToSVG tex path