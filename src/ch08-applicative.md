# 第 8 章 应用函子

> 状态：试写稿（第一稿，待审） ｜ 目标 2.8 万字 ｜ 代码：`code/src/Ch08/Applicative.hs`

`fmap` 一次只处理一个参数。本章处理多参数函数在 Maybe、列表等语境里如何组合：先给出
`pure` 与 `<*>` 的机制和四条定律，再把它们对应到数学上的 lax monoidal 函子，最后逐个看
Maybe、List、ZipList、Reader、Const、Validation 六个实例。

## 8.1 问题：二元函数遇到 Maybe

把两个 `Maybe Int` 相加。第 7 章的 `fmap` 帮不上：`(+)` 是二元函数，`fmap (+) mx` 得到的是
`Maybe (Int -> Int)`，一个装在 `Maybe` 里的函数。把里面的函数应用到 `my` 上，需要一个新的
操作。最直接的写法把 `Nothing` 的检查写两遍：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:motivation}}
```

两层 `case` 里，真正变化的是 `x + y` 这一步；`Nothing` 的传播规则重复了两次。要复用的正是
"在 Maybe 的语境里应用函数"这个动作。

## 8.2 机制：`pure` 与 `<*>`

### 8.2.1 类与实例的形状

`Control.Applicative` 给出的类声明是：

```haskell
class Functor f => Applicative f where
    pure  :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b
```

`pure` 把普通值装进语境；`<*>` 把装在语境里的函数应用到装在语境里的值上。两个操作合起来，
`fmap` 可以只用 `<*>` 定义：`fmap h x = pure h <*> x`。

**定义 8.1（应用函子）** 一个**应用函子**（applicative functor）是一个带有 `pure` 与 `<*>`
的类型构造子 `f`，且 `f` 是 `Functor`。

**例 8.1（两个 Maybe 相加）** 用 `<$>`（即 `fmap` 的中缀形式）与 `<*>` 重写 8.1 节的两层
`case`：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:applicative-use}}
```

`(+) <$> mx` 的类型是 `Maybe (Int -> Int)`，`<*>` 把它应用到 `my`。三个参数用
`(,,) <$> mx <*> my <*> mz`，写法随参数个数线性增长，`Nothing` 的检查一次也没写。测试断言
`addMaybe (Just 1) (Just 2) == Just 3`、`addMaybe (Just 1) Nothing == Nothing`。

### 8.2.2 四条定律

**定义 8.2（应用函子）** `Applicative f` 的实例应当满足，对一切 `u :: f (a -> b)`、
`v :: f a`、`w :: f a`、`x :: a`、`y :: a`、`f :: a -> b`：

以下四条定律用数学记号书写：$\eta$ 表示 `pure`，$\circledast$ 表示 `<*>`。

$$
\begin{aligned}
\eta\,\mathrm{id} \circledast v &= v && \text{恒等} \\
\eta\,(\circ) \circledast u \circledast v \circledast w &= u \circledast (v \circledast w) && \text{复合} \\
\eta\,f \circledast \eta\,x &= \eta\,(f\,x) && \text{同态} \\
u \circledast \eta\,y &= \eta\,(\lambda f.\ f\,y) \circledast u && \text{交换}
\end{aligned}
$$

恒等律说把"装在语境里的恒等"应用上去等于没动；同态律说 `pure` 与 `<*>` 配合等价于先在语境外
应用函数；复合律是 `fmap` 复合律的 `<*>` 版本；交换律说先提供函数还是先提供参数不影响结果。
四条与第 7 章的两条 `fmap` 定律合起来，构成应用函子的完整义务。

**例 8.2（在 Maybe 上核对四条定律）** 把四条写成一组布尔断言：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:laws}}
```

测试返回 `True`。与 7.2.3 节一样，这不是证明；证明要对 `Maybe` 的两个构造子分类讨论。

🦂 类型检查不检查这四条。`Applicative` 的定律与 `Functor` 的定律一样只存在于文档与测试中。
写实例时至少跑一遍例 8.2 这种核对。

### 8.2.3 坏实例：类型正确、定律不成立

**例 8.3（`BadAp`）** 仿照 7.5 节的 `Weird`，给一个类型正确、定律不成立的实例：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:bad-instance}}
```

`pure x` 记下 0，每次 `<*>` 在结果里多加一个 1。恒等律失败：`pure id <*> BadAp 1 0` 得
`BadAp 1 1`，不等于 `BadAp 1 0`。复合律也失败：左边三个 `<*>` 各加一次 1 共加 3，右边先算
`v <*> w` 再加一次共加 2，计数不同。同态律同样失败。交换律恰好成立，因为它两边各经过一次
`<*>`，多加的 1 相同。GHC 对这段代码不报任何错；四条定律要靠证明或测试。

