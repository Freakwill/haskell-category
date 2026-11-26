-- | Chapter 2 examples: recursion, higher-order functions, currying.
--
-- Every slice the book shows lives between ANCHOR markers here, so the prose
-- cannot drift away from code that compiles and passes tests.
module Ch02.Functions
    ( add
    , addTen
    , total
    , doubleAll
    , evens
    , scores
    , passed
    , names
    , pairs
    , addPair
    , addCurried
    , grade
    , normalize
    , totalStrict
    ) where

import Data.List (foldl')

-- ANCHOR: add
add :: Int -> Int -> Int
add x y = x + y
-- ANCHOR_END: add

-- | @add 10@ is a function: we supplied one argument, one is still expected.
--
-- ANCHOR: add-ten
addTen :: Int -> Int
addTen = add 10
-- ANCHOR_END: add-ten

-- ANCHOR: total
total :: [Int] -> Int
total []     = 0
total (x:xs) = x + total xs
-- ANCHOR_END: total

-- ANCHOR: double
doubleAll :: [Int] -> [Int]
doubleAll []       = []
doubleAll (x : xs) = 2 * x : doubleAll xs
-- ANCHOR_END: double

-- ANCHOR: evens
evens :: [Int] -> [Int]
evens []       = []
evens (x : xs) = if even x then x : evens xs else evens xs
-- ANCHOR_END: evens

-- ANCHOR: scores
scores :: [(String, Int)]
scores = [("ann", 91), ("bob", 58), ("cy", 77), ("dee", 64)]
-- ANCHOR_END: scores

-- ANCHOR: pipeline
passed :: [(String, Int)]
passed = filter ((>= 60) . snd) scores

names :: [String]
names = map fst passed
-- ANCHOR_END: pipeline

-- ANCHOR: zip
pairs :: [Int]
pairs = zipWith (*) [1 .. 5] [10, 20, 30]
-- ANCHOR_END: zip

-- ANCHOR: strict-fold
totalStrict :: [Int] -> Int
totalStrict = foldl' (+) 0
-- ANCHOR_END: strict-fold

-- ANCHOR: curry
addPair :: (Int, Int) -> Int
addPair (x, y) = x + y

addCurried :: Int -> Int -> Int
addCurried = curry addPair
-- ANCHOR_END: curry

-- ANCHOR: guard
grade :: Int -> String
grade n
  | n >= 90   = "A"
  | n >= 80   = "B"
  | n >= 60   = "C"
  | otherwise = "F"
-- ANCHOR_END: guard

-- ANCHOR: where
normalize :: [Int] -> [Int]
normalize xs = map (\x -> (x - lo) * 100 `div` width) xs
  where
    lo    = minimum xs
    hi    = maximum xs
    width = max 1 (hi - lo)   -- 除以零的兜底：全部分数相同时宽为 1
-- ANCHOR_END: where
