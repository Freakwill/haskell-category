-- snippet 05 | Haskell.md:L146-L150 | lang=haskell | code-lines=3
-- 原文第 146 行是开始围栏，代码对应原文第 147-149 行
data Maybe a = Just a | Nothing -- 必须有 Just, 作为构造函子，尽管数学上好像没有什么作用。
Just 3 :: Maybe Int
Just "Hello" :: Maybe String
