{-# LANGUAGE OverloadedStrings #-}

import MathTeXEngine
import System.Exit (exitFailure, exitSuccess)
import Data.Text (Text)

testCases :: [(Text, String)]
testCases = 
    [ ("x", "single char")
    , ("123", "digits")
    , ("x^2", "superscript")
    , ("x_i", "subscript")
    , ("\\frac{1}{2}", "fraction")
    , ("\\sqrt{x}", "square root")
    , ("\\alpha", "greek letter")
    , ("a + b", "spaced operator")
    , ("$x$", "inline math")
    , ("\\mathbb{R}", "blackboard bold")
    ]

main :: IO ()
main = do
    putStrLn "Running simple tests..."
    results <- mapM runTest testCases
    let failures = length . filter not $ results
    if failures == 0
        then do
            putStrLn $ "\nAll " ++ show (length results) ++ " tests passed!"
            exitSuccess
        else do
            putStrLn $ "\n" ++ show failures ++ " out of " ++ show (length results) ++ " tests failed!"
            exitFailure

runTest :: (Text, String) -> IO Bool
runTest (input, desc) = do
    putStr $ "Testing " ++ desc ++ " (" ++ show input ++ ")... "
    result <- try $ evaluate (texParse input)
    case result of
        Right expr -> do
            putStrLn "✓"
            return True
        Left (e :: SomeException) -> do
            putStrLn $ "✗ Error: " ++ show e
            return False
  where
    try :: IO a -> IO (Either SomeException a)
    try = Control.Exception.try
    evaluate :: a -> IO a
    evaluate = Control.Exception.evaluate

import Control.Exception (SomeException)