{-
SPDX-License-Identifier: AGPL-3.0-only

This file is part of `statebox/cql`, the categorical query language.

Copyright (C) 2019 Stichting Statebox <https://statebox.nl>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
-}
module Language.Parser.Instance where

import           Language.Parser.LexerRules
import           Language.Parser.Parser

-- base
import           Data.Maybe

-- megaparsec
import           Text.Megaparsec

import           Language.Instance          as I
import           Language.Parser.Mapping    as M
import           Language.Parser.Schema
import           Language.Schema            as S
import           Language.Term

eqParser :: Parser (RawTerm, RawTerm)
eqParser = do
  l <- rawTermParser
  _ <- constant "="
  r <- rawTermParser
  return (l, r)

eqParser2 :: Parser [(RawTerm, RawTerm)]
eqParser2 = do
  r <- many p'
  return $ concat r
  where
    p  = do
      p1 <- rawTermParser
      p2 <- rawTermParser
      return (p1, p2)
    p' = do
      l <- identifier
      _ <- constant "-> {"
      m <- sepBy p $ constant ","
      _ <- constant "}"
      return $ map (\(x, y) -> (RawApp l [x], y)) m

skParser :: Parser [(Gen, En)]
skParser = genParser


genParser :: Parser [(Gen, En)]
genParser = do
  x <- some identifier
  _ <- constant ":"
  y <- identifier
  return $ map (\a -> (a,y)) x

sigmaParser :: Parser InstanceExp
sigmaParser = do
  _ <- constant "sigma"
  f <- mapExpParser
  i <- instExpParser
  o <- optional $ braces $ do { _ <- constant "options"; many optionParser }
  return $ InstanceSigma f i $ fromMaybe [] o


deltaParser :: Parser InstanceExp
deltaParser = do
  _ <- constant "delta"
  f <- mapExpParser
  i <- instExpParser
  o <- optional $ braces $ do { _ <- constant "options"; many optionParser }
  return $ InstanceDelta f i $ fromMaybe [] o

instRawParser :: Parser InstExpRaw'
instRawParser = do
  _ <- constant "literal"
  _ <- constant ":"
  t <- schemaExpParser
  x <- (braces $ p t)
  pure $ x
  where p t = do i <- optional $ do
                    _ <- constant "imports"
                    many instExpParser
                 e <- optional $ do
                    _ <- constant "generators"
                    y <- many genParser
                    return $ concat y
                 o <- optional $ do
                    _ <- constant "equations"
                    many eqParser
                 o2 <- optional $ do
                    _ <- constant "multi_equations"
                    eqParser2
                 x <- optional $ do
                    _ <- constant "options"
                    many optionParser
                 pure $ InstExpRaw' t
                    (fromMaybe [] e)
                    (fromMaybe [] o ++ fromMaybe [] o2)
                    (fromMaybe [] x)
                    (fromMaybe [] i)

instExpParser :: Parser InstanceExp
instExpParser = InstanceRaw <$> instRawParser
    <|> InstanceVar  <$> identifier
    <|> sigmaParser  <|> deltaParser
    <|> do
        _ <- constant "empty"
        _ <- constant ":"
        x <- schemaExpParser
        return $ InstanceInitial x
    <|> parens instExpParser
