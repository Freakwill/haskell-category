-- snippet 17 | Haskell.md:L490-L512 | lang=haskell | code-lines=21
-- 原文第 490 行是开始围栏，代码对应原文第 491-511 行
newtype State a s = State {runState: s -> (a, s)}
instance Functor (State s) where
    fmap f fs = State $ \s -> let (a, s') = runState fs s in (f a, s')
    -- (f(a), s'), (a, s') = fs(s)
    
instance Monad (State s) where
    return x = State $ \s -> (x, s)
    fa >>= f = State $ \s -> let (a, s') = runState fa s in (runState (f a) s')
    -- f(a)(s'), (a, s') = fa(s)
    -- do {b <- fa; f b}

    fa >> f == State $ \s -> let (a, s') = runState fa s in (runState f s')
    -- f(s'), (a, s') = fa(s) -- 不利用fa的输出
    -- f . fa_2

get = State $ \s -> (s, s)  -- 获取当前状态，不做改变
put :: s -> State s ()  -- 输入状态，无输出
put s = State $ \_ -> ((), s)
modify f = State $ \s -> ((), f s) -- 无输出的状态迁移

fa >> put s = State $ \s -> ((), fa_1 s) = modify fa_1
