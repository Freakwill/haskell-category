-- snippet 01 | Haskell.md:L31-L53 | lang=haskell | code-lines=21
-- 原文第 31 行是开始围栏，代码对应原文第 32-52 行
-- Main.hs
module Main where  -- module 名(和文件名一致)，module, where 是关键字

import Data.List  -- 导入模块，以便调用nub函数

{-这是多行注释：
下面是模块内容，定义函数，调用函数
函数调用采用s表达式。与Lisp不同，不建议写最后一个括号。
-}

-- 自定义函数，下一节详细介绍函数定义语法
-- foo的功能和nub一样, 去除重复元素（只适用于字符串），但结果可能不同，因为删除的重复元素位置不一样。
foo :: String -> String
foo [] = []
foo (a:as) = if (elem a as) then (foo as) else (a:(foo as))


main :: IO ()   -- 入口函数
main = do   -- 有多个打印语句，就要写上do
    print (foo "Hello World") -- 调用自定义函数
    print (nub [1,2,3,2,3])  -- nub 是Data.List定义的函数
