-- snippet 11 | Haskell.md:L288-L317 | lang=haskell | code-lines=28
-- 原文第 288 行是开始围栏，代码对应原文第 289-316 行
-- Monoid a => [a]
mempty = []
mappend = ++

-- Monoid a => Maybe a
empty = Nothing
Nothing <> x = x <> Nothing = x
Just x <> Just y = Just (x <> y)

-- Alternative
class Applicative f => Alternative f where
    empty :: f a
    <|> :: f a -> f a -> f a

instance Alternative [] where
 ...
 
instance Alternative Maybe where
 ...
 
asum :: (Foldable t, Alternative f) => t (f a) -> f a  
asum = foldr (<|>) empty 

class (Alternative m, Monad m) => MonadPlus m where
   mzero :: m a
   mzero = empty
   mplus :: m a -> m a -> m a
   mplus = (<|>)
