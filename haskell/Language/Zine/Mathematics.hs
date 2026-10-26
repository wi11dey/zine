module Language.Zine.Mathematics where

import Data.List (intercalate)
import Data.Text (Text)
import Data.Void (Void)
import GHC.Hs (LHsExpr)
import GHC.Hs.Extension (GhcPs)
import GHC.ThToHs (convertToHsExpr)
import Language.Haskell.TH
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
number :: Parser Exp
number = do
  value <- lexeme L.decimal
  return $ LitE (IntegerL value)

identifier' :: Parser String
identifier' = lexeme $ do
  first <- letterChar <|> char '_'
  rest <- many (alphaNumChar <|> char '_')
  return $ first:rest

symbol' :: Parser [String]
symbol' = identifier' `sepBy1` char '.'

symbol :: Parser Exp
symbol = do
  path <- symbol'
  return $ case path of
    [[variable]] -> LitE (StringL [variable])
    _ -> VarE (mkName (intercalate "'" path))

fromTypst :: Parser Exp
fromTypst = undefined

toLHsExpr :: Exp -> LHsExpr GhcPs
toLHsExpr = undefined
