-- snippet 06 | Haskell.md:L161-L165 | lang=haskell | code-lines=3
-- 原文第 161 行是开始围栏，代码对应原文第 162-164 行
divide :: Int -> Int -> Maybe Int
divide x 0 = Nothing
divide x y = x/y
