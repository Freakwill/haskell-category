-- snippet 15 | Haskell.md:L404-L423 | lang=haskell | code-lines=18
-- 原文第 404 行是开始围栏，代码对应原文第 405-422 行
count:: Int
count = sum $ [1..10] >>= (\x -> [x..10] >>= \_ -> return 1)
      = sum $ [1..10] >>= (\x -> [x..10]) >> [1]
count = sum $ do
    x <- [1..10]
    _ <- [x..10]
    return 1

getLine :: IO String
putStrLn :: String -> IO ()
main :: IO ()
main = getLin >>= putStrLn
main = do
    line <- getLine
    putStrLn line

do {x<-s; y<-t; g} == s >>= \x -> (t >>= \y->g) == s >>= ((\x -> t) >=> g)
do {s; t; g} == s >> t >> g
