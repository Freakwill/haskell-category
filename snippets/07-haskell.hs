-- snippet 07 | Haskell.md:L173-L193 | lang=haskell | code-lines=19
-- 原文第 173 行是开始围栏，代码对应原文第 174-192 行
<$> :: (a -> b) -> f a -> f b
f <$> x = fmap f x  -- (= (pure f) <*> x)
<$ :: b -> f a -> f b
<$ = fmap . const  -- a <$ x = fmap (const a) x, x $> a

*> :: Applicative f => f a -> f b -> f b
x *> y = (id <$ x) <*> y = (\_ -> id) <$> x <*> y -- y <* x
{-
f a = c -> a, -- F = Hom(c, .)
x *> y = y

f a = [a]
x *> y = y ++ y ++ ... ++ y
-}
-- example
replicate <$> Just 1 *> Just (+1) <*> Just 1234
-- > 

-- listAx
