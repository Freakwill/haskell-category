# 第 2 章 函数与Lambda演算

> 状态：试写稿 ｜ 目标 1.3 万字 ｜ 代码：`code/src/Ch02/Functions.hs`

第 1 章末尾指出，Haskell 没有循环语句，重复计算由递归完成。本章处理两件事：如何写递归，
以及如何把递归中"变化的部分"提取为参数——后者给出 `map`、`filter`、`foldr` 这类高阶函数。
另一件事是参数逐个给出的机制，即 Curry 化，它是第 8 章的前提。

## 2.1 问题：三个循环

给定四行成绩：

```haskell
{{#include ../code/src/Ch02/Functions.hs:scores}}
```

需要做三件事：筛出及格的记录、取出姓名、把分数相加。

Python 中对应的写法是三个函数，每个含一个 `for` 循环：

```python
def passed(scores):
    out = []
    for name, score in scores:
        if score >= 60:
            out.append((name, score))
    return out


def names(rows):
    out = []
    for name, _ in rows:
        out.append(name)
    return out


def total(rows):
    s = 0
    for _, score in rows:
        s += score
    return s
```

三段代码结构相同：建立一个空结果，遍历，处理每个元素，追加到结果。不同之处只有两点——
对每个元素做什么，以及结果如何累积。

变化的两点被埋在循环体里，因此每增加一个需求就要复制一遍骨架。Haskell 的做法是保留骨架，
把这两点变成参数。

## 2.2 递归

### 2.2.1 列表的归纳结构与递归

Haskell 的列表只有两种形式：`[]`，或一个元素接一条尾巴 `x : xs`。这是类型的定义，不是
修辞：

```haskell
data [] a = [] | a : [a]
```

（`base` 中的实际定义在名字上略有出入，形式相同。）

因此列表上的函数通常写成两个方程：一个处理空列表，一个处理非空列表。这称为**递归**
（recursion）：函数在自己的定义里调用自己，每次调用处理更小的一部分输入。

```haskell
{{#include ../code/src/Ch02/Functions.hs:total}}
```

`total [1,2,3]` 的展开：

```
total (1 : 2 : 3 : [])
= 1 + total (2 : 3 : [])
= 1 + (2 + total (3 : []))
= 1 + (2 + (3 + 0))
= 6
```

每一步都只是代入定义。这里没有循环变量，也没有迭代状态；代码是等式，展开是等式的推论。

### 2.2.2 三个函数，一个骨架

映射与过滤使用同一形式：

```haskell
{{#include ../code/src/Ch02/Functions.hs:double}}
```

```haskell
{{#include ../code/src/Ch02/Functions.hs:evens}}
```

三个函数只有两处不同：空列表的返回值（`0`、`[]`、`[]`），以及非空列表时如何把 `x` 与
"尾巴的结果"合并（`+`、配合 `2 *` 的 `:`、以及 `if` 判断）。

递归函数需要确定三件事：空列表的处理、非空列表的处理、以及每一步如何合并当前元素与递归结果。
展开的深度由运行时决定。

### 2.2.3 guard 与 where

`if` 只能二选一，适用于 `evens` 这类情形。分支增多时，应使用 guard：

```haskell
{{#include ../code/src/Ch02/Functions.hs:guard}}
```

`|` 之后是条件，自上而下匹配，取第一个成立的分支；`otherwise` 为 `True`，用作兜底。与模式匹配
相同，**顺序决定语义**：若把 `n >= 60` 写在最前，90 分也会返回 "C"。

局部值用 `where` 定义：

```haskell
{{#include ../code/src/Ch02/Functions.hs:where}}
```

`lo`、`hi`、`width` 各写一次，函数体中直接引用。等价的形式是 `let ... in ...`，区别在作用域：
`where` 依附于方程，可以引用模式匹配出的变量；`let` 是表达式，可出现在任何位置。
一般的用法是：函数级共享用 `where`，表达式内部的临时绑定用 `let`。

`width = max 1 (hi - lo)` 处理了边界情况：所有分数相同时 `hi - lo` 为 0，除法将失败，因此
下限取 1。`normalize [5, 5]` 返回 `[0, 0]`，不产生异常。含除法的数学式在实现时都需要检查
分母是否为零。

◇ 列表类型是归纳定义的（`[]` 为基例，`:` 为归纳步）。`total` 这样的函数是对该归纳定义做
消去：给基例一个值，给归纳步一个函数，其余由归纳原理保证唯一。第 3 章的 3.4 节将说明，归纳
类型的消去规则就是 `fold`，`foldr` 届时不再只是一个便利函数。

