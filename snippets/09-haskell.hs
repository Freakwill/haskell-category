-- snippet 09 | Haskell.md:L243-L249 | lang=haskell | code-lines=5
-- 原文第 243 行是开始围栏，代码对应原文第 244-248 行
-- List [a]
-- f <*> a = [f[i](a[i]), i]
-- c -> a
f2 <*> f1 = \x -> f2 x $ f1 x
-- const id <*> f1 == f1
