{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module MathTeXEngine.Fonts.FontFamily
    ( FontFamily(..)
    , FontType(..)
    , CharType(..)
    , FontModifier(..)
    , defaultFontFamily
    , getFontForChar
    , getFontPath
    , xHeight
    ) where

import qualified Data.HashMap.Strict as HM
import Data.Text (Text)
import qualified Data.Text as T
import Data.Maybe (fromMaybe)
import System.FilePath ((</>))
import GHC.Generics (Generic)
import Data.Hashable (Hashable)

data FontType = Regular | Italic | Bold | BoldItalic | Math
    deriving (Show, Eq, Ord, Enum, Generic, Hashable)

data CharType = TextChar | DelimiterChar | DigitChar | FunctionChar | PunctuationChar | SymbolChar | VarChar
    deriving (Show, Eq, Ord, Enum, Generic, Hashable)

data FontModifier = Rm | It | Bf | Sf | Tt
    deriving (Show, Eq, Ord, Enum, Generic, Hashable)

data FontFamily = FontFamily
    { fonts :: HM.HashMap FontType FilePath
    , fontMapping :: HM.HashMap CharType FontType
    , fontModifiers :: HM.HashMap FontModifier (HM.HashMap FontType FontType)
    , specialChars :: HM.HashMap Char (FilePath, Int)
    , slantAngle :: Double
    , thickness :: Double
    , xHeight :: Double
    } deriving (Show)

defaultFontMapping :: HM.HashMap CharType FontType
defaultFontMapping = HM.fromList
    [ (TextChar, Regular)
    , (DelimiterChar, Regular)
    , (DigitChar, Regular)
    , (FunctionChar, Regular)
    , (PunctuationChar, Regular)
    , (SymbolChar, Math)
    , (VarChar, Italic)
    ]

defaultFontModifiers :: HM.HashMap FontModifier (HM.HashMap FontType FontType)
defaultFontModifiers = HM.fromList
    [ (Rm, HM.fromList [(BoldItalic, Bold), (Italic, Regular)])
    , (It, HM.fromList [(Bold, BoldItalic), (Regular, Italic)])
    , (Bf, HM.fromList [(Italic, BoldItalic), (Regular, Bold)])
    ]

fontsDir :: FilePath
fontsDir = "assets" </> "fonts"

newComputerModernFonts :: HM.HashMap FontType FilePath
newComputerModernFonts = HM.fromList
    [ (Regular, fontsDir </> "NewComputerModern" </> "NewCMMath-Regular.otf")
    , (Italic, fontsDir </> "NewComputerModern" </> "NewCM10-Italic.otf")
    , (Bold, fontsDir </> "NewComputerModern" </> "NewCM10-Bold.otf")
    , (BoldItalic, fontsDir </> "NewComputerModern" </> "NewCM10-BoldItalic.otf")
    , (Math, fontsDir </> "NewComputerModern" </> "NewCMMath-Regular.otf")
    ]

defaultFontFamily :: FontFamily
defaultFontFamily = FontFamily
    { fonts = newComputerModernFonts
    , fontMapping = defaultFontMapping
    , fontModifiers = defaultFontModifiers
    , specialChars = HM.empty
    , slantAngle = 13.0
    , thickness = 0.0375
    , xHeight = 0.431  -- Typical x-height for Computer Modern
    }

getFontForChar :: FontFamily -> CharType -> [FontModifier] -> FontType
getFontForChar FontFamily{..} charType modifiers =
    let baseFont = fromMaybe Regular (HM.lookup charType fontMapping)
    in foldr applyModifier baseFont modifiers
  where
    applyModifier mod font =
        case HM.lookup mod fontModifiers of
            Nothing -> font
            Just mapping -> fromMaybe font (HM.lookup font mapping)

getFontPath :: FontFamily -> FontType -> FilePath
getFontPath FontFamily{..} fontType =
    fromMaybe "" (HM.lookup fontType fonts)