## 8.3 数学：笛卡尔闭范畴与 lax monoidal 函子

`pure` 与 `<*>` 在范畴论里有名字。这一节补全 2.4 节留下的定义。

### 8.3.1 笛卡尔闭范畴

**定义 8.3（笛卡尔闭范畴）** 范畴 $\mathcal{C}$ 是**笛卡尔闭范畴**（cartesian closed
category，CCC），若它有终对象 $1$、任意两个对象的二元积 $A \times B$、任意两个对象的指数
$C^B$，并且存在一个自然的双射

$$
\mathrm{Hom}(A \times B,\; C) \cong \mathrm{Hom}(A,\; C^B),
$$

其中 $A, B, C$ 为任意对象。

终对象、二元积、指数三者缺一不可：双射的两边分别用到积与指数。2.4 节只给了函数空间的同构
版本；完整定义还要终对象 $1$ 与积的泛性质。Set 是 CCC，Hask 在忽略 $\bot$ 的意义下也是。

对 Hask，双射的两个方向正是 Curry 化与反 Curry 化。`(a, b) -> c` 与 `a -> (b -> c)` 的元素
一一对应，对应由 `curry` 与 `uncurry` 实现。`pure` 的威力正来自这里：二元函数先 Curry 化成
一元函数，`fmap` 就能把它装进语境。

### 8.3.2 lax monoidal 函子

**定义 8.4（lax monoidal 函子）** 设 $\mathcal{C}$、$\mathcal{D}$ 是幺半群范畴。函子
$F\colon\mathcal{C}\to\mathcal{D}$ 带上一个态射 $\eta\colon 1_{\mathcal{D}} \to F(1_\mathcal{C})$
与一族态射 $\mu_{A,B}\colon FA \otimes FB \to F(A \otimes B)$，且满足结合性与单位的一致性
条件，称为 lax monoidal 函子。

Hask 的幺半群结构取 $1 = ()$、$\otimes = \times$。**应用函子与 lax monoidal 函子是同一个
东西**，对应如下：

| lax monoidal 分量 | Hask 版本 | Haskell 写法 |
|---|---|---|
| $\eta\colon 1 \to F1$ | $() \to f\;()$ | `pure ()` |
| 由 $\eta$ 导出的 $A \to FA$ | 任意值装进语境 | `pure` |
| $\mu_{A,B}\colon FA \times FB \to F(A \times B)$ | 一对语境值合成语境积 | `(,) <$> fa <*> fb` |
| 由 $\mu$ 与求值导出的 $F(A \to B) \times FA \to FB$ | 语境里的函数应用到语境值 | `<*>` |

四条定律与 lax monoidal 的一致性条件一一对应：恒等律与同态律对应单位一致性，复合律与交换律
对应结合性与自然性。lax 的意思是 $\mu$ 不是同构：`Maybe a` 与 `Maybe b` 的积只有一部分组合
能合成 `Maybe (a, b)`，`Nothing` 会把整个结果变成 `Nothing`。信息在这个过程中丢失，方向
只能从左到右。

## 8.4 实例巡礼

### 8.4.1 Maybe：失败传播

