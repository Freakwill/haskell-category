-- snippet 13 | Haskell.md:L336-L368 | lang=haskell | code-lines=31
-- 原文第 336 行是开始围栏，代码对应原文第 337-367 行
class Monad m where  
    return :: a -> m a  -- pure
    join :: m (m a) -> m a -- bind function

    (>>=) :: m a -> (a -> m b) -> m b
    x >>= f = join $ fmap f x
    
    bind f = join . (fmap f)

    (>>) :: m a -> m b -> m b  
    x >> y = x >>= \_ -> y  -- mempty >>= f

    fail :: String -> m a  
    fail msg = error msg  
    
(<=<) :: (Monad m) => (b -> m c) -> (a -> m b) -> (a -> m c)  
f <=< g = (\x -> g x >>= f)  -- g >=> f

f <*> x = join $ fmap (\f -> fmap f x) f -- f>>= (\f -> f <$> x)

-- example
-- guard : true|->[()], false|->[]
Prelude Control.Monad> [1..50] >>= (\x -> guard ('7' `elem` show x) >> return x)   
[7,17,27,37,47]  
Prelude Control.Monad> do { x <- [1..50]; guard ('7' `elem` show x); return x }  
[7,17,27,37,47]  
Prelude Control.Monad> [ x | x <- [1..50], '7' `elem` show x ]  
[7,17,27,37,47] 

-- Control.Monad
when/until/void
