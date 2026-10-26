module Language.Zine.Mathematics where

import Data.List (intercalate)
import Data.Text (Text)
import Data.Void (Void)
import GHC.Data.FastString (mkFastString)
import GHC.Hs (HsExpr (..), mkHsIntegral, mkHsString, noExtField)
import GHC.Hs.Extension (GhcPs)
import GHC.Parser.Annotation (noAnn, noLocA)
import GHC.Types.Name.Reader (mkVarUnqual)
import GHC.Types.SourceText (mkIntegralLit)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 empty empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

verbatim = L.symbol sc

-- TODO: numbers with decimals
number :: Parser (HsExpr GhcPs)
number = do
  value <- lexeme L.decimal
  return $ HsOverLit noExtField (mkHsIntegral (mkIntegralLit value))

symbol :: Parser (HsExpr GhcPs)
symbol = do
  symbolPath <- path
  return $ case symbolPath of
    [[variable]] -> HsLit noExtField (mkHsString [variable])
    _ -> HsVar noExtField (noLocA (mkVarUnqual (mkFastString (intercalate "'" symbolPath))))
  where
    path :: Parser [String]
    path = identifier `sepBy1` char '.'

    identifier :: Parser String
    identifier = lexeme $ do
      first <- letterChar <|> char '_'
      rest <- many (alphaNumChar <|> char '_')
      return $ first : rest

atom :: Parser (HsExpr GhcPs)
atom =
  number
    <|> symbol

-- | Fold alternating operands and operators; reject empty or even-length lists.
foldInfix :: [HsExpr GhcPs] -> Maybe (HsExpr GhcPs)
foldInfix [] = Nothing
foldInfix [value] = Just value
foldInfix (lhs : operator : rhs : rest) =
  -- GHC expects left-associated OpApps before resolving fixities.
  foldInfix (OpApp noAnn (noLocA lhs) (noLocA operator) (noLocA rhs) : rest)
foldInfix _ = Nothing

expression :: Parser (HsExpr GhcPs)
expression = do
  factors <- some atom
  case foldInfix (separateLiterals factors) of
    Just result -> pure result
    Nothing -> fail "expected an operand after an infix operator"
  where
    groupOperation :: HsExpr GhcPs
    groupOperation = HsVar noExtField (noLocA (mkVarUnqual (mkFastString "op'")))

    -- \| Adds groupOperations where needed to avoid two consecutive literals
    separateLiterals :: [HsExpr GhcPs] -> [HsExpr GhcPs]
    separateLiterals (first : second : rest)
      | isLiteral first && isLiteral second =
          first : groupOperation : separateLiterals (second : rest)
    separateLiterals (first : rest) = first : separateLiterals rest
    separateLiterals [] = []

    isLiteral :: HsExpr GhcPs -> Bool
    isLiteral HsLit {} = True
    isLiteral HsOverLit {} = True
    isLiteral _ = False

fromTypst :: Parser (HsExpr GhcPs)
fromTypst = undefined
