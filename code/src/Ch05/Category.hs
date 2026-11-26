-- | Chapter 5: a tiny category written out as a table, so the axioms can be
-- checked by brute force instead of by belief.
--
-- The objects are @A, B, C@; the arrows form a chain with a shortcut:
--
-- >        AB          BC
-- >   A ------> B ------> C
-- >    \                  ^
-- >     \       AC         |
-- >      +----------------+
--
-- plus one identity on each object. That is six arrows and ten composable
-- pairs, few enough to write down and check exhaustively.
module Ch05.Category
    ( Obj (..)
    , Arrow (..)
    , src
    , tgt
    , identity
    , compose
    , composeM
    , allArrows
    , assocHolds
    , identityHolds
    , M3 (..)
    , madd
    , assocHoldsM3
    , interp
    , functorLawHolds
    , swapPair
    , swapIsIso
    , badInterp
    , badFunctorLawHolds
    ) where

-- ANCHOR: objects
data Obj = A | B | C
    deriving (Eq, Show, Enum, Bounded)
-- ANCHOR_END: objects

-- ANCHOR: arrows
-- | Six arrows: three identities, three "real" ones.
data Arrow = IdA | IdB | IdC | AB | BC | AC
    deriving (Eq, Show, Enum, Bounded)

allArrows :: [Arrow]
allArrows = [minBound .. maxBound]
-- ANCHOR_END: arrows

src :: Arrow -> Obj
src IdA = A
src IdB = B
src IdC = C
src AB   = A
src BC   = B
src AC   = A

tgt :: Arrow -> Obj
tgt IdA = A
tgt IdB = B
tgt IdC = C
tgt AB   = B
tgt BC   = C
tgt AC   = C

-- ANCHOR: identity
identity :: Obj -> Arrow
identity A = IdA
identity B = IdB
identity C = IdC
-- ANCHOR_END: identity

-- ANCHOR: compose
-- | @compose g f@ is the arrow "first @f@, then @g@", written @g . f@ in maths.
-- Returns 'Nothing' when the types do not line up.
compose :: Arrow -> Arrow -> Maybe Arrow
compose g f = lookup (g, f) table

table :: [((Arrow, Arrow), Arrow)]
table =
    [ ((IdA, IdA), IdA)
    , ((AB,   IdA), AB)
    , ((AC,   IdA), AC)
    , ((IdB, IdB), IdB)
    , ((BC,   IdB), BC)
    , ((IdC, IdC), IdC)
    , ((IdB, AB),   AB)
    , ((BC,   AB),   AC)
    , ((IdC, BC),   BC)
    , ((IdC, AC),   AC)
    ]
-- ANCHOR_END: compose

-- | Lift 'compose' to the case where either side may already have failed.
composeM :: Maybe Arrow -> Maybe Arrow -> Maybe Arrow
composeM (Just g) (Just f) = compose g f
composeM _        _        = Nothing

-- ANCHOR: assoc
-- | Associativity, checked on every triple: @(h . g) . f = h . (g . f)@.
assocHolds :: Bool
assocHolds = and
    [ composeM (compose h g) (Just f) == composeM (Just h) (compose g f)
    | h <- allArrows, g <- allArrows, f <- allArrows
    ]

-- | @1 . f = f@ and @f . 1 = f@ for every arrow @f@.
identityHolds :: Bool
identityHolds = and
    [ compose (identity (tgt f)) f == Just f
      && compose f (identity (src f)) == Just f
    | f <- allArrows
    ]
-- ANCHOR_END: assoc

-- ANCHOR: monoid
-- | The monoid @Z/3@ seen as a one-object category: one object, three arrows,
-- composition is addition modulo 3, the identity is zero.
data M3 = M0 | M1 | M2
    deriving (Eq, Show, Enum, Bounded)

madd :: M3 -> M3 -> M3
madd x y = toEnum ((fromEnum x + fromEnum y) `mod` 3)

assocHoldsM3 :: Bool
assocHoldsM3 = and
    [ madd (madd x y) z == madd x (madd y z)
    | x <- [M0 .. M2], y <- [M0 .. M2], z <- [M0 .. M2]
    ]
-- ANCHOR_END: monoid

-- ANCHOR: functor
-- | A functor from our three-object category into Hask: all three objects go
-- to 'Int', and the arrows go to functions.
interp :: Arrow -> Int -> Int
interp IdA = id
interp IdB = id
interp IdC = id
interp AB   = (+ 1)
interp BC   = (* 2)
interp AC   = (* 2) . (+ 1)

-- | Functor laws: identity is preserved, composition is preserved.
functorLawHolds :: Bool
functorLawHolds = and
    [ identityOK x && compositionOK x g f
    | g <- allArrows, f <- allArrows, x <- [-2 .. 2 :: Int]
    ]
  where
    identityOK x = and [interp (identity o) x == x | o <- [A, B, C]]
    compositionOK x g f = case compose g f of
        Nothing -> True
        Just h  -> interp h x == interp g (interp f x)
-- ANCHOR_END: functor

-- ANCHOR: iso
-- | 交换二元组：做了两次就回到原样，所以它是自逆的。
swapPair :: (a, b) -> (b, a)
swapPair (x, y) = (y, x)

-- | 同构的判据：@swapPair . swapPair = id@。
swapIsIso :: Bool
swapIsIso = and
    [ swapPair (swapPair p) == p
    | p <- [(1 :: Int, 'a'), (2, 'b'), (3, 'c')]
    ]
-- ANCHOR_END: iso

-- ANCHOR: bad-functor
-- | 一个"看起来像函子"的映射：只把 @AC@ 送错了一个函数。
badInterp :: Arrow -> Int -> Int
badInterp IdA = id
badInterp IdB = id
badInterp IdC = id
badInterp AB   = (+ 1)
badInterp BC   = (* 2)
badInterp AC   = (+ 3)   -- 错的：AC = BC . AB，应该等于 (* 2) . (+ 1)

-- | 同一套检查，作用在假函子上：返回 'False'。
badFunctorLawHolds :: Bool
badFunctorLawHolds = and
    [ case compose g f of
        Nothing -> True
        Just h  -> badInterp h x == badInterp g (badInterp f x)
    | g <- allArrows, f <- allArrows, x <- [-2 .. 2 :: Int]
    ]
-- ANCHOR_END: bad-functor
