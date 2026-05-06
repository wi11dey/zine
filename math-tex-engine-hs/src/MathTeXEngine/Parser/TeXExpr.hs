{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module MathTeXEngine.Parser.TeXExpr
    ( TeXExpr(..)
    , TeXExprHead(..)
    , isLeaf
    , leafMap
    , manualTeXExpr
    , toChar
    , mkTeXExpr
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Tree (Tree(..))
import qualified Data.Tree as Tree
import GHC.Generics (Generic)
import Data.Hashable (Hashable)
import qualified Data.HashMap.Strict as HM

data TeXExprHead 
    = Char
    | Symbol
    | Digit
    | Punctuation
    | Delimiter
    | Group
    | Decorated
    | Frac
    | Sqrt
    | Spaced
    | UnderOver
    | Integral
    | Font
    | TextMode
    | InlineMath
    | Expr
    deriving (Show, Eq, Generic, Hashable, Ord)

data TeXExpr
    = TeXExpr
        { texHead :: TeXExprHead
        , texArgs :: [TeXExpr]
        }
    | TeXChar !Char
    | TeXString !Text
    | TeXNothing
    deriving (Show, Eq)

mathFontMappings :: HM.HashMap Text (Char -> Maybe Char)
mathFontMappings = HM.fromList
    [ ("bb", toBlackboardBold)
    , ("cal", toCaligraphic)
    , ("frak", toFraktur)
    , ("scr", toCaligraphic)
    ]

toBlackboardBold :: Char -> Maybe Char
toBlackboardBold 'A' = Just '𝔸'
toBlackboardBold 'B' = Just '𝔹'
toBlackboardBold 'C' = Just 'ℂ'
toBlackboardBold 'D' = Just '𝔻'
toBlackboardBold 'E' = Just '𝔼'
toBlackboardBold 'F' = Just '𝔽'
toBlackboardBold 'G' = Just '𝔾'
toBlackboardBold 'H' = Just 'ℍ'
toBlackboardBold 'I' = Just '𝕀'
toBlackboardBold 'J' = Just '𝕁'
toBlackboardBold 'K' = Just '𝕂'
toBlackboardBold 'L' = Just '𝕃'
toBlackboardBold 'M' = Just '𝕄'
toBlackboardBold 'N' = Just 'ℕ'
toBlackboardBold 'O' = Just '𝕆'
toBlackboardBold 'P' = Just 'ℙ'
toBlackboardBold 'Q' = Just 'ℚ'
toBlackboardBold 'R' = Just 'ℝ'
toBlackboardBold 'S' = Just '𝕊'
toBlackboardBold 'T' = Just '𝕋'
toBlackboardBold 'U' = Just '𝕌'
toBlackboardBold 'V' = Just '𝕍'
toBlackboardBold 'W' = Just '𝕎'
toBlackboardBold 'X' = Just '𝕏'
toBlackboardBold 'Y' = Just '𝕐'
toBlackboardBold 'Z' = Just 'ℤ'
toBlackboardBold _ = Nothing

toCaligraphic :: Char -> Maybe Char
toCaligraphic 'A' = Just '𝒜'
toCaligraphic 'B' = Just 'ℬ'
toCaligraphic 'C' = Just '𝒞'
toCaligraphic 'D' = Just '𝒟'
toCaligraphic 'E' = Just 'ℰ'
toCaligraphic 'F' = Just 'ℱ'
toCaligraphic 'G' = Just '𝒢'
toCaligraphic 'H' = Just 'ℋ'
toCaligraphic 'I' = Just 'ℐ'
toCaligraphic 'J' = Just '𝒥'
toCaligraphic 'K' = Just '𝒦'
toCaligraphic 'L' = Just 'ℒ'
toCaligraphic 'M' = Just 'ℳ'
toCaligraphic 'N' = Just '𝒩'
toCaligraphic 'O' = Just '𝒪'
toCaligraphic 'P' = Just '𝒫'
toCaligraphic 'Q' = Just '𝒬'
toCaligraphic 'R' = Just 'ℛ'
toCaligraphic 'S' = Just '𝒮'
toCaligraphic 'T' = Just '𝒯'
toCaligraphic 'U' = Just '𝒰'
toCaligraphic 'V' = Just '𝒱'
toCaligraphic 'W' = Just '𝒲'
toCaligraphic 'X' = Just '𝒳'
toCaligraphic 'Y' = Just '𝒴'
toCaligraphic 'Z' = Just '𝒵'
toCaligraphic _ = Nothing

toFraktur :: Char -> Maybe Char
toFraktur 'A' = Just '𝔄'
toFraktur 'B' = Just '𝔅'
toFraktur 'C' = Just 'ℭ'
toFraktur 'D' = Just '𝔇'
toFraktur 'E' = Just '𝔈'
toFraktur 'F' = Just '𝔉'
toFraktur 'G' = Just '𝔊'
toFraktur 'H' = Just 'ℌ'
toFraktur 'I' = Just 'ℑ'
toFraktur 'J' = Just '𝔍'
toFraktur 'K' = Just '𝔎'
toFraktur 'L' = Just '𝔏'
toFraktur 'M' = Just '𝔐'
toFraktur 'N' = Just '𝔑'
toFraktur 'O' = Just '𝔒'
toFraktur 'P' = Just '𝔓'
toFraktur 'Q' = Just '𝔔'
toFraktur 'R' = Just 'ℜ'
toFraktur 'S' = Just '𝔖'
toFraktur 'T' = Just '𝔗'
toFraktur 'U' = Just '𝔘'
toFraktur 'V' = Just '𝔙'
toFraktur 'W' = Just '𝔚'
toFraktur 'X' = Just '𝔛'
toFraktur 'Y' = Just '𝔜'
toFraktur 'Z' = Just 'ℨ'
toFraktur _ = Nothing

mkTeXExpr :: TeXExprHead -> [TeXExpr] -> TeXExpr
mkTeXExpr Font [TeXString font, TeXChar c] =
    case HM.lookup font mathFontMappings of
        Just fontMapper -> case fontMapper c of
            Just c' -> TeXExpr Symbol [TeXChar c']
            Nothing -> TeXExpr Font [TeXString font, TeXChar c]
        Nothing -> TeXExpr Font [TeXString font, TeXChar c]
mkTeXExpr head args = TeXExpr head args

isLeaf :: TeXExpr -> Bool
isLeaf (TeXExpr head _) = head `elem` [Char, Delimiter, Digit, Punctuation, Symbol]
isLeaf (TeXChar _) = True
isLeaf (TeXString _) = True
isLeaf TeXNothing = True

leafMap :: (TeXExpr -> TeXExpr) -> TeXExpr -> TeXExpr
leafMap f expr@(TeXExpr head args)
    | isLeaf expr = f expr
    | otherwise = TeXExpr head (map (leafMap f) args)
leafMap f expr = f expr

toChar :: TeXExpr -> Maybe Char
toChar (TeXChar c) = Just c
toChar (TeXExpr Char [TeXChar c]) = Just c
toChar (TeXExpr Symbol [TeXChar c]) = Just c
toChar (TeXExpr Digit [TeXChar c]) = Just c
toChar _ = Nothing

manualTeXExpr :: Either (TeXExprHead, [TeXExpr]) Char -> TeXExpr
manualTeXExpr (Right c) = TeXChar c
manualTeXExpr (Left (head, args)) = mkTeXExpr head args