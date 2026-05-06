{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module MathTeXEngine.Parser.Token
    ( TeXToken(..)
    , tokenize
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Char (isAlpha)
import GHC.Generics (Generic)

data TeXToken
    = TChar !Char
    | TPrimes !Int
    | TCaret
    | TUnderscore
    | TRCurly
    | TLCurly
    | TCommand !Text
    | TRight !Text
    | TLeft !Text
    | TNewline
    | TDollar
    | TError
    deriving (Show, Eq, Generic)

tokenize :: Text -> [(Int, Int, TeXToken)]
tokenize = go 0
  where
    go :: Int -> Text -> [(Int, Int, TeXToken)]
    go _ t | T.null t = []
    go pos t = case T.uncons t of
        Nothing -> []
        Just (c, rest) ->
            let (token, len, remaining) = getToken c rest
            in (pos, len, token) : go (pos + len) remaining

getToken :: Char -> Text -> (TeXToken, Int, Text)
getToken '\\' rest = parseBackslash rest
getToken '^' rest = (TCaret, 1, rest)
getToken '_' rest = (TUnderscore, 1, rest)
getToken '}' rest = (TRCurly, 1, rest)
getToken '{' rest = (TLCurly, 1, rest)
getToken '$' rest = (TDollar, 1, rest)
getToken '\'' rest = 
    let primes = T.takeWhile (== '\'') rest
        numPrimes = T.length primes + 1
    in (TPrimes numPrimes, numPrimes, T.drop (numPrimes - 1) rest)
getToken c rest = (TChar c, 1, rest)

parseBackslash :: Text -> (TeXToken, Int, Text)
parseBackslash t
    | T.null t = (TChar '\\', 1, t)
    | otherwise = case T.uncons t of
        Nothing -> (TChar '\\', 1, t)
        Just (c, rest)
            | c == '\\' -> (TNewline, 2, rest)
            | c == 'n' -> (TNewline, 2, rest)
            | isAlpha c -> 
                let cmd = T.cons c (T.takeWhile isAlpha rest)
                    fullCmd = T.cons '\\' cmd
                    remaining = T.dropWhile isAlpha rest
                in case () of
                    _ | T.isPrefixOf "left" cmd -> 
                        let (delim, dlen) = parseDelimiter (T.drop 4 cmd <> remaining)
                        in (TLeft (T.take dlen (T.drop 4 cmd <> remaining)), T.length fullCmd + dlen - T.length cmd + 4, T.drop dlen (T.drop 4 cmd <> remaining))
                    _ | T.isPrefixOf "right" cmd ->
                        let (delim, dlen) = parseDelimiter (T.drop 5 cmd <> remaining)
                        in (TRight (T.take dlen (T.drop 5 cmd <> remaining)), T.length fullCmd + dlen - T.length cmd + 5, T.drop dlen (T.drop 5 cmd <> remaining))
                    _ -> (TCommand fullCmd, T.length fullCmd, remaining)
            | otherwise -> (TCommand (T.pack ['\\', c]), 2, rest)

parseDelimiter :: Text -> (Text, Int)
parseDelimiter t
    | T.null t = ("", 0)
    | T.head t == '.' = (".", 1)
    | T.head t == '\\' = 
        case T.uncons (T.tail t) of
            Nothing -> ("", 0)
            Just (c, rest) 
                | isAlpha c -> 
                    let cmd = T.cons c (T.takeWhile isAlpha rest)
                    in (T.cons '\\' cmd, T.length cmd + 1)
                | otherwise -> (T.take 2 t, 2)
    | otherwise = (T.take 1 t, 1)