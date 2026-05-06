{-# LANGUAGE OverloadedStrings #-}

module Main where

import MathTeXEngine
import System.Environment (getArgs)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
    args <- getArgs
    case args of
        [texStr, outputPath] -> do
            let tex = T.pack texStr
            putStrLn $ "Rendering: " ++ texStr
            renderTeXToSVG tex outputPath
            putStrLn $ "Output saved to: " ++ outputPath
        _ -> do
            putStrLn "Usage: math-tex-engine-exe \"LaTeX expression\" output.svg"
            putStrLn "Example: math-tex-engine-exe \"x^2 + \\frac{1}{2}\" output.svg"