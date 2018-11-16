module Language.Parser.Parser where

import           Language.Parser.LexerRules
import           Language.Parser.ReservedWords

-- base
import           Data.Char

-- megaparsec
import           Text.Megaparsec
import           Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer    as L

-- scientific
import           Data.Scientific               (Scientific)
import           Language.Term

rawTermParser :: Parser RawTerm
rawTermParser =
  try (do f <- identifier
          _ <- constant "("
          a <- sepBy rawTermParser $ constant ","
          _ <- constant ")"
          return $ RawApp f a)
  <|>
  try (do t <- sepBy1 identifier $ constant "."
          return $ Prelude.foldl (\y x -> RawApp x [y]) (RawApp (head t) []) $ tail t)
  <|>
  try (do i <- identifier
          return $ RawApp i [])

optionParser :: Parser (String, String)
optionParser =
  do i <- identifier
     _ <- constant "="
     j <- identifier
     return (i,j)

identifier :: Parser String
identifier = (lexeme . try) (p >>= check)
  where
    unquotedIdentifier = some (idChar <|> digitChar)
    quotedIdentifier   = between (char '"') (char '"') $ some $ satisfy (\c -> isPrint c && (c /= '"'))
    p = unquotedIdentifier <|> quotedIdentifier
    check x =
      if x `elem` reservedWords
        then fail $ "keyword" ++ show x ++ "cannot be used as an identifier"
        else return x

constant :: String -> Parser String
constant = L.symbol spaceConsumer

braces :: Parser a -> Parser a
braces = between (constant "{") (constant "}")

parens :: Parser a -> Parser a
parens = between (constant "(") (constant ")")

integerParser :: Parser Integer -- TODO: write tests
integerParser = lexeme L.decimal

scientificParser :: Parser Scientific -- TODO: write tests
scientificParser = lexeme L.scientific

boolParser :: Parser Bool -- TODO: write tests
boolParser
  = pure True <* constant "true"
  <|> pure False <* constant "false"

textParser :: Parser String -- TODO: write tests
textParser = do
  _ <- constant "\""
  text <- many (escapeSeq <|> show <$> noneOf ['"', '\r', '\n', '\\']) -- TODO: check if the escping is correct
  _ <- constant "\""
  pure $ unwords text

escapeSeq :: Parser String -- TODO: write tests
escapeSeq = do
  _ <- char '\\'
  escaped
    <- show <$> oneOf ['b', 't', 'n', 'f', 'r', '"', '\'', '\\', '.']
    <|> unicodeEsc
    <|> eof *> pure ""
  pure escaped

unicodeEsc :: Parser String -- TODO: write tests
unicodeEsc
  = char 'u' *> pure "u"
  <|> (:)
    <$> (char 'u')
    <*> (show <$> hexDigitChar)
  <|> (:)
    <$> (char 'u')
    <*> ((:) <$> hexDigitChar <*> (show <$> hexDigitChar))
  <|> (:)
    <$> (char 'u')
    <*>((:)
      <$> hexDigitChar
      <*> ((:) <$> hexDigitChar <*> (show <$> hexDigitChar)))
