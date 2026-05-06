{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine
    ( -- * Main API
      texParse
    , generateTeXElements
    , renderTeX
    , renderTeXToSVG
    , renderTeXElement
    
    -- * Types
    , TeXExpr(..)
    , TeXExprHead(..)
    , TeXElement(..)
    , AnyTeXElement(..)
    , FontFamily
    , defaultFontFamily
    
    -- * Re-exports
    , module MathTeXEngine.Parser.TeXExpr
    ) where

import MathTeXEngine.Parser.TeXExpr
import MathTeXEngine.Parser.Parser (texParse)
import MathTeXEngine.Engine.TeXElements as TE
import MathTeXEngine.Engine.Layout
import MathTeXEngine.Fonts.FontFamily
import Diagrams.Prelude
import Diagrams.Backend.SVG
import Data.Text (Text)
import qualified Data.Text as T

renderTeX :: Text -> Diagram B
renderTeX tex = renderTeXElement (generateTeXElements tex)

renderTeXToSVG :: Text -> FilePath -> IO ()
renderTeXToSVG tex path = renderSVG path (mkWidth 400) (renderTeX tex)

renderTeXElement :: AnyTeXElement -> Diagram B
renderTeXElement elem = case elem of
    CharElem c -> renderChar c
    SpaceElem s -> strutX (spaceWidth s)
    VLineElem l -> renderVLine l
    HLineElem l -> renderHLine l
    GroupElem g -> renderGroup g

renderChar :: TeXChar -> Diagram B
renderChar c = 
    text [charContent c] # fontSize (local 1) # fc black

renderVLine :: VLine -> Diagram B
renderVLine l = 
    vrule (vlineHeight l) # lw (local (vlineThickness l)) # lc black

renderHLine :: HLine -> Diagram B
renderHLine l =
    hrule (hlineWidth l) # lw (local (hlineThickness l)) # lc black

renderGroup :: TE.Group -> Diagram B
renderGroup (TE.Group elems) =
    mconcat [renderTeXElement elem 
             # scale s 
             # translate (r2 (x, y))
            | (P (V2 x y), s, elem) <- elems]