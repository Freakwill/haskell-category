-- snippet 12 | Haskell.md:L321-L326 | lang=haskell | code-lines=4
-- 原文第 321 行是开始围栏，代码对应原文第 322-325 行
newtype Ziplist = ZipList (getZipList :: [a])
instance Applicative ZipList where
    pure x = ZipList (repeat x)
    ZipList fs <*> ZipList xs = ZipList (zipWith ($) fs xs)