## 2.3 高阶函数

### 2.3.1 把变化的部分提为参数

三个函数只差两处，把这两处提为参数，就得到 `map`、`filter`、`foldr`：

```haskell
map :: (a -> b) -> [a] -> [b]
map _ []     = []
map f (x:xs) = f x : map f xs

filter :: (a -> Bool) -> [a] -> [a]
filter _ []     = []
filter p (x:xs) = if p x then x : filter p xs else filter p xs

foldr :: (a -> b -> b) -> b -> [a] -> b
foldr _ z []     = z
foldr f z (x:xs) = f x (foldr f z xs)
```

`foldr` 的作用是把列表的构造符替换为给定的运算符：

```
[1, 2, 3]              用 (:) 和 [] 构造
1 + (2 + (3 + 0))      用 (+) 和 0 构造
```

骨架相同，只是 `:` 换成 `+`，`[]` 换成 `0`。因此 `total` 可写成 `foldr (+) 0`，
`doubleAll` 可写成 `map (2 *)`，`evens` 可写成 `filter even`：原来的六个方程各压缩为一行。

### 2.3.2 折叠的代价：thunk 与 foldl'

`foldr (+) 0` 是求和的数学定义，直接用于求值却并不合适。

惰性求值不会立即计算，而是先构造表达式：

```
foldr (+) 0 [1,2,3]  →  1 + (2 + (3 + 0))
```

三个元素尚无问题；一千万个元素会积累一千万层未求值的加法，即 **thunk**，占用数百 MB 至数 GB
内存，最后一次性求值。1.6 节所说的"惰性把求值时机交给运行时"，代价即在此处。

工程上的写法是严格左折叠：

```haskell
{{#include ../code/src/Ch02/Functions.hs:strict-fold}}
```

（使用前需 `import Data.List (foldl')`。）

`foldl'` 每一步都求出中间结果，累加器始终是 `Int`，不会形成表达式树。（`base` 中 `sum` 的
实现即 `foldl' (+) 0`。不带撇的 `foldl` 既不短路，又积累 thunk，几乎没有适用场合。）

两者的分工是：`foldr` 用于表达结构，可短路、可处理无限列表；`foldl'` 用于累积数值。对 `(+)`
这类满足结合律且有单位元的运算，选错不改变结果，只带来意外的耗时与内存占用；对减法这类运算，
连结果也会变（见 2.7.3）。

### 2.3.3 管道与 zipWith

改用高阶函数后，前面三个函数写成：

```haskell
{{#include ../code/src/Ch02/Functions.hs:pipeline}}
```

`filter ((>= 60) . snd)` 读作"取第二个分量，判断其是否不小于 60"。`snd` 取二元组的第二个
分量；`(>= 60)` 是 **section**，把 `>=` 的第二个参数填为 60，得到 `\x -> x >= 60`；`(.)` 将两个
函数连接。三者均在下一节说明。

`zipWith` 是二元版本，按位合并两个列表：

```haskell
{{#include ../code/src/Ch02/Functions.hs:zip}}
```

`pairs` 为 `[10, 40, 90]`：第一个列表有 5 个元素，第二个只有 3 个，结果停在较短的一方。
这一行为由 `zipWith` 的定义决定：任一列表为空时即停止。

## 2.4 Curry 化

以上各处都用到同一个事实：Haskell 的函数只接受一个参数。所谓二元函数：

```haskell
{{#include ../code/src/Ch02/Functions.hs:add}}
```

其类型为 `Int -> Int -> Int`，箭头右结合，因此实际含义是：

```haskell
add :: Int -> (Int -> Int)
```

`add` 接受一个 `Int`，返回一个 `Int -> Int` 的函数；再给一个 `Int` 才得到结果。这一点可以在
中途停下：

```haskell
{{#include ../code/src/Ch02/Functions.hs:add-ten}}
```

`addTen` 的类型是 `Int -> Int`，定义中没有写参数，因为 `add 10` 本身即为函数。`addTen 5`
求值为 `15`。这一机制称为 **Curry 化**（currying），名称来源于 Haskell Curry。

### 函数空间的同构

设 $A, B, C$ 为集合，$C^B$ 表示从 $B$ 到 $C$ 的全部函数构成的集合（该记号的理由是
$|C^B| = |C|^{|B|}$）。此时存在自然双射：

