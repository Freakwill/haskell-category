# 代码块静态诊断（P0，本轮不编译）

判定口径：只读源码做一次静态判断，**没有逐个调用 GHC**。四类基本判定为「语法明显错误 / 缺导入 / 伪代码 / 疑似可编译」；凡能解析但过不了类型检查的，单列「类型错误」（四类之外的补充）。

依据文件：`snippets/_report.csv` 与 `snippets/NN-lang.hs`（文件头注释记录了原文行号区间）。

| # | 文件 | 原文行 | 判定 | 一句话理由 |
|---|------|--------|------|------------|
| 1 | 01-haskell.hs | 31–53 | 疑似可编译 | `Main.hs` 结构完整（module + import Data.List + 定义 + main），仅 `foo` 用自定义递归实现 `nub`。 |
| 2 | 02-lua.hs | 73–80 | 疑似可编译（标签错误） | 围栏标了 `lua`，内容其实是合法 Haskell：`comment`/`main` 都是普通函数，可以直接在 GHCi 或 `runghc` 下跑。 |
| 3 | 03-haskell.hs | 106–109 | 语法明显错误 | `MakeDrug "wtf" :: Drug` 是裸表达式，放在模块顶层无法解析；在 GHCi 里才合法。 |
| 4 | 04-haskell.hs | 115–124 | 语法明显错误 | `newtype Transform a = Transform （a->a）` 用了全角括号（已由 CSV 的 `是(全角括号)` 标出），且 `Function1D` 先作零参别名再作一参别名，属重复定义。 |
| 5 | 05-haskell.hs | 146–150 | 语法明显错误 | 重定义 Prelude 的 `Maybe`，后面两行 `Just 3 :: Maybe Int` 又是裸表达式，都只能存在于 GHCi 会话。 |
| 6 | 06-haskell.hs | 161–165 | 类型错误 | 签名写 `Int -> Int -> Maybe Int`，实现用 `/`，而 `Int` 不是 `Fractional`；应改 `div` 或 `fromIntegral`。 |
| 7 | 07-haskell.hs | 173–193 | 语法明显错误 | 重新定义 `<$>`/`<$`/`*>` 却未 `import Prelude hiding`，且 `x *> y = (id <$ x) <*> y = ...` 一行两个 `=`，无法解析。 |
| 8 | 08-haskell.hs | 203–211 | 语法明显错误 | 类体里直接写 `pure id <*> v = v` 这类法则等式，没有方法名，class 声明不允许裸表达式。 |
| 9 | 09-haskell.hs | 243–249 | 伪代码 | 四行注释 + 一行 `f2 <*> f1 = \x -> f2 x $ f1 x`，用二元中缀模式定义 `<*>`，参数个数不对；`f1`/`f2` 也无来源。 |
| 10 | 10-haskell.hs | 273–278 | 缺导入 | `instance Monoid a => Applicative (Const a)` 用到 `Const`/`mempty`/`<>`，缺 `Data.Functor.Const` 与 `Data.Monoid`/`Data.Semigroup` 导入。 |
| 11 | 11-haskell.hs | 288–317 | 伪代码 | 顶层 `mempty = []`、`mappend = ++` 属重绑定，两个 `instance ... where` 里只有 `...` 占位，`mzero`/`mplus` 在类体里既无签名也无实现。 |
| 12 | 12-haskell.hs | 321–326 | 语法明显错误 | `newtype Ziplist = ZipList (getZipList :: [a])` 把字段名当成位置构造的参数用，`a` 也未在左侧绑定；名字拼写还与 `ZipList` 不一致。 |
| 13 | 13-haskell.hs | 336–368 | 语法明显错误 | 类体混入 `bind f = ...`（无签名、非方法）、GHCi 提示符 `Prelude Control.Monad>` 及其输出、以及 `when/until/void` 这行自然语言。 |
| 14 | 14-haskell.hs | 384–392 | 伪代码 | `List, join = concat` 是「类型—注释」式的说明，`r ->, join: ...` 不是 Haskell 语法，只有 `join f = \x -> f x x` 一行像真代码。 |
| 15 | 15-haskell.hs | 404–423 | 语法明显错误 | `count = ... = ...` 一行两个 `=`；`getLin` 是 `getLine` 的笔误；`main` 定义了三次；`do {...} == ...` 是裸表达式。 |
| 16 | 16-haskell.hs | 429–478 | 语法明显错误 | `sequence` 两次带不同签名、`sequence a:as = ...` 缺括号、`....` 是省略号占位，还引用了未定义的 `queensN`/`answer`。 |
| 17 | 17-haskell.hs | 490–512 | 语法明显错误 | 记录字段写成 `{runState: s -> (a, s)}`（应为 `::`），且 `newtype State a s` 的参数顺序与 `instance Functor (State s)` 矛盾。 |
| 18 | 18-haskell.hs | 524–565 | 伪代码 | 同名 `putStrLn'`/`getLine'` 各有两套签名，`???` 与 `appendFile :: ...`、`data IORef a = ...` 是占位符，不是可编译代码。 |
| 19 | 19-haskell.hs | 573–593 | 缺导入 | 用了 `ST`/`STRef`/`newSTRef` 却没 `import Control.Monad.ST` 与 `Data.STRef`，`repeatFor`、`modifySTRef` 也缺定义。 |
| 20 | 20-haskell.hs | 599–602 | 缺导入 | 只有两行签名，`STArray`/`Ix` 需要 `Data.Array.ST` 与 `Data.Ix`；没有实现体，最多算接口摘要。 |
| 21 | 21-haskell.hs | 608–656 | 语法明显错误 | `renderGreeting = gather <$> headT <*> bodyT <*> where` 里 `where` 位置非法且 `gather` 三参对两参；`Greet`/`Great` 拼写不一，`fmap` 那行有两个 `=`。 |
| 22 | 22-haskell.hs | 670–674 | 伪代码 | `f a = (m, a)` 中 `m` 未绑定，`(x, a) >>= f = (xf1(a), f2(a))` 引用了不存在的 `xf1`/`f2`，只是半群作用的示意。 |
| 23 | 23-haskell.hs | 684–686 | 伪代码 | 仅一行 `f a = a->(m, a)`，是「半群 State 单子」的示意图，不能单独成模块。 |

## 汇总（按判定计数，合计 23）

- 疑似可编译：2（#1、#2；其中 #2 围栏标签 `lua` 应为 `haskell`）
- 语法明显错误：11（#3、#4、#5、#7、#8、#12、#13、#15、#16、#17、#21）
- 类型错误：1（#6）
- 缺导入：3（#10、#19、#20；#20 同时还只有签名没有实现）
- 伪代码：6（#9、#11、#14、#18、#22、#23）

2 + 11 + 1 + 3 + 6 = 23，与 `_report.csv` 的块数一致。

## 下一步（P1，未做）

1. 只对「疑似可编译」的 #1、#2 做真实编译，确认后转成 `code/src/` 下的模块。
2. 对「语法明显错误」的 12 块逐条定位最小修复点，写成 errata 清单交给正文作者，而不是在脚手架里改代码。
3. 其余块在正文里加 `<!-- no-compile: 伪代码 -->` 标记，抽取脚本据此跳过编译流水线。
