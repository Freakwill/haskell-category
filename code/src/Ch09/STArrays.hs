-- | Chapter 9: real in-place mutation, trapped inside the ST monad.
-- StateM threads copies of the state; ST really mutates, and runST
-- seals the mutation so the result is pure again.
module Ch09.STArrays
    ( inPlaceReverse
    , fibArray
    ) where

import Control.Monad       (forM_, when)
import Control.Monad.ST
import Data.Array.ST
    ( STArray
    , newListArray
    , newArray
    , readArray
    , writeArray
    , getElems
    )

-- ANCHOR: reverse
-- | Reverse a list by swapping array cells in place.  The mutation never
-- escapes: runST demands a pure result, so what leaks out is the
-- reversed list, not the array.
inPlaceReverse :: [Int] -> [Int]
inPlaceReverse xs = runST $ do
    arr <- newListArray (1, n) xs :: ST s (STArray s Int Int)
    forM_ [1 .. n `div` 2] $ \i -> do
        let j = n - i + 1
        a <- readArray arr i
        b <- readArray arr j
        writeArray arr i b
        writeArray arr j a
    getElems arr
  where
    n = length xs
-- ANCHOR_END: reverse

-- ANCHOR: fib
-- | Fibonacci with an in-place table: cell i is written once, read twice.
-- Compare with the StateM version in the exercises: StateM copies the
-- whole state every step, ST writes into the same cells.
fibArray :: Int -> Integer
fibArray n = runST $ do
    arr <- newArray (0, n) 0 :: ST s (STArray s Int Integer)
    writeArray arr 0 0
    when (n >= 1) (writeArray arr 1 1)
    forM_ [2 .. n] $ \i -> do
        a <- readArray arr (i - 1)
        b <- readArray arr (i - 2)
        writeArray arr i (a + b)
    readArray arr n
-- ANCHOR_END: fib
