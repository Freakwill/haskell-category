-- snippet 02 | Haskell.md:L73-L80 | lang=lua | code-lines=6
-- 原文第 73 行是开始围栏，代码对应原文第 74-79 行
comment :: String -> IO ()
comment s = return ()
main :: IO ()
main = do
    comment "print Hello World"
    putStrLn "Hello World"
