-- snippet 19 | Haskell.md:L573-L593 | lang=haskell | code-lines=19
-- 原文第 573 行是开始围栏，代码对应原文第 574-592 行
newtype ST s a = ST (STRef s a)
type STRef s a = State# s -> (# State# s, a #)
-- newtype ST s a = ST (s -> (s, a))

newSTRef :: a -> ST s (STRef s a)
readSTRef :: STRef s a -> ST s a
writeSTRef :: STRef s a -> a -> ST s ()
modifySTRef

-- example
fib :: Int -> ST s Integral
fib n = do {a <- newSTRef 0;
            b <- newSTRef 1;
            repeatFor n
            (do {x <- readSTRef a;
                y <- readSTRef b;
                writeSTRef a y;
                writeSTRef b $! (x+y)});
            readSTRef a}
