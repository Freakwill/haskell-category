-- snippet 08 | Haskell.md:L203-L211 | lang=haskell | code-lines=7
-- 原文第 203 行是开始围栏，代码对应原文第 204-210 行
class Functor f => Applicative f where
    pure :: a -> f a   -- minimum context
    (<*>) :: f (a -> b) -> f a -> f b
    pure id <*> v = v  -- identity
    pure (.) <*> u <*> v <*> w = u <*> (v <*> w) -- compostition
    pure f <*> pure x = pure (f x)  -- homomorphism
    u <*> pure y = pure ($ y) <*> u -- interchange
