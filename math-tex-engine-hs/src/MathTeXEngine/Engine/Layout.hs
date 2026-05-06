{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module MathTeXEngine.Engine.Layout
    ( generateTeXElements
    , layout
    ) where

import MathTeXEngine.Parser.TeXExpr as Expr
import MathTeXEngine.Parser.Parser (texParse)
import MathTeXEngine.Engine.TeXElements
import MathTeXEngine.Engine.LayoutContext as LayoutContext
import MathTeXEngine.Fonts.FontFamily
import Diagrams.Prelude
import qualified MathTeXEngine.Engine.TeXElements as TE
import Data.Text (Text)
import qualified Data.Text as T
import Data.Maybe (fromMaybe)

generateTeXElements :: Text -> AnyTeXElement
generateTeXElements tex =
    let expr = texParse tex
        state = LayoutState defaultFontFamily [] MathMode
    in layout state expr

layout :: LayoutState -> Expr.TeXExpr -> AnyTeXElement
layout state expr = case expr of
    Expr.TeXChar c -> layoutChar state c VarChar
    Expr.TeXString s -> layoutString state s
    Expr.TeXNothing -> SpaceElem (Space 0)
    Expr.TeXExpr head args -> layoutExpr state head args

layoutChar :: LayoutState -> Char -> CharType -> AnyTeXElement
layoutChar state@LayoutState{..} c charType =
    let fontType = getFont state charType
        slanted = charType == VarChar || fontType == Italic
    in CharElem $ TE.TeXChar c fontType layoutFontFamily slanted c

layoutString :: LayoutState -> Text -> AnyTeXElement
layoutString state s = 
    let chars = T.unpack s
        elems = map (\c -> layoutChar state c TextChar) chars
        positioned = positionHorizontally 0 elems
    in GroupElem $ TE.Group positioned

layoutExpr :: LayoutState -> Expr.TeXExprHead -> [Expr.TeXExpr] -> AnyTeXElement
layoutExpr state head args = case head of
    Char -> case args of
        [Expr.TeXChar c] -> layoutChar state c VarChar
        _ -> SpaceElem (TE.Space 0)
    
    Symbol -> case args of
        [Expr.TeXChar c] -> layoutChar state c SymbolChar
        [TeXString s] -> layoutString state s
        _ -> SpaceElem (TE.Space 0)
    
    Digit -> case args of
        [Expr.TeXChar c] -> layoutChar state c DigitChar
        _ -> SpaceElem (TE.Space 0)
    
    Punctuation -> case args of
        [Expr.TeXChar c] -> layoutChar state c PunctuationChar
        _ -> SpaceElem (TE.Space 0)
    
    Delimiter -> case args of
        [Expr.TeXChar c] -> layoutChar state c DelimiterChar
        _ -> SpaceElem (TE.Space 0)
    
    Spaced -> case args of
        [inner] -> 
            let elem = layout state inner
                space = 0.2  -- em
            in GroupElem $ TE.Group 
                [ (p2 (-space, 0), 1, SpaceElem (TE.Space space))
                , (p2 (0, 0), 1, elem)
                , (p2 (hAdvance elem, 0), 1, SpaceElem (TE.Space space))
                ]
        _ -> SpaceElem (TE.Space 0)
    
    Expr.Group -> layoutGroup state args
    
    Expr.Decorated -> layoutDecorated state args
    
    Expr.Frac -> layoutFrac state args
    
    Expr.Sqrt -> layoutSqrt state args
    
    Expr.UnderOver -> layoutUnderOver state args
    
    Expr.Integral -> layoutIntegral state args
    
    Expr.Font -> layoutFont state args
    
    Expr.TextMode -> layoutTextMode state args
    
    Expr.InlineMath -> layoutInlineMath state args
    
    Expr.Expr -> layoutGroup state args

layoutGroup :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutGroup state exprs =
    let elems = map (layout state) exprs
        positioned = positionHorizontally 0 elems
    in case positioned of
        [] -> SpaceElem (TE.Space 0)
        [(_, _, elem)] -> elem
        _ -> GroupElem $ TE.Group positioned

positionHorizontally :: Double -> [AnyTeXElement] -> [(P2 Double, Double, AnyTeXElement)]
positionHorizontally _ [] = []
positionHorizontally x (elem:rest) =
    let advance = hAdvance elem
    in (p2 (x, 0), 1, elem) : positionHorizontally (x + advance) rest

layoutDecorated :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutDecorated state args = case args of
    [base, sub, sup] ->
        let baseElem = layout state base
            subElem = maybe Nothing (\e -> if e == Expr.TeXNothing then Nothing else Just (layout state e)) (Just sub)
            supElem = maybe Nothing (\e -> if e == Expr.TeXNothing then Nothing else Just (layout state e)) (Just sup)
            baseWidth = hAdvance baseElem
            scriptScale = 0.7
            xHeight' = xHeight (layoutFontFamily state)
            
            elems = [(p2 (0, 0), 1, baseElem)]
            
            elemsWithSub = case subElem of
                Nothing -> elems
                Just se -> elems ++ [(p2 (baseWidth, -xHeight' * 0.5), scriptScale, se)]
            
            elemsWithSuper = case supElem of
                Nothing -> elemsWithSub
                Just se -> elemsWithSub ++ [(p2 (baseWidth, xHeight' * 0.7), scriptScale, se)]
                
        in GroupElem $ TE.Group elemsWithSuper
    _ -> SpaceElem (TE.Space 0)

layoutFrac :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutFrac state args = case args of
    [num, den] ->
        let numElem = layout state num
            denElem = layout state den
            thickness = 0.04
            gap = 0.2
            numWidth = inkWidth numElem
            denWidth = inkWidth denElem
            maxWidth = max numWidth denWidth
            lineWidth = maxWidth + 0.2
            
            numX = (lineWidth - numWidth) / 2
            denX = (lineWidth - denWidth) / 2
            
            elems = 
                [ (p2 (numX, gap + thickness/2), 1, numElem)
                , (p2 (0, -thickness/2), 1, HLineElem (TE.HLine lineWidth thickness))
                , (p2 (denX, -gap - thickness/2 - inkHeight denElem), 1, denElem)
                ]
        in GroupElem $ TE.Group elems
    _ -> SpaceElem (TE.Space 0)

layoutSqrt :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutSqrt state args = case args of
    [content] ->
        let contentElem = layout state content
            thickness = 0.04
            padding = 0.1
            contentHeight = inkHeight contentElem
            radicalHeight = contentHeight + 2 * padding
            radicalWidth = 0.5
            
            elems = 
                [ (p2 (0, -radicalHeight/2), 1, VLineElem (TE.VLine radicalHeight thickness))
                , (p2 (radicalWidth, padding), 1, contentElem)
                , (p2 (radicalWidth, contentHeight + padding - thickness/2), 1, 
                   HLineElem (TE.HLine (inkWidth contentElem) thickness))
                ]
        in GroupElem $ TE.Group elems
    _ -> SpaceElem (TE.Space 0)

layoutUnderOver :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutUnderOver state args = case args of
    [base, under, over] ->
        let baseElem = layout state base
            underElem = maybe Nothing (\e -> if e == Expr.TeXNothing then Nothing else Just (layout state e)) (Just under)
            overElem = maybe Nothing (\e -> if e == Expr.TeXNothing then Nothing else Just (layout state e)) (Just over)
            scriptScale = 0.7
            gap = 0.1
            
            baseX = 0
            elems = [(p2 (baseX, 0), 1, baseElem)]
            
            elemsWithUnder = case underElem of
                Nothing -> elems
                Just ue -> 
                    let underX = baseX + (inkWidth baseElem - scriptScale * inkWidth ue) / 2
                    in elems ++ [(p2 (underX, -inkHeight baseElem - gap), scriptScale, ue)]
            
            elemsWithOver = case overElem of
                Nothing -> elemsWithUnder
                Just oe ->
                    let overX = baseX + (inkWidth baseElem - scriptScale * inkWidth oe) / 2
                    in elemsWithUnder ++ [(p2 (overX, topInkBound baseElem + gap), scriptScale, oe)]
                    
        in GroupElem $ TE.Group elemsWithOver
    _ -> SpaceElem (TE.Space 0)

layoutIntegral :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutIntegral state args = layoutUnderOver state args

layoutFont :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutFont state args = case args of
    [Expr.TeXString fontCmd, content] ->
        let modifier = case fontCmd of
                "bb" -> Nothing
                "cal" -> Just Sf
                "frak" -> Nothing
                "scr" -> Just Sf
                "rm" -> Just Rm
                "it" -> Just It
                "bf" -> Just Bf
                "sf" -> Just Sf
                "tt" -> Just Tt
                _ -> Nothing
            newState = maybe state (\m -> addFontModifier state m) modifier
        in layout newState content
    _ -> SpaceElem (TE.Space 0)

layoutTextMode :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutTextMode state args =
    let newState = changeMode state LayoutContext.TextMode
    in case args of
        [] -> SpaceElem (TE.Space 0)
        [content] -> layout newState content
        (Expr.TeXString modifier : content : _) ->
            let modState = case modifier of
                    "bf" -> addFontModifier newState Bf
                    "it" -> addFontModifier newState It
                    "rm" -> addFontModifier newState Rm
                    "tt" -> addFontModifier newState Tt
                    _ -> newState
            in layout modState content
        _ -> SpaceElem (TE.Space 0)

layoutInlineMath :: LayoutState -> [Expr.TeXExpr] -> AnyTeXElement
layoutInlineMath state args =
    let newState = changeMode state MathMode
    in layoutGroup newState args