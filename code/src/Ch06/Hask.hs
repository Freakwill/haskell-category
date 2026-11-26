-- | Chapter 6: Hask, and why it is only approximately a category.
module Ch06.Hask
    ( lawsHoldOn
    , etaCounterexample
    , absurdFromBottom
    ) where

import Control.Exception (SomeException, evaluate, try)
import Data.Either (isRight)
import Data.Void (Void)

-- ANCHOR: laws
-- 三条定律在具体函数与具体输入上核对：结合律、左单位、右单位。
lawsHoldOn :: (Int -> Int) -> (Int -> Int) -> (Int -> Int) -> [Int] -> Bool
lawsHoldOn f g h xs =
    all (\x -> (f . (g . h)) x == ((f . g) . h) x) xs
        && all (\x -> (id . f) x == f x) xs
        && all (\x -> (f . id) x == f x) xs
-- ANCHOR_END: laws

-- ANCHOR: eta
-- 取 f = ⊥。(id . f) 是一个 λ，求值到 WHNF 不会失败；f 本身是 ⊥，seq 会失败。
-- 于是左单位律 id . f = f 在 seq 可观测的意义下不成立。
etaCounterexample :: IO (Bool, Bool)
etaCounterexample = do
    composed <- try (evaluate (seq (id . (undefined :: Int -> Int)) ()))
        :: IO (Either SomeException ())
    bare     <- try (evaluate (seq (undefined :: Int -> Int) ()))
        :: IO (Either SomeException ())
    pure (isRight composed, isRight bare)
-- ANCHOR_END: eta

-- ANCHOR: void
-- 若只计全函数，Void -> a 是空集；在 Hask 里它非空，⊥ 就是它的元素。
absurdFromBottom :: Void -> a
absurdFromBottom = undefined
-- ANCHOR_END: void
