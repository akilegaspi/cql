module Language.Parser.Mapping where

import           Data.List                  (foldl')
import           Data.Maybe
import           Language.Mapping
import           Language.Parser.LexerRules
import           Language.Parser.Parser
import           Language.Parser.Schema     hiding (attParser, fkParser)
import           Text.Megaparsec

--------------------------------------------------------------------------------

fkParser :: Parser (String, [String])
fkParser = do x <- identifier
              _ <- constant "->"
              y <- sepBy1 identifier $ constant "."
              return (x, y)

schemaPathParser :: Parser SchemaPath
schemaPathParser = do
  prefix <- identifier
  maybeParen <- optional $ constant "(" *> schemaPathParser <* constant ")"
  suffixes <- many $ constant "." *> identifier
  let prefixWithParens =
        case maybeParen of
          Just paren -> SchemaPathParen prefix paren
          Nothing    -> SchemaPathArrowId prefix
  pure $ foldl' SchemaPathDotted prefixWithParens suffixes

attParser :: Parser MappingApp
attParser
  = do
    x <- identifier
    _ <- constant "->"
    _ <- constant "lambda"
    y <- identifier
    --  _ <- constant ":"
    --   t <- identifier
    _ <- constant "."
    e <- rawTermParser
    return $ MappingAppLambda (x, (y, e))
  <|> MappingAppPointFree <$> schemaPathParser

mappingRawParser :: Parser MappingExpRaw'
mappingRawParser = do
        _ <- constant "literal"
        _ <- constant ":"
        s <- schemaExpParser
        _ <- constant "->"
        t <- schemaExpParser
        m <- braces $ (q' s t)
        pure $ m
 where p   = do  x <- do
                    _ <- constant "entity"
                    v <- identifier
                    _ <- constant "->"
                    u <- identifier
                    return (v,u)
                 f <- optional $ do
                    _ <- constant "foreign_keys"
                    many fkParser
                 a <- optional $ do
                    _ <- constant "attributes"
                    many attParser
                 pure $ (x,fromMaybe [] f, fromMaybe [] a)
       q' s t = do m <- many p
                   o <- optional $ do
                          _ <- constant "options"
                          many optionParser
                   pure $ q s t (fromMaybe [] o) m

       q s t o = Prelude.foldr (\(x,fm,am) (MappingExpRaw' s' t' ens' fks' atts' o') -> MappingExpRaw' s' t' (x:ens') (fm++fks') (am++atts') o') (MappingExpRaw' s t [] [] [] o)





mapExpParser :: Parser MappingExp
mapExpParser =
    MappingRaw <$> mappingRawParser
    <|>
      MappingVar <$> identifier
    <|>
       do
        _ <- constant "identity"
        x <- schemaExpParser
        return $ MappingId x
    <|> parens mapExpParser
