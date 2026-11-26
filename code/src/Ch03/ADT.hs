-- | Chapter 3 examples: algebraic data types, their eliminators, and the
-- difference between a decision procedure for equality and an identity type.
module Ch03.ADT
    ( Nat (..)
    , natRec
    , toInt
    , plus
    , times
    , Shape (..)
    , area
    , perimeter
    , Pair (..)
    , swap
    , boolRec
    , maybeRec
    , eitherRec
    ) where

-- ANCHOR: nat
-- | 自然数：两个构造子，一个无参数，一个带递归参数。
data Nat = Zero | Succ Nat
    deriving (Eq, Show)
-- ANCHOR_END: nat

-- ANCHOR: natRec
-- | Nat 的消去规则（递归子）：给定基值与后继步骤，把任意 Nat 归约成 a。
natRec :: a -> (a -> a) -> Nat -> a
natRec z _ Zero     = z
natRec z s (Succ n) = s (natRec z s n)
-- ANCHOR_END: natRec

-- ANCHOR: arith
toInt :: Nat -> Int
toInt = natRec 0 (+ 1)

plus :: Nat -> Nat -> Nat
plus m = natRec m Succ

times :: Nat -> Nat -> Nat
times m = natRec Zero (plus m)
-- ANCHOR_END: arith

-- ANCHOR: sum-product
-- | 和类型（两种形状）套在积类型（每个构造子的字段）上。
data Shape = Circle Double | Rect Double Double
    deriving (Eq, Show)

area :: Shape -> Double
area (Circle r) = pi * r * r
area (Rect w h) = w * h

perimeter :: Shape -> Double
perimeter (Circle r) = 2 * pi * r
perimeter (Rect w h) = 2 * (w + h)
-- ANCHOR_END: sum-product

-- ANCHOR: pair
-- | 积类型：一个构造子，两个字段。
data Pair a b = Pair a b
    deriving (Eq, Show)

swap :: Pair a b -> Pair b a
swap (Pair x y) = Pair y x
-- ANCHOR_END: pair

-- ANCHOR: since
-- | 和类型的分情况消去，在标准库里分别叫 bool、maybe、either。
boolRec :: a -> a -> Bool -> a
boolRec t _ True  = t
boolRec _ f False = f

maybeRec :: b -> (a -> b) -> Maybe a -> b
maybeRec d _ Nothing  = d
maybeRec _ f (Just x) = f x

eitherRec :: (a -> c) -> (b -> c) -> Either a b -> c
eitherRec f _ (Left a)  = f a
eitherRec _ g (Right b) = g b
-- ANCHOR_END: since
