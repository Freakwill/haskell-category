-- | Chapter 7: functors, natural transformations, and their laws.
module Ch07.Functor
    ( Tree (..)
    , addOneMaybe
    , addOneList
    , mapTree
    , treeIdentityOn
    , treeCompositionOn
    , maybeToList
    , naturalMaybeToListOn
    , inspectMaybe
    , Weird (..)
    , weirdIdentityBroken
    , weirdCompositionBroken
    , Mod2 (..)
    , mod2CompositionHolds
    , mod2IdentityBroken
    ) where

-- ANCHOR: motivation
-- | Two hand-written versions of "add one to every element".  The only
-- part that changes between them is @(+ 1)@; the shape repeats.
addOneMaybe :: Maybe Int -> Maybe Int
addOneMaybe Nothing  = Nothing
addOneMaybe (Just x) = Just (x + 1)

addOneList :: [Int] -> [Int]
addOneList []     = []
addOneList (x:xs) = (x + 1) : addOneList xs
-- ANCHOR_END: motivation

-- ANCHOR: tree
-- | A recursive shape whose Functor instance acts only on stored values.
data Tree a
    = Leaf a
    | Branch (Tree a) (Tree a)
    deriving (Eq, Show)

instance Functor Tree where
    fmap f (Leaf x)     = Leaf (f x)
    fmap f (Branch l r) = Branch (fmap f l) (fmap f r)
-- ANCHOR_END: tree

-- ANCHOR: map-tree
mapTree :: (a -> b) -> Tree a -> Tree b
mapTree = fmap
-- ANCHOR_END: map-tree

-- ANCHOR: functor-laws
-- | Checking the two Functor laws on a finite test set cannot prove them,
-- but it rejects a bad implementation.
treeIdentityOn :: [Tree Int] -> Bool
treeIdentityOn = all (\t -> fmap id t == t)

treeCompositionOn :: (Int -> Int) -> (Int -> Int) -> [Tree Int] -> Bool
treeCompositionOn f g = all (\t -> fmap (f . g) t == (fmap f . fmap g) t)
-- ANCHOR_END: functor-laws

-- ANCHOR: maybe-to-list
-- | A polymorphic map from Maybe to lists.  It preserves the shape of a
-- value while changing its outer constructor.
maybeToList :: Maybe a -> [a]
maybeToList Nothing  = []
maybeToList (Just x) = [x]
-- ANCHOR_END: maybe-to-list

-- ANCHOR: naturality
-- | Naturality says that mapping f before or after maybeToList agrees.
naturalMaybeToListOn :: (Int -> Int) -> [Maybe Int] -> Bool
naturalMaybeToListOn f = all (\mx -> maybeToList (fmap f mx) == fmap f (maybeToList mx))
-- ANCHOR_END: naturality

-- ANCHOR: non-natural
-- | This function inspects Int values.  Its type resembles maybeToList's,
-- but it is not polymorphic and therefore need not be natural.
inspectMaybe :: Maybe Int -> [Int]
inspectMaybe Nothing  = []
inspectMaybe (Just x)
    | x < 0     = []
    | otherwise = [x]
-- ANCHOR_END: non-natural

-- ANCHOR: weird
-- | A Functor instance that type-checks but breaks both laws.  The extra
-- Int component is the escape hatch: it lets the instance change data of
-- a type other than the parameter.
data Weird a = Weird a Int
    deriving (Eq, Show)

instance Functor Weird where
    fmap f (Weird x n) = Weird (f x) (n + 1)

-- | Witness: the identity law fails on this instance.
weirdIdentityBroken :: Bool
weirdIdentityBroken = fmap id (Weird 1 0) /= Weird 1 0

-- | Witness: the composition law also fails on this instance.
weirdCompositionBroken :: Bool
weirdCompositionBroken =
    let f = (+ 1)
        g = (* 2)
    in fmap (g . f) (Weird 1 0) /= (fmap g . fmap f) (Weird 1 0)
-- ANCHOR_END: weird

-- ANCHOR: mod2
-- | Composition holds but identity fails: the two laws are independent.
data Mod2 a = Mod2 a Int
    deriving (Eq, Show)

instance Functor Mod2 where
    fmap f (Mod2 x n) = Mod2 (f x) (n `mod` 2)

-- | Witness: the composition law holds on a concrete pair of functions.
mod2CompositionHolds :: Bool
mod2CompositionHolds =
    let f = (+ 1)
        g = (* 2)
        xs = [Mod2 1 0, Mod2 2 7, Mod2 3 4]
    in all (\x -> fmap (g . f) x == (fmap g . fmap f) x) xs

-- | Witness: the identity law fails.
mod2IdentityBroken :: Bool
mod2IdentityBroken = fmap id (Mod2 1 2) /= Mod2 1 2
-- ANCHOR_END: mod2
