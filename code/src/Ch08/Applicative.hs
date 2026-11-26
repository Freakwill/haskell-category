-- | Chapter 8: applicative functors and the instance tour.
module Ch08.Applicative
    ( addMaybeManual
    , addMaybe
    , tripleMaybe
    , applicativeLawsOnMaybe
    , BadAp (..)
    , badIdentityBroken
    , badCompositionBroken
    , pairMaybe
    , failMaybe
    , grid
    , zipPair
    , askBoth
    , constSum
    , Validation (..)
    , checkAge
    , checkName
    , validatePerson
    ) where

import Control.Applicative (ZipList (..))
import Data.Functor.Const  (Const (..))
import Data.Monoid         (Sum (..))

-- ANCHOR: motivation
-- | Adding two Maybe Int by hand: the same Nothing check twice.
addMaybeManual :: Maybe Int -> Maybe Int -> Maybe Int
addMaybeManual mx my =
    case mx of
        Nothing  -> Nothing
        Just x   -> case my of
            Nothing -> Nothing
            Just y  -> Just (x + y)
-- ANCHOR_END: motivation

-- ANCHOR: applicative-use
-- | The same addition via <$> and <*>: the failure check is written once.
addMaybe :: Maybe Int -> Maybe Int -> Maybe Int
addMaybe mx my = (+) <$> mx <*> my

tripleMaybe :: Maybe Int -> Maybe Int -> Maybe Int -> Maybe (Int, Int, Int)
tripleMaybe mx my mz = (,,) <$> mx <*> my <*> mz
-- ANCHOR_END: applicative-use

-- ANCHOR: laws
-- | The four Applicative laws, checked on one concrete assignment.
-- A passing check is not a proof; it rejects broken instances.
applicativeLawsOnMaybe :: Bool
applicativeLawsOnMaybe =
    and [ (pure id <*> z) == z                              -- identity
        , (pure (.) <*> u <*> v <*> w) == (u <*> (v <*> w)) -- composition
        , ((pure f <*> pure x) :: Maybe Int) == pure (f x)   -- homomorphism
        , (u <*> pure y) == (pure ($ y) <*> u)              -- interchange
        ]
  where
    u = Just (+ 1)   :: Maybe (Int -> Int)
    v = Just (* 2)   :: Maybe (Int -> Int)
    w = Just 5       :: Maybe Int
    z = Just 7       :: Maybe Int
    f = (+ 1)        :: Int -> Int
    x = 3
    y = 4
-- ANCHOR_END: laws

-- ANCHOR: bad-instance
-- | A type-correct Applicative that breaks identity, homomorphism and
-- composition.  The extra Int field is the escape hatch, as in Chapter 7.
data BadAp a = BadAp a Int
    deriving (Eq, Show)

instance Functor BadAp where
    fmap f (BadAp x n) = BadAp (f x) n

instance Applicative BadAp where
    pure x = BadAp x 0
    BadAp f n <*> BadAp x m = BadAp (f x) (n + m + 1)

-- | Witness: pure id <*> v /= v.
badIdentityBroken :: Bool
badIdentityBroken = (pure id <*> BadAp 1 0) /= BadAp 1 0

-- | Witness: pure (.) <*> u <*> v <*> w /= u <*> (v <*> w).
badCompositionBroken :: Bool
badCompositionBroken =
    let u = BadAp (+ 1) 0 :: BadAp (Int -> Int)
        v = BadAp (* 2) 0 :: BadAp (Int -> Int)
        w = BadAp 7     0 :: BadAp Int
    in (pure (.) <*> u <*> v <*> w) /= (u <*> (v <*> w))
-- ANCHOR_END: bad-instance

-- ANCHOR: maybe-instance
-- | Maybe: Nothing propagates, Just combines.
pairMaybe :: Maybe (Int, Char)
pairMaybe = (,) <$> Just 1 <*> Just 'a'

failMaybe :: Maybe Int
failMaybe = (+) <$> Just 1 <*> Nothing
-- ANCHOR_END: maybe-instance

-- ANCHOR: list-instance
-- | List: cartesian product, not zip.
grid :: [(Int, Char)]
grid = (,) <$> [1, 2] <*> ['a', 'b']
-- ANCHOR_END: list-instance

-- ANCHOR: zip-list
-- | ZipList: pairing truncates to the shorter list; pure is repeat.
zipPair :: [(Int, Char)]
zipPair = getZipList ((,) <$> ZipList [1, 2, 3] <*> ZipList "ab")
-- ANCHOR_END: zip-list

-- ANCHOR: reader-instance
-- | The function instance shares the environment between both sides.
askBoth :: Int -> (Int, Int)
askBoth = (,) <$> (+ 1) <*> (* 2)
-- ANCHOR_END: reader-instance

-- ANCHOR: const-instance
-- | Const m accumulates the monoid and ignores the values.
constSum :: Sum Int
constSum = getConst (Const (Sum 3) <*> Const (Sum 4))
-- ANCHOR_END: const-instance

-- ANCHOR: validation
-- | Validation collects every failed check instead of stopping early.
data Validation err a
    = Failure [err]
    | Success a
    deriving (Eq, Show)

instance Functor (Validation err) where
    fmap _ (Failure es) = Failure es
    fmap f (Success a)  = Success (f a)

instance Applicative (Validation err) where
    pure = Success
    Success f <*> Success a   = Success (f a)
    Failure es <*> Success _  = Failure es
    Success _ <*> Failure es  = Failure es
    Failure es <*> Failure fs = Failure (es ++ fs)

checkAge :: Int -> Validation String Int
checkAge n
    | n < 0     = Failure ["age is negative"]
    | n > 150   = Failure ["age too large"]
    | otherwise = Success n

checkName :: String -> Validation String String
checkName s
    | null s    = Failure ["name is empty"]
    | otherwise = Success s

-- | Two checks that both fail: both error strings are reported.
validatePerson :: Validation String (Int, String)
validatePerson = (,) <$> checkAge 200 <*> checkName ""
-- ANCHOR_END: validation
