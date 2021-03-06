{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE FlexibleInstances #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Machine.Source
-- Copyright   :  (C) 2012 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  Rank-2 Types
--
----------------------------------------------------------------------------
module Data.Machine.Source
  (
  -- * Sources
    Source, SourceT
  , source
  , repeated
  , cycled
  , cap
  , iterated
  , replicated
  , enumerateFromTo
  ) where

import Control.Category
import Data.Foldable
import Data.Machine.Plan
import Data.Machine.Type
import Data.Machine.Process
import Prelude (Enum, Eq, Int, otherwise, succ, (==), (>>))

-------------------------------------------------------------------------------
-- Source
-------------------------------------------------------------------------------

-- | A 'Source' never reads from its inputs.
type Source b = forall k. Machine k b

-- | A 'SourceT' never reads from its inputs, but may have monadic side-effects.
type SourceT m b = forall k. MachineT m k b

-- | Repeat the same value, over and over.
repeated :: o -> Source o
repeated = repeatedly . yield

-- | Loop through a 'Foldable' container over and over.
cycled :: Foldable f => f b -> Source b
cycled xs = repeatedly (traverse_ yield xs)

-- | Generate a 'Source' from any 'Foldable' container.
source :: Foldable f => f b -> Source b
source xs = construct (traverse_ yield xs)

-- |
-- You can transform a 'Source' with a 'Process'.
--
-- Alternately you can view this as capping the 'Source' end of a 'Process',
-- yielding a new 'Source'.
--
-- @'cap' l r = l '<~' r@
--
cap :: Process a b -> Source a -> Source b
cap l r = l <~ r

-- | 'iterated' @f x@ returns an infinite source of repeated applications
-- of @f@ to @x@
iterated :: (a -> a) -> a -> Source a
iterated f x = construct (go x) where
  go a = do
    yield a
    go (f a)

-- | 'replicated' @n x@ is a source of @x@ emitted @n@ time(s)
replicated :: Int -> a -> Source a
replicated n x = repeated x ~> taking n

-- | Enumerate from a value to a final value, inclusive, via 'succ'
enumerateFromTo :: (Enum a, Eq a) => a -> a -> Source a
enumerateFromTo start end = construct (go start) where
  go i
    | i == end  = yield i
    | otherwise = yield i >> go (succ i)
