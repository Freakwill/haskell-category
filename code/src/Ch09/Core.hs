-- | Chapter 9: join, Kleisli composition, monad law checks on a finite
-- structure, and a type-correct monad that breaks the laws.
module Ch09.Core
    ( joinViaBind
    , bindViaJoin
    , compViaBind
    , bindViaComp
    , interdefinitionsHold
    , Two (..)
    , sameTwo
    , twoLawsHold
    , monadLawsOnMaybe
    , monadLawsOnList
    , BadM (..)
    , badLeftIdentityBroken
    , badAssociativityBroken
    ) where

-- ANCHOR: interdefinitions
-- | join from bind: flatten a doubly wrapped value.
joinViaBind :: Monad m => m (m a) -> m a
joinViaBind mm = mm >>= id

-- | bind from join: map f, then flatten.
bindViaJoin :: Monad m => m a -> (a -> m b) -> m b
bindViaJoin m f = joinViaBind (fmap f m)

-- | Kleisli composition from bind.
compViaBind :: Monad m => (a -> m b) -> (b -> m c) -> (a -> m c)
compViaBind f g x = f x >>= g

-- | bind from Kleisli composition: m is treated as a zero-argument source.
bindViaComp :: Monad m => m a -> (a -> m b) -> m b
bindViaComp m f = compViaBind (\() -> m) f ()
-- ANCHOR_END: interdefinitions

-- | The four definitions agree on concrete Maybe and list values.
interdefinitionsHold :: Bool
interdefinitionsHold =
    and [ joinViaBind (Just (Just 3)) == Just 3
        , joinViaBind (Just Nothing) == (Nothing :: Maybe Int)
        , bindViaJoin (Just 4) (\n -> if n > 0 then Just (n - 1) else Nothing)
            == Just 3
        , compViaBind (\n -> [n, n + 1]) (\n -> if n > 1 then [n * 10] else []) 1
            == [20]
        , bindViaComp [1, 2] (\n -> [n, n * 10]) == [1, 10, 2, 20]
        , joinViaBind [[1, 2], [3]] == [1, 2, 3]
        ]

-- ANCHOR: finite-reader
-- | The Reader monad over a two-element environment.  Function values have
-- no Eq instance, so equality is checked by running both sides on every
-- environment.
newtype Two a = Two { runTwo :: Bool -> a }

instance Functor Two where
    fmap f (Two g) = Two (f . g)

instance Applicative Two where
    pure a = Two (const a)
    Two f <*> Two g = Two (\b -> f b (g b))

instance Monad Two where
    Two g >>= k = Two (\b -> runTwo (k (g b)) b)

sameTwo :: Two Bool -> Two Bool -> Bool
sameTwo (Two f) (Two g) = f True == g True && f False == g False

-- | The three monad laws, checked exhaustively on Two: every value
-- @m :: Two Bool@ (4 of them) and every function @Bool -> Two Bool@
-- (16 of them) is tried.  A passing check is not a proof; it rejects
-- broken instances.
twoLawsHold :: Bool
twoLawsHold =
    and [ sameTwo ((m >>= f) >>= g) (m >>= (\x -> f x >>= g))
        | m <- ms, f <- fs, g <- fs ]
    && and [ sameTwo (return x >>= f) (f x)
           | x <- [False, True], f <- fs ]
    && and [ sameTwo (m >>= return) m | m <- ms ]
  where
    mk :: Bool -> Bool -> Two Bool
    mk t f = Two (\b -> if b then t else f)
    ms = [mk t f | t <- [False, True], f <- [False, True]]
    bt = [const False, const True, id, not]
    fs = [\b -> mk (t b) (f b) | t <- bt, f <- bt]
-- ANCHOR_END: finite-reader

-- ANCHOR: maybe-list-laws
-- | The three laws on one concrete Maybe assignment.
monadLawsOnMaybe :: Bool
monadLawsOnMaybe =
    and [ ((m >>= f) >>= g) == (m >>= (\x -> f x >>= g))
        , (return 3 >>= f) == f 3
        , (m >>= return) == m
        ]
  where
    m = Just 3
    f n = if n > 0 then Just (n + 1) else Nothing
    g n = if n > 3 then Just (n * 2) else Nothing

-- | The three laws on one concrete list assignment.
monadLawsOnList :: Bool
monadLawsOnList =
    and [ ((m >>= f) >>= g) == (m >>= (\x -> f x >>= g))
        , (return 1 >>= f) == f 1
        , (m >>= return) == m
        ]
  where
    m = [1, 2, 3]
    f n = [n, n + 1]
    g n = if n > 2 then [n * 10] else []
-- ANCHOR_END: maybe-list-laws

-- ANCHOR: bad-monad
-- | A type-correct Monad whose bind adds 2 * n + m + 1 to the counter.
-- The extra Int field is the escape hatch, as in Chapters 7 and 8.
data BadM a = BadM a Int
    deriving (Eq, Show)

instance Functor BadM where
    fmap f (BadM a n) = BadM (f a) n

instance Applicative BadM where
    pure a = BadM a 0
    BadM f n <*> BadM a m = BadM (f a) (n + m + 1)

instance Monad BadM where
    BadM a n >>= k =
        let BadM b m = k a
        in BadM b (2 * n + m + 1)

-- | Witness: return 1 >>= f /= f 1.
badLeftIdentityBroken :: Bool
badLeftIdentityBroken = (return 1 >>= f) /= f 1
  where
    f n = BadM (n + 1) 5

-- | Witness: (m >>= f) >>= g /= m >>= (\x -> f x >>= g).
badAssociativityBroken :: Bool
badAssociativityBroken =
    ((m >>= f) >>= g) /= (m >>= (\x -> f x >>= g))
  where
    m = BadM 7 3
    f n = BadM (n + 1) 0
    g n = BadM (n * 2) 0
-- ANCHOR_END: bad-monad
