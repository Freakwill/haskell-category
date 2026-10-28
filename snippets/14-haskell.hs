-- snippet 14 | Haskell.md:L384-L392 | lang=haskell | code-lines=7
-- 原文第 384 行是开始围栏，代码对应原文第 385-391 行
List, join = concat
Maybe, join: Maybe Maybe a -> Maybe a

r ->, join: (r -> r -> a) -> (r -> a)
join f = \x -> f x x

x >>= f = \t -> f(x(t), t)
