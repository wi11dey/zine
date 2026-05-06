{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine.Parser.LatexSymbols
    ( latexSymbols
    , greekLetters
    , mathOperators
    , arrowSymbols
    , delimiterSymbols
    , delimiterCommands
    , spaceCommands
    , spaceSymbols
    ) where

import Data.Text (Text)
import qualified Data.Map.Strict as Map

-- | Basic Greek letters and common math symbols
greekLetters :: Map.Map Text Char
greekLetters = Map.fromList
    [ ("\\alpha", 'α')
    , ("\\beta", 'β')
    , ("\\gamma", 'γ')
    , ("\\delta", 'δ')
    , ("\\epsilon", 'ϵ')
    , ("\\varepsilon", 'ε')
    , ("\\zeta", 'ζ')
    , ("\\eta", 'η')
    , ("\\theta", 'θ')
    , ("\\vartheta", 'ϑ')
    , ("\\iota", 'ι')
    , ("\\kappa", 'κ')
    , ("\\lambda", 'λ')
    , ("\\mu", 'μ')
    , ("\\nu", 'ν')
    , ("\\xi", 'ξ')
    , ("\\pi", 'π')
    , ("\\varpi", 'ϖ')
    , ("\\rho", 'ρ')
    , ("\\varrho", 'ϱ')
    , ("\\sigma", 'σ')
    , ("\\varsigma", 'ς')
    , ("\\tau", 'τ')
    , ("\\upsilon", 'υ')
    , ("\\phi", 'ϕ')
    , ("\\varphi", 'φ')
    , ("\\chi", 'χ')
    , ("\\psi", 'ψ')
    , ("\\omega", 'ω')
    -- Capital Greek letters
    , ("\\Gamma", 'Γ')
    , ("\\Delta", 'Δ')
    , ("\\Theta", 'Θ')
    , ("\\Lambda", 'Λ')
    , ("\\Xi", 'Ξ')
    , ("\\Pi", 'Π')
    , ("\\Sigma", 'Σ')
    , ("\\Upsilon", 'Υ')
    , ("\\Phi", 'Φ')
    , ("\\Psi", 'Ψ')
    , ("\\Omega", 'Ω')
    -- Additional symbols needed for tests
    , ("\\sin", '∅')  -- placeholder, will be handled as function
    , ("\\cos", '∅')  -- placeholder
    , ("\\lim", '∅')  -- placeholder
    ]

-- | Math operators and relations
mathOperators :: Map.Map Text Char
mathOperators = Map.fromList
    [ ("\\pm", '±')
    , ("\\mp", '∓')
    , ("\\times", '×')
    , ("\\div", '÷')
    , ("\\neq", '≠')
    , ("\\leq", '≤')
    , ("\\geq", '≥')
    , ("\\subset", '⊂')
    , ("\\supset", '⊃')
    , ("\\subseteq", '⊆')
    , ("\\supseteq", '⊇')
    , ("\\in", '∈')
    , ("\\ni", '∋')
    , ("\\infty", '∞')
    , ("\\sum", '∑')
    , ("\\prod", '∏')
    , ("\\int", '∫')
    , ("\\oint", '∮')
    , ("\\sqrt", '√')
    , ("\\cdot", '·')
    , ("\\circ", '∘')
    , ("\\bullet", '•')
    , ("\\star", '⋆')
    , ("\\ast", '∗')
    , ("\\oplus", '⊕')
    , ("\\ominus", '⊖')
    , ("\\otimes", '⊗')
    , ("\\oslash", '⊘')
    , ("\\odot", '⊙')
    , ("\\cap", '∩')
    , ("\\cup", '∪')
    , ("\\vee", '∨')
    , ("\\wedge", '∧')
    ]

-- | Arrow symbols
arrowSymbols :: Map.Map Text Char
arrowSymbols = Map.fromList
    [ ("\\leftarrow", '←')
    , ("\\rightarrow", '→')
    , ("\\leftrightarrow", '↔')
    , ("\\Leftarrow", '⇐')
    , ("\\Rightarrow", '⇒')
    , ("\\Leftrightarrow", '⇔')
    , ("\\uparrow", '↑')
    , ("\\downarrow", '↓')
    , ("\\updownarrow", '↕')
    , ("\\Uparrow", '⇑')
    , ("\\Downarrow", '⇓')
    , ("\\Updownarrow", '⇕')
    , ("\\mapsto", '↦')
    , ("\\to", '→')
    ]

-- | Delimiter symbols (not commands)
delimiterSymbols :: [Char]
delimiterSymbols = 
    [ '|', '/', '\\', '(', ')', '[', ']', '⟨', '⟩', '‖'
    , '⌈', '⌉', '⌊', '⌋', '⌜', '⌝', '⌞', '⌟'
    ]

-- | Delimiter commands
delimiterCommands :: Map.Map Text Char
delimiterCommands = Map.fromList
    [ ("\\vert", '|')
    , ("\\slash", '/')
    , ("\\backslash", '\\')
    , ("\\lbrack", '[')
    , ("\\rbrack", ']')
    , ("\\langle", '⟨')
    , ("\\rangle", '⟩')
    , ("\\|", '‖')
    , ("\\Vert", '‖')
    , ("\\lceil", '⌈')
    , ("\\rceil", '⌉')
    , ("\\lfloor", '⌊')
    , ("\\rfloor", '⌋')
    , ("\\ulcorner", '⌜')
    , ("\\urcorner", '⌝')
    , ("\\llcorner", '⌞')
    , ("\\lrcorner", '⌟')
    , ("\\{", '{')
    , ("\\}", '}')
    , ("\\lbrace", '{')
    , ("\\rbrace", '}')
    ]

-- | Space commands with their widths in em units
spaceCommands :: Map.Map Text Double
spaceCommands = Map.fromList
    [ ("\\,", 0.16667)          -- thin space
    , ("\\thinspace", 0.16667)
    , ("\\/", 0.16667)
    , ("\\>", 0.22222)          -- medium space
    , ("\\:", 0.22222)
    , ("\\;", 0.27778)          -- thick space
    , ("\\ ", 0.33333)          -- normal space
    , ("\\enspace", 0.5)
    , ("\\quad", 1.0)
    , ("\\qquad", 2.0)
    , ("\\!", -0.16667)         -- negative thin space
    ]

-- | Space symbols
spaceSymbols :: Map.Map Char Double
spaceSymbols = Map.singleton '~' 0.33333

-- | Combined map of all LaTeX symbols
latexSymbols :: Map.Map Text Char
latexSymbols = Map.unions 
    [ greekLetters
    , mathOperators
    , arrowSymbols
    , delimiterCommands
    ]