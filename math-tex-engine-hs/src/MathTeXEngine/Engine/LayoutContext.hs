{-# LANGUAGE RecordWildCards #-}

module MathTeXEngine.Engine.LayoutContext
    ( LayoutState(..)
    , TeXMode(..)
    , changeMode
    , addFontModifier
    , getFont
    ) where

import MathTeXEngine.Fonts.FontFamily

data TeXMode = TextMode | MathMode
    deriving (Show, Eq)

data LayoutState = LayoutState
    { layoutFontFamily :: FontFamily
    , layoutFontModifiers :: [FontModifier]
    , layoutTexMode :: TeXMode
    } deriving (Show)

changeMode :: LayoutState -> TeXMode -> LayoutState
changeMode state mode = state { layoutTexMode = mode }

addFontModifier :: LayoutState -> FontModifier -> LayoutState
addFontModifier state modifier = 
    state { layoutFontModifiers = layoutFontModifiers state ++ [modifier] }

getFont :: LayoutState -> CharType -> FontType
getFont LayoutState{..} charType =
    let actualCharType = if layoutTexMode == TextMode then TextChar else charType
    in getFontForChar layoutFontFamily actualCharType layoutFontModifiers