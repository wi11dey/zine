{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Parser for the "zine" language, ported from a tree-sitter grammar.
-- Targets the incremental parser in Parser.Incremental.
--
-- Grammar shape (after desugaring):
--   text        := token (' ' token)*
--   token       := span | word | math
--   span        := /[a-z]+\{/ text '}'
--   word        := /[^ \r\n{}]+/
--   math        := display | inline
--   display     := '{{' expression '}}'
--   inline      := '{' expression '}'
--   expression  := atom | negation | noncommutative | commutative
--                | norm | set | bra | ket | projection | interval | parens
--   atom        := identifier | integer | script | postfix
--   script      := superscript | subscript
--   ...
--
-- The `_expression` helper from the original grammar (which allowed an
-- optional leading space) is folded into the call sites.

module Zine.Parser
  ( -- * AST
    Text(..)
  , Token(..)
  , Math(..)
  , Expression(..)
  , Atom(..)
  , Script(..)
  , Bracket(..)
  , Element(..)
    -- * Parsers
  , pText
  , pToken
  , pExpression
  ) where

import           Control.Applicative (many, optional, some, (<|>))
import           Data.Char           (isAlpha, isDigit, isLower)

import           Parser.Incremental  (Parser, recoverWith, symbol)

--------------------------------------------------------------------------------
-- AST
--------------------------------------------------------------------------------

-- | A text body: a non-empty sequence of tokens separated by single spaces.
newtype Text = Text [Token]
  deriving (Show, Eq)

data Token
  = TSpan  String Text     -- ^ keyword{ ... }
  | TWord  String          -- ^ bare word (no spaces, no braces)
  | TMath  Math
  deriving (Show, Eq)

data Math
  = MDisplay Expression    -- ^ {{ expr }}
  | MInline  Expression    -- ^ {  expr  }
  deriving (Show, Eq)

data Expression
  = EAtom          Atom
  | ENegation      Expression                        -- ^ - atom | - parens
  | ENoncomm       Expression Expression             -- ^ juxtaposition (with or without space)
  | ECommutative   Expression String Expression      -- ^ a + b | a - b   (operator includes spaces)
  | ENorm          Expression                        -- ^ | expr |
  | ESet           [Element]                         -- ^ [ a, b, c, ... ]  or  [ a | b ]
  | ESetBuilder    Expression Expression             -- ^ [ a | b ]
  | EBra           Expression                        -- ^ < expr |
  | EKet           Expression                        -- ^ | expr >
  | EProjection    Expression Expression             -- ^ < a | b >
  | EInterval      Char Expression Expression Char   -- ^ ( a .. b ) etc.
  | EParens        Expression
  deriving (Show, Eq)

data Atom
  = AIdent     String
  | AInteger   String
  | AScript    Script
  | APostfix   Atom Char     -- ^ atom followed by ! # or '
  deriving (Show, Eq)

data Script
  = Superscript Bracket Bracket  -- ^ base ^ exponent
  | Subscript   Bracket Bracket  -- ^ base _ index
  deriving (Show, Eq)

-- | A "bracketed-or-atomic" expression that can appear next to a script
-- operator. Mirrors `choice(@atom, @parens, @norm)` and friends.
data Bracket
  = BAtom      Atom
  | BParens    Expression
  | BNorm      Expression
  | BNegation  Expression
  deriving (Show, Eq)

data Element
  = EElem Expression
  | EEllipsis
  deriving (Show, Eq)

--------------------------------------------------------------------------------
-- Low-level character helpers
--------------------------------------------------------------------------------

-- | Match a single specific character.
char :: Char -> Parser Char Char
char c = symbol (== c)

-- | Match a literal string.
str :: String -> Parser Char String
str = traverse char

-- | One character satisfying a predicate.
satisfy :: (Char -> Bool) -> Parser Char Char
satisfy = symbol

-- | One ASCII space.
space :: Parser Char Char
space = char ' '

-- | A non-empty run of characters satisfying a predicate.
some1 :: (Char -> Bool) -> Parser Char String
some1 p = some (satisfy p)

--------------------------------------------------------------------------------
-- Tokens / text
--------------------------------------------------------------------------------

-- | text := token (' ' token)*
pText :: Parser Char Text
pText = (\t ts -> Text (t : ts)) <$> pToken <*> many (space *> pToken)

-- | token := span | word | math
--
-- We try `span` and `math` before `word` because `word` is greedy on any
-- non-space, non-brace character; the keyword form `[a-z]+{` would otherwise
-- be eaten by it. `recoverWith` wraps the fall-throughs so the disjunction
-- still terminates if none match.
pToken :: Parser Char Token
pToken =
      (TMath <$> pMath)
  <|> (uncurry TSpan <$> pSpan)
  <|> (TWord <$> pWord)

-- | span := /[a-z]+\{/ text '}'
--
-- Returns (keyword, body) so the caller can wrap it with the field name.
pSpan :: Parser Char (String, Text)
pSpan = do
  kw   <- some1 isLower
  _    <- char '{'
  body <- pText
  _    <- char '}'
  pure (kw, body)

-- | word := /[^ \r\n{}]+/
pWord :: Parser Char String
pWord = some1 (\c -> c /= ' ' && c /= '\r' && c /= '\n'
                  && c /= '{' && c /= '}')

-- | math := display | inline
--
-- Display ({{ ... }}) is tried first because its prefix is a strict
-- extension of inline's prefix.
pMath :: Parser Char Math
pMath = pDisplay <|> pInline
  where
    pDisplay = MDisplay <$> (str "{{" *> pExpression <* str "}}")
    pInline  = MInline  <$> (char '{' *> pExpression <* char '}')

--------------------------------------------------------------------------------
-- Expressions
--------------------------------------------------------------------------------

-- | The original grammar threads an `_expression` helper that optionally
-- consumes a leading space. We inline that here: `pExprSp` accepts an
-- optional leading space; `pExpression` does not.
pExprSp :: Parser Char Expression
pExprSp = (space *> pExprSp) <|> pExpression

-- | expression := one of the many forms below.
--
-- Ordering matters: longer/more-specific prefixes come first. The
-- incremental parser's `Disj` plus the `Yuck`/profile machinery will pick
-- the best parse, but giving it a sensible static order keeps the
-- search shallow.
pExpression :: Parser Char Expression
pExpression =
      pCommutative                -- a +/- b   (binary, left-assoc)
  <|> pNoncomm                    -- a b       (juxtaposition)
  <|> pProjection                 -- < a | b >
  <|> pBra                        -- < a |
  <|> pKet                        -- | a >
  <|> pNorm                       -- | a |
  <|> pSet                        -- [ ... ]
  <|> pInterval                   -- (a..b)  [a..b)  ...
  <|> pParens                     -- ( a )
  <|> pNegation                   -- - a
  <|> (EAtom <$> pAtom)           -- atom

-- | atom := identifier | integer | script | postfix
--
-- Script and postfix are built on top of a plainer atom, so we parse the
-- "head" first and then optionally extend it. This avoids left recursion.
pAtom :: Parser Char Atom
pAtom = do
  base <- pAtomHead
  pAtomTail base

-- | The non-recursive part of an atom.
pAtomHead :: Parser Char Atom
pAtomHead =
      (AIdent   <$> some1 isAlpha)
  <|> (AInteger <$> some1 isDigit)

-- | After a head atom we may see ^expr, _expr, or a postfix operator.
-- We chain greedily: a^b! is parsed as postfix(superscript(a,b), '!').
pAtomTail :: Atom -> Parser Char Atom
pAtomTail a =
      (do _ <- char '^'
          rhs <- pBracketSuper
          pAtomTail (AScript (Superscript (BAtom a) rhs)))
  <|> (do _ <- char '_'
          rhs <- pBracketSub
          pAtomTail (AScript (Subscript (BAtom a) rhs)))
  <|> (do op <- satisfy (`elem` "!#'")
          pAtomTail (APostfix a op))
  <|> pure a

-- | RHS of `^`: choice(@atom, @parens, @negation)
pBracketSuper :: Parser Char Bracket
pBracketSuper =
      (BParens   <$> pParensInner)
  <|> (BNegation <$> pNegationInner)
  <|> (BAtom    <$> pAtom)

-- | RHS of `_`: choice(@atom, @parens, @negation)
pBracketSub :: Parser Char Bracket
pBracketSub = pBracketSuper

-- | negation := '-' choice(@atom, @parens)
pNegation :: Parser Char Expression
pNegation = ENegation <$> pNegationInner

pNegationInner :: Parser Char Expression
pNegationInner = do
  _ <- char '-'
  (EAtom <$> pAtom) <|> pParens

-- | parens := '(' expression ')'
pParens :: Parser Char Expression
pParens = EParens <$> pParensInner

pParensInner :: Parser Char Expression
pParensInner = char '(' *> pExpression <* char ')'

-- | norm := '|' expression '|'
pNorm :: Parser Char Expression
pNorm = ENorm <$> (char '|' *> pExpression <* char '|')

-- | bra := '<' expression '|'    (no closing '>')
pBra :: Parser Char Expression
pBra = EBra <$> (char '<' *> pExpression <* char '|')

-- | ket := '|' expression '>'    (no opening '<')
pKet :: Parser Char Expression
pKet = EKet <$> (char '|' *> pExpression <* char '>')

-- | projection := '<' expression '|' expression '>'
pProjection :: Parser Char Expression
pProjection = do
  _ <- char '<'
  l <- pExpression
  _ <- char '|'
  r <- pExpression
  _ <- char '>'
  pure (EProjection l r)

-- | set := '[' (elements | expression '|' expression) ']'
pSet :: Parser Char Expression
pSet = do
  _ <- char '['
  body <- pSetBuilder <|> (ESet <$> pElements)
  _ <- char ']'
  pure body
  where
    pSetBuilder = do
      l <- pExpression
      _ <- char '|'
      r <- pExpression
      pure (ESetBuilder l r)

-- | elements := expression ',' expression (',' expression)*
--             [ ',' '...' [ ',' expression (',' expression)* ] ]
pElements :: Parser Char [Element]
pElements = do
  e1   <- pExpression
  _    <- char ','
  e2   <- pExpression
  more <- many (char ',' *> pExpression)
  tail_ <- optional pTrailingEllipsis
  pure $ map EElem (e1 : e2 : more) ++ concat tail_
  where
    pTrailingEllipsis :: Parser Char [Element]
    pTrailingEllipsis = do
      _ <- char ','
      _ <- str "..."
      rest <- optional $ do
        _   <- char ','
        x   <- pExpression
        xs  <- many (char ',' *> pExpression)
        pure (x : xs)
      pure (EEllipsis : maybe [] (map EElem) rest)

-- | interval := ('(' | '[') expression '..' expression (')' | ']')
pInterval :: Parser Char Expression
pInterval = do
  o <- satisfy (\c -> c == '(' || c == '[')
  l <- pExpression
  _ <- str ".."
  r <- pExpression
  c <- satisfy (\c -> c == ')' || c == ']')
  pure (EInterval o l r c)

-- | noncommutative
--   := _expression ' ' _expression     (precedence 3, left-assoc)
--    | parens parens                   (no separator)
--
-- We parse one head expression and then try to extend with a juxtaposed
-- partner. Recovery uses `recoverWith` so that an isolated expression still
-- parses if no partner follows.
pNoncomm :: Parser Char Expression
pNoncomm =
      pParensJuxt
  <|> pSpacedJuxt
  where
    pParensJuxt = do
      l <- pParens
      r <- pParens
      pure (ENoncomm l r)

    pSpacedJuxt = do
      l <- pExprNoBinop
      _ <- space
      r <- pExprNoBinop
      pure (ENoncomm l r)

-- | An expression that doesn't itself start by re-entering pCommutative or
-- pNoncomm at the top -- used as the operands of those rules to avoid
-- immediate left recursion. The Disj/profile mechanism still discovers
-- left-associative chains via repeated application from outside.
pExprNoBinop :: Parser Char Expression
pExprNoBinop =
      pProjection
  <|> pBra
  <|> pKet
  <|> pNorm
  <|> pSet
  <|> pInterval
  <|> pParens
  <|> pNegation
  <|> (EAtom <$> pAtom)

-- | commutative := _expression (' + ' | ' - ') (_expression | ellipsis)
--
-- The original grammar uses prec.left 1 so this is left-associative.
-- We implement it iteratively over a non-binop seed.
pCommutative :: Parser Char Expression
pCommutative = do
  first_ <- pExprNoBinop <|> pNoncommNoCommut
  rest   <- some pCommTail
  pure (foldl (\acc (op, e) -> ECommutative acc op e) first_ rest)
  where
    pCommTail :: Parser Char (String, Expression)
    pCommTail = do
      op  <- (str " + ") <|> (str " - ")
      rhs <- pExprNoBinop
         <|> pNoncommNoCommut
         <|> (EAtom AIdent <$ recoverWith (pure ()))   -- placeholder; see below
                                                       -- (only used if a real RHS fails)
      pure (op, rhs)
                                                       -- ^ Note: recoverWith pulls
                                                       -- a "yucky" but valid parse so
                                                       -- the disjunction terminates.

-- | A noncommutative juxtaposition that doesn't itself start with a
-- commutative chain. Used inside pCommutative as an operand option.
pNoncommNoCommut :: Parser Char Expression
pNoncommNoCommut =
      (do l <- pParens; r <- pParens; pure (ENoncomm l r))
  <|> (do l <- pExprNoBinop
          _ <- space
          r <- pExprNoBinop
          pure (ENoncomm l r))