$$
\mathrm{Hom}(A \times B,\; C) \;\cong\; \mathrm{Hom}(A,\; C^B)
$$

左边接受一个有序对并返回一个值，右边接受一个 $A$ 并返回一个 $B \to C$ 的函数。两个方向的
映射在 Haskell 中各对应一个函数：

```haskell
{{#include ../code/src/Ch02/Functions.hs:curry}}
```

`curry :: ((a, b) -> c) -> a -> b -> c` 把左边变为右边，`uncurry` 相反。`addCurried 1 2`
与 `addPair (1, 2)` 都得 `3`，这行代码即该同构的一个具体实例。

◇ 元素个数上的核对：不必取具体数值，直接比较两边的表达式的形式：

$$
|\mathrm{Hom}(A \times B,\; C)| = |C|^{|A|\,|B|},
\qquad
|\mathrm{Hom}(A,\; C^B)| = \big(|C|^{|B|}\big)^{|A|} = |C|^{|A|\,|B|}
$$

结果相等：先打包成一对再取值，与先取值再打包，函数的个数相同。

这个同构界定了"函数空间"的含义：若一个范畴对任意对象 $B, C$ 都存在对象 $C^B$ 使上述双射
自然成立，该范畴称为**Cartesian 闭范畴**（Cartesian closed category）。集合范畴是，Hask 也是
（在忽略 $\bot$ 的意义下）。严格的定义还要求该范畴有终对象与二元积——指数不能单独存在，双射
的两边都要用到积。第 8 章给出完整定义，并说明应用函子的定义依赖这一结构。

### 语法上的推论

由此可以解释若干语法现象，无须单独记忆：

- `add 1 2` 无须写成 `add(1, 2)`：这里不存在二元函数，只有返回函数的函数。
- `map (2 *) [1,2]` 中的 `(2 *)` 合法：`*` 是二元运算，填入第一个参数后成为一元函数。
- `(-1)` 不能作为"减一"使用，见 2.7.1 节。

## 2.5 函数复合

### `.` 运算符

`(.)` 的定义只有一行：

```haskell
(.) :: (b -> c) -> (a -> b) -> (a -> c)
f . g = \x -> f (g x)
```

它满足结合律 `f . (g . h) = (f . g) . h`。这不是 Haskell 的规定，而是函数复合本身的性质。
第 5 章中，复合的结合律是范畴定义的第一条公理。

有了它，`filter ((>= 60) . snd)` 无须为参数命名。这种写法称为 **point-free**：

```haskell
names = map fst . filter ((>= 60) . snd)   -- 对比：names rows = map fst (filter ((>= 60) . snd) rows)
```

point-free 有适用范围。两三步的组合较易读；超过四步，`(.)` 链需要从右向左解读，可读性下降。
判断标准是能否一次读通。读不通时应写回参数形式，理由是减少后续阅读成本。

### `$` 运算符

```haskell
sum $ map (^ 2) [1 .. 10]     -- 385
```

`$` 的定义为 `f $ x = f x`，唯一特殊之处是优先级最低（`infixr 0`）。因此 `f $ g $ h x` 等于
`f (g (h x))`，可省去两层括号。

它与 `(.)` 的区别是：`$` 作用于值，`(.)` 作用于函数。`(.)` 组合两个函数，结果仍是函数；
`$` 只是把右边的值传给左边的函数。（两者混用时编译器给出的错误见 2.7.4。）

## 2.6 Lambda 演算

前面五节一直在用 λ 演算，只是没正式提出。λ 演算是"函数作为值"的最小语言：表达式只有
三种——变量、λ-抽象、应用。第 9 章的 $\lambda a.\, f(a)$、第 13 章的
$\lambda \_.\, y$ 都写在这个语言里，本节把它的规则一次说清。

### 2.6.1 λ-抽象（及其 Haskell 对应表达）