**例 8.4（`Maybe` 实例）** 标准库的实现要点是 `pure = Just`，`Just f <*> Just x = Just (f x)`，
其余情况得 `Nothing`：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:maybe-instance}}
```

`pairMaybe` 得 `Just (1, 'a')`；`failMaybe` 里 `Nothing` 出现一次，整个结果就是 `Nothing`。
Maybe 的语义是"失败即停"：任何一个环节没有值，后面全部免算。要"失败也继续、把所有错误收
齐"的语义，见 8.4.6 的 Validation。

### 8.4.2 List：笛卡尔积

#### 8.4.2.1 Python 实现

列表装的是"多个候选"。对两个列表逐一配对，Python 有两个内置语义：

```python
{{#include ../code/python/zip_product.py:zip-vs-product}}
```

运行的真实输出：

```
[(1, 'a'), (1, 'b'), (2, 'a'), (2, 'b')]
[(1, 'a'), (2, 'b')]
[(1, 'a'), (2, 'b'), (3, None)]
```

`product` 给出笛卡尔积，长短互不影响；`zip` 截断到较短者；`zip_longest` 不截断而是补
`None`。三种语义都合法，选哪个看业务：生成所有组合用 `product`，对齐两个序列用 `zip`。
Python 的限制在于，三种语义散在三个函数里，没有一个统一的接口把它们换成 `Maybe`、`Reader`
等其他语境。

#### 8.4.2.2 Haskell 实现

**例 8.5（列表实例）** Haskell 的列表实例选的是笛卡尔积语义：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:list-instance}}
```

`grid` 得 `[(1,'a'), (1,'b'), (2,'a'), (2,'b')]`，与 Python 的 `product` 相同。列表的
`pure` 是单元素列表：`pure x = [x]`，所以 `(+) <$> [1,2] <*> [10,20]` 得
`[11, 21, 12, 22]`，四个组合一个不少。

| 维度 | Python | Haskell |
|---|---|---|
| 笛卡尔积 | `itertools.product` | 列表的 `<*>` |
| 按位配对（截断） | `zip` | `ZipList` 的 `<*>` |
| 按位配对（补缺） | `zip_longest` | 无对应（需自定义） |
| 统一接口 | 无 | `Applicative` |

对照的主线是最后一行：Haskell 的两种配对语义挂在同一个 `<*>` 名下，靠类型区分，因此一个
写好了 `f <$> x <*> y` 的程序，把列表换成 `Maybe` 或 `Reader` 不用改结构。

### 8.4.3 ZipList：按位配对与 `pure = repeat` 的理由

**例 8.6（`ZipList`）** `ZipList` 是列表的另一个 `Applicative` 实例，语义是 `zip`：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:zip-list}}
```

`zipPair` 得 `[(1,'a'), (2,'b')]`，第三个元素被截掉。

🦂 `ZipList` 的 `pure` 是 `repeat`，不是 `[]`，也不是单元素列表。这不是随意选择，是恒等律
逼出来的：若 `pure = []`，则 `pure id <*> xs = []`，恒等律 `pure id <*> xs = xs` 对非空
`xs` 立刻失败；若 `pure = [x]`（单元素），`pure id <*> [1, 2, 3]` 只得到 `[1]`，同样失败。
要满足恒等律，`pure id` 必须提供无限多个 `id`，供任意长度的列表取用，`repeat` 是唯一选择。
代价是 `ZipList` 不再是 `Monad`：第 9 章会看到，`pure = repeat` 与 `>>=` 的定律无法相容。

### 8.4.4 Reader：共享环境

**例 8.7（函数实例）** 对固定的环境类型 `r`，函数类型 `r -> a` 有 `Applicative` 实例：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:reader-instance}}
```

`askBoth 3` 得 `(4, 6)`：`(+ 1)` 与 `(* 2)` 各自读到同一个环境 3，分别算出 4 和 6。函数
实例的语义是"同一个输入分发给两个计算"。这正是依赖注入的雏形：两个子计算共享一份只读
配置，配置在 `r` 里传来传去，不必改动任何全局状态。

### 8.4.5 Const：只留幺半群

