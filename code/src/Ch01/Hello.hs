-- | Chapter 1: the smallest runnable script, for the 1.1 walkthrough.
--   Also the book's "hello" executable target, so CI compiles it.
module Main (main) where

-- ANCHOR: hello
-- Comments start with two dashes.
double :: Int -> Int
double x = x * 2

-- The entry point: an IO () action.
main :: IO ()
main = print (double 21)
-- ANCHOR_END: hello