**λ-抽象**（lambda abstraction）$\lambda x.\, e$ 表示以 $x$ 为参数、以 $e$ 为体的
函数；Haskell 写作 `\x -> e`（`\` 是 λ 的 ASCII 替身）。**应用**（application）
$f\,x$ 把函数 $f$ 用于参数 $x$，Haskell 写作 `f x`。2.1 节的递归、2.3 节的高阶
函数、2.4 节的 Curry 化，其数学形式都写在这套语言里。

Haskell 的多元函数定义是**语法糖**（syntactic sugar）：`f x y = x + y` 只是写起来省事，编译器会把它展开（**解糖**，desugar）成嵌套的一元 λ，即
$f := \lambda x.\, \lambda y.\, x + y$。这正是 Curry 化的来源（2.4 节）——
`f 1 2` 先代 $x$ 得 $\lambda y.\, 1 + y$，再代 $y$ 得 $1 + 2$。

**绑定与自由变量**：$\lambda x.\, x + y$ 中 $x$ 是**绑定变量**（bound
variable），$y$ 是**自由变量**（free variable）。绑定变量可以改名而不改变函数：
$\lambda x.\, x + 1$ 与 $\lambda z.\, z + 1$ 是同一个函数，这称为 **α-等价**
（alpha-equivalence）。Haskell 同理：`\x -> x + 1` 与 `\z -> z + 1` 是同一个值。

### 2.6.2 β-归约与 η-归约

**β-归约**（beta-reduction）：函数应用按"代入"求值，即把 $(\lambda x.\, e)\,v$
替换为 $e[x := v]$（把 $e$ 中所有 $x$ 换成 $v$）。

**例子**
$$(\lambda x.\, x + 1)\,3 \;\leadsto\; 3 + 1 \;\leadsto\; 4$$

其中$\leadsto$ 读作"归约到"。Haskell 的求值遵循同样的代入规则（2.3.2 节）：
`(\x -> x + 1) 3` 计算出 `4`。2.5 节 `(g . f) x = g (f x)` 的逐步验证，就是
β-归约。

**η-归约**（eta-reduction）：$\lambda x.\, f\,x$ 与 $f$ 是同一个函数——参数原样
传给 $f$，多一层包装没有意义。Haskell 里 `\x -> f x` 与 `f` 行为相同，GHC 的
优化也会做这一步。η-归约在范畴论里叫**外延性**（extensionality）：函数由它在
每个输入上的值决定。第 6 章处理 Hask 范畴时还会遇到它：`seq` 与 $\bot$ 会破坏
η-等价，这也是 Hask 不是严格范畴的原因之一。

### 2.6.3 Church 编码：数据也是函数

$\lambda$ 演算里没有布尔与自然数，它们都用函数编码。**Church 布尔**：

$$\mathrm{true} := \lambda x.\, \lambda y.\, x, \qquad
\mathrm{false} := \lambda x.\, \lambda y.\, y$$

**Church 自然数** $n$ 是"把 $f$ 作用 $n$ 次的函数"：

$$0 := \lambda f.\, \lambda x.\, x, \qquad 1 := \lambda f.\, \lambda x.\, f\,x,
\qquad n + 1 := \lambda f.\, \lambda x.\, f\,(n\,f\,x)$$

用 β-归约可以验证 $1\,g\,z \leadsto g\,z$、$2\,g\,z \leadsto g\,(g\,z)$。
Haskell 里照抄（类型分别是 `a -> a -> a` 与 `(a -> a) -> a -> a`）：

```haskell
churchTrue, churchFalse :: a -> a -> a
churchTrue  t _ = t
churchFalse _ f = f

