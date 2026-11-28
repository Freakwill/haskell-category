-- | Chapter 13: vector arithmetic on Seq, matrix product, and numerical
-- differentiation by finite differences.
module Ch13.Numeric
    ( dot
    , dotTrunc
    , transpose
    , matVec
    , matMul
    , forwardDiff
    , centralDiff
    ) where

import Data.Foldable (toList)
import Data.Sequence (Seq)
import qualified Data.Sequence as Seq

-- ANCHOR: dot
-- | Dot product with an explicit length check: a size mismatch is an error,
-- not a silent wrong answer.
dot :: Num a => Seq a -> Seq a -> a
dot xs ys
    | Seq.length xs /= Seq.length ys =
        error "dot: length mismatch"
    | otherwise = sum (Seq.zipWith (*) xs ys)

-- | Dot product without the check: Seq.zipWith keeps the shorter side, so
-- a size mismatch silently produces a wrong value.
dotTrunc :: Num a => Seq a -> Seq a -> a
dotTrunc xs ys = sum (Seq.zipWith (*) xs ys)
-- ANCHOR_END: dot

-- ANCHOR: matvec
-- | Matrix-vector product: each row dotted with the vector.
matVec :: Num a => Seq (Seq a) -> Seq a -> Seq a
matVec rows x = Seq.fromList [ dot r x | r <- toList rows ]

-- | Matrix transpose.
transpose :: Seq (Seq a) -> Seq (Seq a)
transpose xs
    | Seq.null xs = Seq.empty
    | otherwise = Seq.fromList
        [ fmap (`Seq.index` j) xs
        | j <- [0 .. Seq.length (Seq.index xs 0) - 1]
        ]

-- | Matrix product A B: row i of A dotted with column j of B.
matMul :: Num a => Seq (Seq a) -> Seq (Seq a) -> Seq (Seq a)
matMul a b =
    Seq.fromList
        [ Seq.fromList [ dot r c | c <- toList (transpose b) ]
        | r <- toList a
        ]
-- ANCHOR_END: matvec

-- ANCHOR: diff
-- | Forward difference: (f (x + h) - f x) / h.
forwardDiff :: (Fractional a, Ord a) => (a -> a) -> a -> a -> a
forwardDiff f x h = (f (x + h) - f x) / h

-- | Central difference: (f (x + h) - f (x - h)) / (2h).
centralDiff :: (Fractional a, Ord a) => (a -> a) -> a -> a -> a
centralDiff f x h = (f (x + h) - f (x - h)) / (2 * h)
-- ANCHOR_END: diff
