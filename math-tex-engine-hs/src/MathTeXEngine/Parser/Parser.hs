{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module MathTeXEngine.Parser.Parser
    ( texParse
    , TeXParseError(..)
    ) where

import MathTeXEngine.Parser.TeXExpr
import MathTeXEngine.Parser.Token
import MathTeXEngine.Parser.Commands
import Data.Text (Text)
import qualified Data.Text as T
import Control.Monad (when)
import Control.Exception (Exception, throw)
import Data.Maybe (fromMaybe, isJust)

data TeXParseError = TeXParseError
    { errorMessage :: String
    , errorPosition :: Int
    , errorTeX :: Text
    } deriving (Show, Eq)

instance Exception TeXParseError

type ParseStack = [TeXExpr]

texParse :: Text -> TeXExpr
texParse tex = 
    let tokens = tokenize tex
        containsMath = T.isInfixOf "$" tex
        rootExpr = TeXExpr Expr []
        initialStack = [rootExpr, TeXExpr Expr []]
        finalStack = parseTokens containsMath False initialStack tokens
    in case finalStack of
        [root] -> simplifyRoot root
        [lines, line] -> 
            let linesExpr = pushArg lines (simplifyExpr line)
            in simplifyRoot linesExpr
        _ -> throw $ TeXParseError "unexpected end of input" (T.length tex) tex

simplifyRoot :: TeXExpr -> TeXExpr
simplifyRoot (TeXExpr Expr [single]) = single
simplifyRoot (TeXExpr Expr args) = TeXExpr Expr args
simplifyRoot expr = expr

parseTokens :: Bool -> Bool -> ParseStack -> [(Int, Int, TeXToken)] -> ParseStack
parseTokens _ _ stack [] = stack
parseTokens containsMath insideMath stack ((pos, len, token):rest) =
    let (newStack, newInsideMath) = parseToken containsMath insideMath stack pos len token
    in parseTokens containsMath newInsideMath newStack rest

parseToken :: Bool -> Bool -> ParseStack -> Int -> Int -> TeXToken -> (ParseStack, Bool)
parseToken containsMath insideMath stack pos len = \case
    TDollar -> (handleDollar stack, not insideMath)
    TNewline -> (handleNewline stack pos, insideMath)
    TLCurly -> (TeXExpr Group [] : stack, insideMath)
    TRCurly -> (handleRCurly stack pos, insideMath)
    TLeft delim -> (handleLeft stack delim, insideMath)
    TRight delim -> (handleRight stack pos delim, insideMath)
    TCommand cmd -> (handleCommand stack cmd, insideMath)
    TUnderscore -> (handleDecoration stack pos 2, insideMath)
    TCaret -> (handleDecoration stack pos 3, insideMath)
    TPrimes n -> (handlePrimes stack pos n, insideMath)
    TChar c -> (handleChar containsMath insideMath stack c, insideMath)
    TError -> throw $ TeXParseError "tokenizer error" pos ""

handleDollar :: ParseStack -> ParseStack
handleDollar [] = [TeXExpr InlineMath []]
handleDollar (top:rest) =
    case top of
        TeXExpr InlineMath _ -> pushDown rest top
        _ -> TeXExpr InlineMath [] : stack
  where stack = top : rest

handleNewline :: ParseStack -> Int -> ParseStack
handleNewline stack pos =
    case length stack of
        2 -> let [lines, line] = stack
             in [pushArg lines (simplifyExpr line), TeXExpr Expr []]
        _ -> throw $ TeXParseError "unexpected newline" pos ""

handleRCurly :: ParseStack -> Int -> ParseStack
handleRCurly [] pos = throw $ TeXParseError "unexpected }" pos ""
handleRCurly (top:rest) pos =
    case top of
        TeXExpr Group _ -> pushDown rest (simplifyGroup top)
        _ -> throw $ TeXParseError "missing closing }" pos ""

handleLeft :: ParseStack -> Text -> ParseStack
handleLeft stack delim = 
    let delimExpr = delimiter "\\left" delim
    in TeXExpr Delimiter [delimExpr] : stack

handleRight :: ParseStack -> Int -> Text -> ParseStack
handleRight [] pos _ = throw $ TeXParseError "missing opening delimiter" pos ""
handleRight (delimited:rest) pos delim =
    case delimited of
        TeXExpr Delimiter args -> 
            let rightDelim = delimiter "\\right" delim
                (leftDelim, contents) = case args of
                    [] -> (TeXChar '?', [])
                    [l] -> (l, [])
                    (l:cs) -> (l, cs)
                content = case contents of
                    [] -> TeXExpr Group []
                    [c] -> c
                    cs -> TeXExpr Group cs
            in pushDown rest (TeXExpr Delimiter [leftDelim, content, rightDelim])
        _ -> throw $ TeXParseError "missing opening delimiter" pos ""

handleCommand :: ParseStack -> Text -> ParseStack
handleCommand stack cmd =
    let reqArgs = requiredArgs cmd
    in if reqArgs == 0
       then pushDown stack (commandExpr cmd [])
       else let cmdExpr = TeXExpr Symbol [TeXString cmd]
                newStack = cmdExpr : stack
            in concludeCommand newStack

handleDecoration :: ParseStack -> Int -> Int -> ParseStack
handleDecoration stack pos index =
    case stack of
        [] -> throw $ TeXParseError "decoration without base" pos ""
        top:rest ->
            -- Pull the last expression from top (the base to be decorated)
            case top of
                TeXExpr _ [] -> throw $ TeXParseError "decoration without base" pos ""
                TeXExpr h args ->
                    let core = last args
                        remaining = init args
                        decorated = ensureDecorated core
                        slot = if index == 2 then 1 else 2  -- subscript=1, superscript=2
                    in case decorated of
                        TeXExpr Decorated decArgs | slot < length decArgs ->
                            case decArgs !! slot of
                                TeXNothing ->
                                    -- Push decorated back to top, then create new group for content
                                    let newTop = TeXExpr h (remaining ++ [decorated])
                                        decGroup = TeXExpr (if index == 2 then Expr else Expr) []
                                    in decGroup : newTop : rest
                                _ -> throw $ TeXParseError "multiple decorations" pos ""
                        _ -> error "ensureDecorated didn't return Decorated"
                _ -> throw $ TeXParseError "decoration without base" pos ""

nthMaybe :: Int -> [a] -> Maybe a
nthMaybe n xs = if n < length xs then Just (xs !! n) else Nothing

setNth :: TeXExpr -> Int -> TeXExpr -> TeXExpr
setNth (TeXExpr head args) n newVal =
    TeXExpr head (take n args ++ [newVal] ++ drop (n + 1) args)
setNth expr _ _ = expr

handlePrimes :: ParseStack -> Int -> Int -> ParseStack
handlePrimes stack pos n =
    let primesExpr = TeXExpr Symbol [TeXString (T.replicate n "'")]
    in handleDecoration stack pos 3

handleChar :: Bool -> Bool -> ParseStack -> Char -> ParseStack
handleChar containsMath insideMath stack c =
    let expr = if c == '-' && (not containsMath || insideMath)
               then TeXExpr Spaced [TeXExpr Symbol [TeXChar '−']]
               else canonicalExpr c
    in pushDown stack expr

ensureDecorated :: TeXExpr -> TeXExpr
ensureDecorated expr@(TeXExpr head _) =
    case head of
        Decorated -> expr
        UnderOver -> expr
        Integral -> expr
        _ -> TeXExpr Decorated [expr, TeXNothing, TeXNothing]
ensureDecorated expr = expr

delimiter :: Text -> Text -> TeXExpr
delimiter prefix str =
    let content = T.drop (T.length prefix) str
    in if T.length content == 1
       then let c = T.head content
                c' = case c of
                    '<' -> '⟨'
                    '>' -> '⟩'
                    _ -> c
            in TeXExpr Delimiter [TeXChar c']
       else texParse content

pushDown :: ParseStack -> TeXExpr -> ParseStack
pushDown [] expr = [expr]
pushDown (top:rest) expr =
    let newTop = pushArg top (simplifyExpr expr)
        stack' = newTop : rest
    in concludeCommand stack'

pushArg :: TeXExpr -> TeXExpr -> TeXExpr
pushArg (TeXExpr head args) arg = TeXExpr head (args ++ [arg])
pushArg expr arg = TeXExpr Expr [expr, arg]

simplifyExpr :: TeXExpr -> TeXExpr
simplifyExpr = simplifyGroup

simplifyGroup :: TeXExpr -> TeXExpr
simplifyGroup (TeXExpr Group []) = TeXExpr Spaced []
simplifyGroup (TeXExpr Group [single]) = single
simplifyGroup expr = expr

concludeCommand :: ParseStack -> ParseStack
concludeCommand [] = []
concludeCommand (cmd:rest) =
    case cmd of
        TeXExpr Symbol [TeXString cmdStr] ->
            let reqArgs = requiredArgs cmdStr
                availableArgs = length rest
            in if availableArgs >= reqArgs
               then let args = take reqArgs rest
                        remaining = drop reqArgs rest
                        cmdResult = commandExpr cmdStr (reverse args)
                    in pushDown remaining cmdResult
               else cmd : rest
        _ -> cmd : rest

getTexHead :: TeXExpr -> TeXExprHead
getTexHead (TeXExpr h _) = h
getTexHead _ = Expr

texArgs :: TeXExpr -> [TeXExpr]
texArgs (TeXExpr _ args) = args
texArgs _ = []