church2 :: (a -> a) -> a -> a
church2 f x = f (f x)
```

这个编码说明两件事：数据与控制是同一个东西（`true` 就是"选第一个"）；后面章节
"把函数当数据"的写法——第 3 章用类型元素个数做算术、第 5 章用枚举验证公理、第 9
章把 $a \to T b$ 当态射——都建立在这个"一切皆函数"的世界观上。

## 2.7 常见错误

### 2.7.1 (-1) 不是"减一"的 section

要给每个元素减 1，直观写法是：

```haskell
badList = map (-1) [5, 4]
```

编译失败：

```
T1.hs:4:16: error: [GHC-39999]
    • No instance for 'Num (a0 -> Int)'
        arising from a use of syntactic negation
      (maybe you haven't applied a function to enough arguments?)
    • In the first argument of 'map', namely '(- 1)'
```

原因：`(-1)` 是负数字面量（即 `negate 1`），不是减号的部分应用。中缀运算符做 section 时，
`(x -)` 合法，`(- x)` 不合法，后者被优先解析为负数，于是 `map` 收到的不是函数，错误信息因此
指向 `Num (a0 -> Int)`。

正确写法有三种：

```haskell
map (subtract 1) [5, 4]   -- [4, 3]
map (\x -> x - 1) [5, 4]  -- [4, 3]
map (1 -) [5, 4]          -- [-4, -3]，此处是 1 减 x，方向相反
```

`subtract` 正是为该情形提供的。

### 2.7.2 缺少参数时，类型错误不直接说明原因

```haskell
badNumber :: Int
badNumber = add 1
```

```
T2.hs:7:13: error: [GHC-83865]
    • Couldn't match expected type 'Int' with actual type 'Int -> Int'
    • Probable cause: 'add' is applied to too few arguments
```

GHC 在第二行给出了原因。复杂表达式中，第一条信息往往具有误导性，优先阅读
`Probable cause` 一行可以节省时间。

### 2.7.3 foldr 与 foldl 不等价

```haskell
foldr (-) 0 [1,2,3]   -- 1 - (2 - (3 - 0)) = 2
foldl (-) 0 [1,2,3]   -- ((0 - 1) - 2) - 3 = -6
```

对加法、乘法这类满足结合律的运算，两者结果相同；对减法、除法与列表拼接，结果不同。即使结果
相同，代价也不同：`foldl` 在惰性求值下积累 thunk，`foldl'` 则逐步求值。1.6 节的问题在此重现。

### 2.7.4 f . g 3 不是"先算 g 3，再交给 f"

```haskell
bad = f . g 3
```

```
T3.hs:10:7: error: [GHC-83865]
    • Couldn't match expected type 'Int' with actual type 'a0 -> Int'
    • Probable cause: '(.)' is applied to too few arguments
      In the expression: f . g 3
```

函数应用的优先级高于任何中缀运算符，因此 `f . g 3` 解析为 `f . (g 3)`：右边是 `Int`，
而 `(.)` 要求两侧都是函数。

要表达"先算 `g 3`，再交给 `f`"，两种写法均可：

```haskell
f $ g 3      -- 用 $
f (g 3)      -- 用括号
```

此错误难以定位，是因为 `a0 -> Int` 看起来像缺少参数，实际是括号位置不当。2.5 节的区分在此
适用：`.` 要求两侧都是函数，`$` 接受值。

## 2.8 练习

1. 用 `foldr` 重写 `length'`、`reverse`、`concat`，各不超过两行。
2. 把 `pairs` 改为以较长的列表为准。`zipWith` 无法做到，需说明缺少什么（提示：第 3 章的代数
   数据类型会给出答案）。
3. 证明 `map f . map g = map (f . g)`，对列表长度作归纳。
4. 证明 `foldr (:) [] = id`。
5. 定义 `foldlFromRight :: (b -> a -> b) -> b -> [a] -> b`，仅用 `foldr` 实现。（提示：让累加器
   本身是一个函数。）
6. 用 β-归约展开 `church2 (+1) 0` 得到 2；在 ghci 里输入同式核对，再验证
   `churchTrue 1 2` 与 `churchFalse 1 2` 分别选出第一、第二个参数。

## 参考文献

- **Bird, Richard.** *Thinking Functionally with Haskell*, 2nd ed. Cambridge University Press,
  2014. 全书以等式推理为主线：先写方程，再把变化的部分提为参数。本章 2.2–2.3 节的写法
  沿此路径。
- **Awodey, Steve.** *Category Theory*, 2nd ed. Oxford University Press, 2006.
  §6.1（Exponential in a category）、§6.2（Cartesian closed categories）、§6.4（不依赖
  集合元素的等式定义）。2.4 节所述双射的范畴论版本见这几节，第 8 章将正式使用。
- **Barendregt, Henk.** *The Lambda Calculus: Its Syntax and Semantics*, 2nd ed.
  North-Holland, 1984. 无类型 λ 演算的标准参考：语法、α/β/η-归约与 Church–Rosser
  定理。2.6 节的归约规则依据此书。
- **Church, Alonzo.** *The Calculi of Lambda-Conversion*. Princeton University Press,
  1941. λ 演算的原典；Church 布尔与 Church 自然数在此首次提出（2.6.3 节）。
- **Pierce, Benjamin C.** *Types and Programming Languages*. MIT Press, 2002. 第 5 章
  以约三十页讲完无类型 λ 演算（语法、归约、Church 编码），是面向工程读者的最简入门；
  2.6 节按此书的顺序组织。
- **Selinger, Peter.** *Lecture Notes on the Lambda Calculus*. 2013.
  https://arxiv.org/abs/0804.3434。在线讲义，§1–2 覆盖 2.6 节的内容，含
  Church–Rosser 定理的证明与不动点组合子。
- **`Data.List`**（`base` 包）中 `foldr` 与 `foldl'` 的文档：2.3 节关于求值代价的讨论依据
  于此。