**例 8.8（`Const` 实例）** `Const m a` 只存 `m` 不存 `a`：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:const-instance}}
```

`Const (Sum 3) <*> Const (Sum 4)` 得 `Const (Sum 7)`：两个 `m` 用 `< >` 合成，`a` 部分只是
占位。测试断言 `constSum == Sum 7`。

🦂 `Const m` 的 `Applicative` 实例要求 `m` 是幺半群，这个要求不是额外加的，是从定律推出来
的。`pure x` 必须给出一个 `m` 且与 `x` 无关，记作 `m₀`；`Const m₁ <*> Const m₂` 必须给出
`m₁` 与 `m₂` 的某个合成，记作 `m₁ ⊙ m₂`。恒等律要求 `m₀ ⊙ m = m = m ⊙ m₀`，复合律要求
`⊙` 结合。这正是幺半群的三条公理。所以 `Const` 的意义是：把幺半群的累积挂进应用函子的
接口。

### 8.4.6 Validation：累积错误

**例 8.9（`Validation`）** 表单校验要一次报告全部错误，Maybe 的"失败即停"不够：

```haskell
{{#include ../code/src/Ch08/Applicative.hs:validation}}
```

`validatePerson` 对 `checkAge 200` 与 `checkName ""` 分别失败，两个错误串合并成
`Failure ["age too large", "name is empty"]`。关键在最后一条方程：两边都失败时，两个错误
列表用 `++` 接起来。

🦂 `Validation` 不能写成 `Monad`。`>>=` 要求下一步取决于上一步的结果；上一步已经失败时，
下一步没有值可用，只能短路。累积要求"两个计算独立完成"，这正是 `<*>` 的形状；`>>=` 的
形状是先后的依赖，与累积矛盾。标准库里 `Either` 是 `Monad` 因而短路，`Validation`（
`validation` 包或自写）是 `Applicative` 因而累积。二者互不替代，选谁取决于要不要一次
报告全部错误。

## 8.5 常见错误

**把 `<*>` 当 `fmap` 的双参数版。** `fmap` 吃普通函数，`<*>` 吃语境里的函数。`<*>` 的
第一个参数是 `f (a -> b)`，写反两个参数的类型顺序会得到这样的报错：

```
src/Ch08/Applicative.hs:43:24: error: [GHC-83865]
    • Couldn't match type ‘(Int, Int, Int)’ with ‘Int’
      Expected: Int -> Int -> Int -> Int
        Actual: Int -> Int -> Int -> (Int, Int, Int)
```

报错指向 `(,,) <$> mx`：三元函数放进返回 `Maybe Int` 的位置。类型检查器在这里做的事正是
盯着 `f (a -> b)` 与 `f a` 的顺序。

**`<*>` 与 `==`、`/=` 混用不加括号。** 三者都是中缀优先级 4，GHC 拒绝在同一表达式里混用：

```
src/Ch08/Applicative.hs:80:8: error: [GHC-88747]
    Precedence parsing error
        cannot mix ‘<*>’ [infixl 4] and ‘/=’ [infix 4] in the same infix expression
```

把比较两边分别加括号：`(pure id <*> v) == v`。

**在定律检查里用函数值。** 恒等律写成 `pure id <*> v == v` 时，若 `v` 是 `Maybe (Int -> Int)`
会得到：

```
src/Ch08/Applicative.hs:51:27: error: [GHC-39999]
    • No instance for ‘Eq (Int -> Int)’ arising from a use of ‘==’
      (maybe you haven't applied a function to enough arguments?)
```

函数没有 `Eq`（6.3.3 节）。定律检查要选可比较的值类型，例如 `Just 7 :: Maybe Int`。

**以为列表的 `<*>` 是 zip。** 是笛卡尔积；zip 语义在 `ZipList`。混淆的后果是组合数量对
不上：`(,) <$> [1..3] <*> [1..3]` 得 9 个元素，不是 3 个。

## 8.6 练习

1. 证明 Maybe 实例满足恒等律与复合律，分别按 `Nothing` 与 `Just` 两个构造子分类讨论。
2. 构造一个满足四条定律中的三条、违反一条的 `Applicative` 实例，给出具体的反例值（`BadAp`
   是违反三条的原型）。
3. 改写：把 `tripleMaybe` 改成先 `curry` 再 `fmap` 的形式，说明两种写法为什么等价
   （用到 8.3.1 的 CCC 双射）。
4. 证明：`ZipList` 若要满足恒等律，`pure` 必须是 `repeat`。指出证明中哪一步用到
   `pure id <*> xs = xs`。
5. 从恒等律与复合律推出 8.4.5 节所说的 `Const m` 的幺半群要求：写出 `m₀` 与 `⊙` 的定义，
   逐条对应幺半群公理。
6. 对照：用 Python 的 `product` 与 `zip` 分别实现 8.4.2 的两种语义，指出 `zip_longest` 的
   补缺语义在 Haskell 里需要怎样自定义（提示：两个列表先各自 `pure` 对齐长度）。
7. 构造一个 `Validation String` 的校验流水线：至少四个独立校验，其中两个失败，断言错误
   按校验顺序全部出现在 `Failure` 里。
8. 推导：从定义 8.4 的单位一致性条件推出 8.2.2 的同态律，写出每一步对应的分量。

## 参考文献

- **McBride, Conor; Paterson, Ross.** "Applicative Programming with Effects." *Journal of
  Functional Programming* 18(1), 2008. Applicative 的类、四条定律与实例体系的首篇系统论文；
  8.2 节与 8.4 节依据此篇。
- **Awodey, Steve.** *Category Theory*, 2nd ed. Oxford University Press, 2006. §6.1–6.2
  （指数与 CCC）。定义 8.3 据此。
- **Mac Lane, Saunders.** *Categories for the Working Mathematician*, 2nd ed. Springer,
  1998. 第 VII 章（幺半群范畴）、第 XI 章（monoidal 函子与一致条件）。定义 8.4 据此。
- **`base` 文档**：`Control.Applicative`（类声明与定律）、`Data.Functor.Const`、`ZipList`。
  8.2 与 8.4 的实例依据。
