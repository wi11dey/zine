{-# LANGUAGE OverloadedStrings #-}

module MathTeXEngine.Parser.CommandData where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.HashMap.Strict as HM

binaryOperatorSymbols :: [Char]
binaryOperatorSymbols = ['+', '*', '−']

binaryOperatorCommands :: [Text]
binaryOperatorCommands = T.words $ T.unlines
    [ "\\pm \\sqcap"
    , "\\mp \\sqcup"
    , "\\times \\vee \\oplus"
    , "\\div \\wedge \\ominus"
    , "\\ast \\setminus \\otimes"
    , "\\star \\wr \\oslash"
    , "\\circ \\diamond \\odot"
    , "\\bullet \\bigtriangleup \\bigcirc"
    , "\\cdot \\bigtriangledown \\dagger"
    , "\\cap \\triangleleft \\ddagger"
    , "\\cup \\triangleright"
    , "\\uplus \\amalg"
    ]

relationSymbols :: [Char]
relationSymbols = ['=', '<', '>', ':']

relationCommands :: [Text]
relationCommands = T.words $ T.unlines
    [ "\\leq \\geq \\equiv \\models"
    , "\\prec \\succ \\sim \\perp"
    , "\\preceq \\succeq \\simeq \\mid"
    , "\\ll \\gg \\asymp \\parallel"
    , "\\subset \\supset \\approx \\bowtie"
    , "\\subseteq \\supseteq \\cong \\join"
    , "\\sqsubset \\sqsupset \\neq \\smile"
    , "\\sqsubseteq \\sqsupseteq \\doteq \\frown"
    , "\\in \\ni \\propto \\vdash"
    , "\\dashv \\dots \\dotplus"
    ]

arrowCommands :: [Text]
arrowCommands = T.words $ T.unlines
    [ "\\leftarrow \\longleftarrow \\uparrow"
    , "\\Leftarrow \\Longleftarrow \\Uparrow"
    , "\\rightarrow \\longrightarrow \\downarrow"
    , "\\Rightarrow \\Longrightarrow \\Downarrow"
    , "\\leftrightarrow \\longleftrightarrow \\updownarrow"
    , "\\Leftrightarrow \\Longleftrightarrow \\Updownarrow"
    , "\\mapsto \\longmapsto \\nearrow"
    , "\\hookleftarrow \\hookrightarrow \\searrow"
    , "\\leftharpoonup \\rightharpoonup \\swarrow"
    , "\\leftharpoondown \\rightharpoondown \\nwarrow"
    , "\\rightleftharpoons"
    ]

spacedSymbols :: [Char]
spacedSymbols = binaryOperatorSymbols ++ relationSymbols

spacedCommands :: [Text]
spacedCommands = binaryOperatorCommands ++ relationCommands ++ arrowCommands

underoverCommands :: [Text]
underoverCommands = T.words
    "\\sum \\prod \\coprod \\bigcap \\bigcup \\bigsqcup \\bigvee \\bigwedge \\bigodot \\bigotimes \\bigoplus \\biguplus"

underoverFunctions :: [Text]
underoverFunctions = T.words "lim liminf limsup inf sup min max"

integralCommands :: [Text]
integralCommands = ["\\int", "\\oint"]

genericFunctions :: [Text]
genericFunctions = T.words $ T.unlines
    [ "arccos csc ker arcsin deg lg Pr arctan det sec arg dim"
    , "sin cos exp sinh cosh gcd ln sup cot hom log tan"
    , "coth tanh"
    ]

spaceCommands :: HM.HashMap Text Double
spaceCommands = HM.fromList
    [ ("\\,", 0.16667)          -- 3/18 em = 3 mu
    , ("\\thinspace", 0.16667)  -- 3/18 em = 3 mu
    , ("\\/", 0.16667)          -- 3/18 em = 3 mu
    , ("\\>", 0.22222)          -- 4/18 em = 4 mu
    , ("\\:", 0.22222)          -- 4/18 em = 4 mu
    , ("\\;", 0.27778)          -- 5/18 em = 5 mu
    , ("\\ ", 0.33333)          -- 6/18 em = 6 mu
    , ("\\enspace", 0.5)        -- 9/18 em = 9 mu
    , ("\\quad", 1.0)           -- 1 em = 18 mu
    , ("\\qquad", 2.0)          -- 2 em = 36 mu
    , ("\\!", -0.16667)         -- -3/18 em = -3 mu
    ]

spaceSymbols :: HM.HashMap Char Double
spaceSymbols = HM.fromList
    [ ('~', 0.33333) -- 6/18 em = 6 mu, nonbreakable
    ]

combiningAccents :: [Text]
combiningAccents =
    [ "\\hat"
    , "\\breve"
    , "\\bar"
    , "\\grave"
    , "\\acute"
    , "\\tilde"
    , "\\dot"
    , "\\ddot"
    , "\\mathring"
    , "\\check"
    ]

accentToCombiningChar :: HM.HashMap Text Char
accentToCombiningChar = HM.fromList
    [ ("\\hat", '\x0302')
    , ("\\breve", '\x0306')
    , ("\\bar", '\x0304')
    , ("\\grave", '\x0300')
    , ("\\acute", '\x0301')
    , ("\\tilde", '\x0303')
    , ("\\dot", '\x0307')
    , ("\\ddot", '\x0308')
    , ("\\mathring", '\x030a')
    , ("\\check", '\x030c')
    ]

wideAccents :: [Text]
wideAccents =
    [ "\\overline"
    , "\\underline"
    , "\\overbrace"
    , "\\underbrace"
    , "\\overrightarrow"
    , "\\overleftarrow"
    , "\\widehat"
    , "\\widetilde"
    ]

delimiterCommands :: [(Text, Char)]
delimiterCommands =
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
    , ("\\lvert", '|')
    , ("\\rvert", '|')
    , ("\\lVert", '‖')
    , ("\\rVert", '‖')
    ]

extraSymbols :: [(Text, Text)]
extraSymbols =
    [ ("\\neq", "≠")
    , ("\\ne", "≠")
    , ("\\upepsilon", "ε")
    ]