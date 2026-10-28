-- snippet 20 | Haskell.md:L599-L602 | lang=haskell | code-lines=2
-- 原文第 599 行是开始围栏，代码对应原文第 600-601 行
newListArray :: Ix i => (i, i) -> [e] -> ST s (STArray s i e)
getElems :: STArray s i e -> ST s [e]
