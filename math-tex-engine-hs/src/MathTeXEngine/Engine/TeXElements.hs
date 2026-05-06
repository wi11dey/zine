{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine.Engine.TeXElements
    ( TeXElement(..)
    , TeXChar(..)
    , Space(..)
    , VLine(..)
    , HLine(..)
    , Group(..)
    , AnyTeXElement(..)
    , leftInkBound
    , rightInkBound
    , bottomInkBound
    , topInkBound
    , inkWidth
    , inkHeight
    , hMid
    , vMid
    , hAdvance
    , ascender
    , descender
    , isSlanted
    ) where

import Diagrams.Prelude hiding (Group)
import Diagrams.Backend.SVG (SVG)
import Data.Text (Text)
import qualified Data.Text as T
import MathTeXEngine.Fonts.FontFamily
import MathTeXEngine.Engine.LayoutContext

class TeXElement a where
    leftInkBound :: a -> Double
    rightInkBound :: a -> Double
    bottomInkBound :: a -> Double
    topInkBound :: a -> Double
    hAdvance :: a -> Double
    ascender :: a -> Double
    descender :: a -> Double
    isSlanted :: a -> Bool
    
    -- Derived functions
    inkWidth :: a -> Double
    inkWidth x = rightInkBound x - leftInkBound x
    
    inkHeight :: a -> Double
    inkHeight x = topInkBound x - bottomInkBound x
    
    hMid :: a -> Double
    hMid x = 0.5 * (leftInkBound x + rightInkBound x)
    
    vMid :: a -> Double
    vMid x = 0.5 * (bottomInkBound x + topInkBound x)
    
    -- Default implementations
    hAdvance = inkWidth
    ascender _ = 0
    descender _ = 0
    isSlanted _ = False

data TeXChar = TeXChar
    { charContent :: !Char
    , charFont :: !FontType
    , charFontFamily :: !FontFamily
    , charSlanted :: !Bool
    , charRepresented :: !Char
    } deriving (Show)

instance TeXElement TeXChar where
    leftInkBound _ = 0  -- Simplified for diagrams
    rightInkBound c = 0.5  -- Simplified width
    bottomInkBound _ = -0.2  -- Typical descender
    topInkBound _ = 0.7  -- Typical ascender
    hAdvance = rightInkBound
    ascender _ = 0.7
    descender _ = -0.2
    isSlanted = charSlanted

newtype Space = Space { spaceWidth :: Double }
    deriving (Show)

instance TeXElement Space where
    leftInkBound _ = 0
    rightInkBound = spaceWidth
    bottomInkBound _ = 0
    topInkBound _ = 0

data VLine = VLine
    { vlineHeight :: !Double
    , vlineThickness :: !Double
    } deriving (Show)

instance TeXElement VLine where
    leftInkBound l = -vlineThickness l / 2
    rightInkBound l = vlineThickness l / 2
    bottomInkBound _ = 0
    topInkBound = vlineHeight

data HLine = HLine
    { hlineWidth :: !Double
    , hlineThickness :: !Double
    } deriving (Show)

instance TeXElement HLine where
    leftInkBound _ = 0
    rightInkBound = hlineWidth
    bottomInkBound l = -hlineThickness l / 2
    topInkBound l = hlineThickness l / 2

data Group = Group
    { groupElements :: [(P2 Double, Double, AnyTeXElement)]
    } deriving (Show)

data AnyTeXElement
    = CharElem TeXChar
    | SpaceElem Space
    | VLineElem VLine
    | HLineElem HLine
    | GroupElem Group
    deriving (Show)

instance TeXElement AnyTeXElement where
    leftInkBound (CharElem x) = leftInkBound x
    leftInkBound (SpaceElem x) = leftInkBound x
    leftInkBound (VLineElem x) = leftInkBound x
    leftInkBound (HLineElem x) = leftInkBound x
    leftInkBound (GroupElem x) = leftInkBound x
    
    rightInkBound (CharElem x) = rightInkBound x
    rightInkBound (SpaceElem x) = rightInkBound x
    rightInkBound (VLineElem x) = rightInkBound x
    rightInkBound (HLineElem x) = rightInkBound x
    rightInkBound (GroupElem x) = rightInkBound x
    
    bottomInkBound (CharElem x) = bottomInkBound x
    bottomInkBound (SpaceElem x) = bottomInkBound x
    bottomInkBound (VLineElem x) = bottomInkBound x
    bottomInkBound (HLineElem x) = bottomInkBound x
    bottomInkBound (GroupElem x) = bottomInkBound x
    
    topInkBound (CharElem x) = topInkBound x
    topInkBound (SpaceElem x) = topInkBound x
    topInkBound (VLineElem x) = topInkBound x
    topInkBound (HLineElem x) = topInkBound x
    topInkBound (GroupElem x) = topInkBound x
    
    hAdvance (CharElem x) = hAdvance x
    hAdvance (SpaceElem x) = hAdvance x
    hAdvance (VLineElem x) = hAdvance x
    hAdvance (HLineElem x) = hAdvance x
    hAdvance (GroupElem x) = hAdvance x
    
    isSlanted (CharElem x) = isSlanted x
    isSlanted _ = False

instance TeXElement Group where
    leftInkBound (Group []) = 0
    leftInkBound (Group elems) = 
        minimum [px + scale * leftInkBound elem | (P (V2 px _), scale, elem) <- elems]
    
    rightInkBound (Group []) = 0
    rightInkBound (Group elems) =
        maximum [px + scale * rightInkBound elem | (P (V2 px _), scale, elem) <- elems]
    
    bottomInkBound (Group []) = 0
    bottomInkBound (Group elems) =
        minimum [py + scale * bottomInkBound elem | (P (V2 _ py), scale, elem) <- elems]
    
    topInkBound (Group []) = 0
    topInkBound (Group elems) =
        maximum [py + scale * topInkBound elem | (P (V2 _ py), scale, elem) <- elems]
    
    hAdvance g = rightInkBound g - leftInkBound g