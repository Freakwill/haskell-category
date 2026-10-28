-- snippet 22 | Haskell.md:L670-L674 | lang=haskell | code-lines=3
-- 原文第 670 行是开始围栏，代码对应原文第 671-673 行
f a = (m, a)
(x, a) >>= f = (xf1(a), f2(a))

