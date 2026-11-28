-- | Chapter 13: automatic differentiation via dual numbers.  A value is
-- carried with its derivative; the arithmetic rules are the differentiation
-- rules, so evaluating a polynomial at x with dx = 1 returns f x and f' x
-- in one pass.
{-# LANGUAGE RankNTypes #-}

module Ch13.Autodiff
    ( Dual (..)
    , derivAt
    , polyDemo
    ) where

-- ANCHOR: dual
-- | Dual number: value and derivative together.
data Dual a = Dual a a
    deriving (Eq, Show)

instance Num a => Num (Dual a) where
    Dual x dx + Dual y dy = Dual (x + y) (dx + dy)
    Dual x dx - Dual y dy = Dual (x - y) (dx - dy)
    Dual x dx * Dual y dy = Dual (x * y) (x * dy + y * dx)
    negate (Dual x dx)    = Dual (negate x) (negate dx)
    abs (Dual x dx)       = Dual (abs x) (dx * signum x)
    signum (Dual x _)     = Dual (signum x) 0
    fromInteger n         = Dual (fromInteger n) 0
-- ANCHOR_END: dual

-- ANCHOR: deriv-at
-- | Derivative of a polynomial f at x: run f on the dual number (x, 1),
-- then read off the derivative half.  No difference quotient, no
-- symbolic rewriting -- the chain and product rules are built into
-- the Num instance.
derivAt :: (forall a. Num a => a -> a) -> Double -> Double
derivAt f x =
    let Dual _ d = f (Dual x 1)
    in d

-- | f x = x^2 + 3x + 2, the running example of the chapter.
polyDemo :: Num a => a -> a
polyDemo x = x * x + 3 * x + 2
-- ANCHOR_END: deriv-at
