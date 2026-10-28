-- snippet 16 | Haskell.md:L429-L478 | lang=haskell | code-lines=48
-- 原文第 429 行是开始围栏，代码对应原文第 430-477 行
sequence :: t (m a) -> m (t a)  -- 类型转换
-- t = []
sequence [] = return []
sequence a:as = a >>= \x -> ((\l -> x:l) <$> sequence as) -- 类似于 Descartes 积

sequence :: t (m a) -> m () -- Kleisli 连乘
sequence_ [] = return ()
sequence_ a:as = a >> sequence_ as

mapM = sequence . map :: (a -> m b) -> [a] -> m [b]
mapM_ = sequence_ . map :: (a -> m b) -> [a] -> m ()

forM = flip mapM :: [a] -> (a -> m b) -> m [b] -- 模拟 for 循环
forM_ = flip mapM_

main = forM_ [5..10] $ \n -> do
    putStrLn $ "Solutions for queen" ++ (show n) ++ " problem:"
    forM_ (queensN n) $ print

replicateM :: Int -> m a -> m [a]
replicateM_ :: Int -> m a -> m ()

-- m: s -> a , s
sequence_ [m1, m2, ....] ~ m1'm2'.... :: s -> (), s
replicateM_ n m = m ^ n :: s -> (), s
sequence [m1, m2, ....] ~ m1'm2'.... :: s -> [....], s


forever :: m a -> m b -- sequence . repeat

main = forever $ do
    input <- getLine
    putStrLn $ answer input

filterM :: (a -> m Bool) -> [a] -> m [a]

foldM :: (b -> a -> m b) -> b -> t a -> m b
-- do
-- b1 <- f(b, a0)
-- b2 <- f(b1, a1)
-- ...
-- f(bn, an)
-- == (f(a0)*f(a1)*f(a2)...f(an))(b)

-- example

\m -> mapM . (const m) :: m b -> [a] -> m [b]

