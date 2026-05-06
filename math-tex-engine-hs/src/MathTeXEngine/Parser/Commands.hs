{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine.Parser.Commands 
    ( canonicalExpr
    , commandExpr
    , requiredArgs
    , getSymbolChar
    ) where

import MathTeXEngine.Parser.TeXExpr
import MathTeXEngine.Parser.CommandData
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.HashMap.Strict as HM
import Data.Char (isDigit)
import Data.Maybe (fromMaybe)

type CommandDefinition = (TeXExpr, Int)

symbolToCanonical :: HM.HashMap Char TeXExpr
symbolToCanonical = HM.fromList $ concat
    [ digitRegistrations
    , punctuationRegistrations
    , delimiterRegistrations
    , spacedSymbolRegistrations
    ]
  where
    digitRegistrations = [(c, TeXExpr Digit [TeXChar c]) | c <- ['0'..'9']]
    punctuationRegistrations = [(c, TeXExpr Punctuation [TeXChar c]) | c <- ",;.!?"]
    delimiterRegistrations = [(c, TeXExpr Delimiter [TeXChar c]) | c <- "|/\\()[]⟨⟩‖⌈⌉⌊⌋⌜⌝⌞⌟"]
    spacedSymbolRegistrations = [(c, TeXExpr Spaced [TeXExpr Symbol [TeXChar c]]) | c <- spacedSymbols]

commandDefinitions :: HM.HashMap Text CommandDefinition
commandDefinitions = HM.fromList $ concat
    [ basicCommands
    , symbolCommands
    , fontCommands
    , spaceCommandsList
    , accentCommands
    , functionCommands
    , operatorCommands
    , delimiterCommandsList
    ]
  where
    basicCommands =
        [ ("\\frac", (TeXExpr Frac [], 2))
        , ("\\sqrt", (TeXExpr Sqrt [], 1))
        , ("\\overline", (mkTeXExpr Font [TeXString "overline"], 1))
        , ("\\underline", (mkTeXExpr Font [TeXString "underline"], 1))
        ]
    
    symbolCommands =
        [ ("\\_", (TeXExpr Symbol [TeXChar '_'], 0))
        , ("\\%", (TeXExpr Symbol [TeXChar '%'], 0))
        , ("\\$", (TeXExpr Symbol [TeXChar '$'], 0))
        , ("\\&", (TeXExpr Symbol [TeXChar '&'], 0))
        , ("\\#", (TeXExpr Symbol [TeXChar '#'], 0))
        , ("\\ ", (TeXExpr Symbol [TeXChar ' '], 0))
        ]
    
    fontCommands =
        [ ("\\mathbb", (mkTeXExpr Font [TeXString "bb"], 1))
        , ("\\mathcal", (mkTeXExpr Font [TeXString "cal"], 1))
        , ("\\mathfrak", (mkTeXExpr Font [TeXString "frak"], 1))
        , ("\\mathscr", (mkTeXExpr Font [TeXString "scr"], 1))
        , ("\\mathrm", (mkTeXExpr Font [TeXString "rm"], 1))
        , ("\\mathit", (mkTeXExpr Font [TeXString "it"], 1))
        , ("\\mathbf", (mkTeXExpr Font [TeXString "bf"], 1))
        , ("\\mathsf", (mkTeXExpr Font [TeXString "sf"], 1))
        , ("\\mathtt", (mkTeXExpr Font [TeXString "tt"], 1))
        , ("\\text", (mkTeXExpr TextMode [], 1))
        , ("\\textbf", (mkTeXExpr TextMode [TeXString "bf"], 1))
        , ("\\textit", (mkTeXExpr TextMode [TeXString "it"], 1))
        , ("\\textrm", (mkTeXExpr TextMode [TeXString "rm"], 1))
        , ("\\texttt", (mkTeXExpr TextMode [TeXString "tt"], 1))
        ]
    
    spaceCommandsList = 
        [(cmd, (TeXExpr Spaced [TeXExpr (if w >= 0 then Symbol else Char) [TeXChar ' ']], 0)) 
         | (cmd, w) <- HM.toList spaceCommands]
    
    accentCommands =
        [(cmd, (TeXExpr Symbol [TeXChar (fromMaybe '?' (HM.lookup cmd accentToCombiningChar))], 1))
         | cmd <- combiningAccents]
    
    functionCommands = concat
        [ [(f, (TeXExpr Symbol [TeXString f], 0)) | f <- genericFunctions]
        , [(f, (TeXExpr UnderOver [TeXExpr Symbol [TeXString f], TeXNothing, TeXNothing], 0)) | f <- underoverFunctions]
        , [(cmd, (TeXExpr UnderOver [TeXExpr Symbol [TeXChar (getSymbolChar cmd)], TeXNothing, TeXNothing], 0)) | cmd <- underoverCommands]
        , [(cmd, (TeXExpr Integral [TeXExpr Symbol [TeXChar (getSymbolChar cmd)], TeXNothing, TeXNothing], 0)) | cmd <- integralCommands]
        ]
    
    operatorCommands =
        [(cmd, (TeXExpr Spaced [TeXExpr Symbol [TeXChar (getSymbolChar cmd)]], 0)) | cmd <- spacedCommands]
    
    delimiterCommandsList =
        [(cmd, (TeXExpr Delimiter [TeXChar c], 0)) | (cmd, c) <- delimiterCommands]

canonicalExpr :: Char -> TeXExpr
canonicalExpr c = fromMaybe (TeXExpr Char [TeXChar c]) (HM.lookup c symbolToCanonical)

commandExpr :: Text -> [TeXExpr] -> TeXExpr
commandExpr cmd args =
    case HM.lookup cmd commandDefinitions of
        Just (template, _) -> 
            let TeXExpr head templateArgs = template
            in TeXExpr head (templateArgs ++ args)
        Nothing -> TeXExpr Symbol [TeXChar (getSymbolChar cmd)]

requiredArgs :: Text -> Int
requiredArgs cmd = fromMaybe 0 $ fmap snd (HM.lookup cmd commandDefinitions)

getSymbolChar :: Text -> Char
getSymbolChar cmd = 
    case latexSymbolLookup cmd of
        Just c -> c
        Nothing -> '?'

latexSymbolLookup :: Text -> Maybe Char
latexSymbolLookup cmd = 
    case HM.lookup cmd extraSymbolsMap of
        Just sym -> Just (T.head sym)
        Nothing -> defaultLatexSymbols cmd
  where
    extraSymbolsMap = HM.fromList extraSymbols

defaultLatexSymbols :: Text -> Maybe Char
defaultLatexSymbols "\\alpha" = Just 'α'
defaultLatexSymbols "\\beta" = Just 'β'
defaultLatexSymbols "\\gamma" = Just 'γ'
defaultLatexSymbols "\\delta" = Just 'δ'
defaultLatexSymbols "\\epsilon" = Just 'ε'
defaultLatexSymbols "\\zeta" = Just 'ζ'
defaultLatexSymbols "\\eta" = Just 'η'
defaultLatexSymbols "\\theta" = Just 'θ'
defaultLatexSymbols "\\iota" = Just 'ι'
defaultLatexSymbols "\\kappa" = Just 'κ'
defaultLatexSymbols "\\lambda" = Just 'λ'
defaultLatexSymbols "\\mu" = Just 'μ'
defaultLatexSymbols "\\nu" = Just 'ν'
defaultLatexSymbols "\\xi" = Just 'ξ'
defaultLatexSymbols "\\pi" = Just 'π'
defaultLatexSymbols "\\rho" = Just 'ρ'
defaultLatexSymbols "\\sigma" = Just 'σ'
defaultLatexSymbols "\\tau" = Just 'τ'
defaultLatexSymbols "\\upsilon" = Just 'υ'
defaultLatexSymbols "\\phi" = Just 'φ'
defaultLatexSymbols "\\chi" = Just 'χ'
defaultLatexSymbols "\\psi" = Just 'ψ'
defaultLatexSymbols "\\omega" = Just 'ω'
defaultLatexSymbols "\\Gamma" = Just 'Γ'
defaultLatexSymbols "\\Delta" = Just 'Δ'
defaultLatexSymbols "\\Theta" = Just 'Θ'
defaultLatexSymbols "\\Lambda" = Just 'Λ'
defaultLatexSymbols "\\Xi" = Just 'Ξ'
defaultLatexSymbols "\\Pi" = Just 'Π'
defaultLatexSymbols "\\Sigma" = Just 'Σ'
defaultLatexSymbols "\\Upsilon" = Just 'Υ'
defaultLatexSymbols "\\Phi" = Just 'Φ'
defaultLatexSymbols "\\Psi" = Just 'Ψ'
defaultLatexSymbols "\\Omega" = Just 'Ω'
defaultLatexSymbols "\\infty" = Just '∞'
defaultLatexSymbols "\\partial" = Just '∂'
defaultLatexSymbols "\\nabla" = Just '∇'
defaultLatexSymbols "\\forall" = Just '∀'
defaultLatexSymbols "\\exists" = Just '∃'
defaultLatexSymbols "\\neg" = Just '¬'
defaultLatexSymbols "\\emptyset" = Just '∅'
defaultLatexSymbols "\\varnothing" = Just '∅'
defaultLatexSymbols "\\cdots" = Just '⋯'
defaultLatexSymbols "\\ldots" = Just '…'
defaultLatexSymbols "\\vdots" = Just '⋮'
defaultLatexSymbols "\\ddots" = Just '⋱'
-- Missing symbols for tests
defaultLatexSymbols "\\pm" = Just '±'
defaultLatexSymbols "\\mp" = Just '∓'
defaultLatexSymbols "\\times" = Just '×'
defaultLatexSymbols "\\div" = Just '÷'
defaultLatexSymbols "\\cdot" = Just '·'
defaultLatexSymbols "\\circ" = Just '∘'
defaultLatexSymbols "\\ast" = Just '∗'
defaultLatexSymbols "\\star" = Just '⋆'
defaultLatexSymbols "\\bullet" = Just '•'
defaultLatexSymbols "\\neq" = Just '≠'
defaultLatexSymbols "\\ne" = Just '≠'
defaultLatexSymbols "\\leq" = Just '≤'
defaultLatexSymbols "\\geq" = Just '≥'
defaultLatexSymbols "\\subset" = Just '⊂'
defaultLatexSymbols "\\supset" = Just '⊃'
defaultLatexSymbols "\\subseteq" = Just '⊆'
defaultLatexSymbols "\\supseteq" = Just '⊇'
defaultLatexSymbols "\\in" = Just '∈'
defaultLatexSymbols "\\ni" = Just '∋'
defaultLatexSymbols "\\rightarrow" = Just '→'
defaultLatexSymbols "\\to" = Just '→'
defaultLatexSymbols "\\leftarrow" = Just '←'
defaultLatexSymbols "\\Rightarrow" = Just '⇒'
defaultLatexSymbols "\\Leftarrow" = Just '⇐'
defaultLatexSymbols "\\leftrightarrow" = Just '↔'
defaultLatexSymbols "\\Leftrightarrow" = Just '⇔'
defaultLatexSymbols _ = Nothing