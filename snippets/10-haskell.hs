-- snippet 10 | Haskell.md:L273-L278 | lang=haskell | code-lines=4
-- 原文第 273 行是开始围栏，代码对应原文第 274-277 行
-- Const a
instance Monoid a => Applicative (Const a) where
    pure _ = Const mempty :: Const a
    (Const x) <*> (Const y) = (Const x <> y)
