-- | Chapter 1 examples: a small evaluator, laziness, and one IO action.
--
-- The book includes slices of this file by ANCHOR, so every line a reader
-- sees here is compiled by CI. Keep the evaluator deliberately small: it is
-- the seed of the running project that Chapter 16 finishes.
module Ch01.Tour
    ( Expr (..)
    , eval
    , pretty
    , demoExpr
    , firstFive
    , squaresOf
    ) where

-- ANCHOR: expr
data Expr
    = Lit Int
    | Add Expr Expr
    | Mul Expr Expr
    | Neg Expr
    deriving (Eq, Show)
-- ANCHOR_END: expr

-- ANCHOR: eval
eval :: Expr -> Int
eval (Lit n)   = n
eval (Add a b) = eval a + eval b
eval (Mul a b) = eval a * eval b
eval (Neg a)   = negate (eval a)
-- ANCHOR_END: eval

-- ANCHOR: pretty
pretty :: Expr -> String
pretty (Lit n)   = show n
pretty (Add a b) = "(" ++ pretty a ++ " + " ++ pretty b ++ ")"
pretty (Mul a b) = "(" ++ pretty a ++ " * " ++ pretty b ++ ")"
pretty (Neg a)   = "-" ++ pretty a
-- ANCHOR_END: pretty

-- | @6 * (2 + 3)@ written as a tree.
--
-- ANCHOR: demoExpr
demoExpr :: Expr
demoExpr = Mul (Lit 6) (Add (Lit 2) (Lit 3))
-- ANCHOR_END: demoExpr

-- ANCHOR: lazy
firstFive :: [Int]
firstFive = take 5 squares
  where
    squares = map (^ 2) [0 ..]   -- an infinite list; defining it costs nothing
-- ANCHOR_END: lazy

-- | Same values, produced on demand instead of up front.
squaresOf :: [Int] -> [Int]
squaresOf = map (^ 2)
