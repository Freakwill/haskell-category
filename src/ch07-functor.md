# 第 7 章 函子与自然变换：`fmap` 与自然性

> **状态**：试写稿（第一稿，待审） ｜ **目标**：1.8 万字 ｜ **代码**：`code/src/Ch07/Functor.hs`
>
> 写作提示：样章之一；自然性方块在线版用 ASCII，排 PDF 时手画 TikZ

第 5 章定义函子：把对象映射到对象、态射映射到态射，并保持恒等与复合。Haskell 的 `Functor` 类是
这个定义在 **Hask** 上的实现：类型构造子给对象映射，`fmap` 给态射映射。本章先用一棵树说明
`fmap` 到底做什么，再补上两条定律；随后引入自然变换，说明某些多态函数"不看元素值"这一限制
的精确含义。

## 7.1 问题：同一个操作在不同形状上重复

三种容器：`Maybe a` 没有元素或有一个；`[a]` 有任意多个；二叉树在叶子放元素。现在把每个
`Int` 加一，最直接的写法是为每种形状各写一个函数：

```haskell
{{#include ../code/src/Ch07/Functor.hs:motivation}}
```

两段代码里真正变化的是 `(+ 1)`；`Nothing`、`Just`、`[]`、`(:)` 保留不动。换成平方、换成
`show`、换成任意 `a -> b`，这段"保留形状、处理元素"的代码都要重复。要复用的正是这一部分。

**例 7.1（树上的 `fmap`）** 本章的代码定义一棵二叉树，并给它一个 `Functor` 实例：

```haskell
{{#include ../code/src/Ch07/Functor.hs:tree}}
```

测试断言 `fmap (* 2) (Branch (Leaf 1) (Leaf (-2))) == Branch (Leaf 2) (Leaf (-4))`：叶子里的
数变了，`Branch`、两个 `Leaf`、左右位置都没变。把这一动作抽出来，`mapTree` 不需要重新写
递归：

```haskell
{{#include ../code/src/Ch07/Functor.hs:map-tree}}
```

这就是 `fmap` 的工作：给定处理元素的函数，保留容器的结构。

🦂 "函子是盒子"只是第一印象。`Maybe` 和列表像盒子，`Tree` 像树；但函数类型也有 `Functor`
实例：固定 `r` 时 `fmap h g = h . g :: (r -> a) -> (r -> b)`，这里的"结构"是等待参数 `r` 的
计算。`Const m a` 也有实例，却根本不存 `a`。所以"保留结构"只能当读代码的提示；严格的定义
要回到对象映射、态射映射与两条定律。

## 7.2 从类到函子

### 7.2.1 类型构造子与 kind

`Functor` 的类头是

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

`f` 的 kind 是 `* -> *`：接受一个类型，返回一个类型。`Maybe`、`[]`、`Tree` 都有这个 kind；
`Maybe Int`、`[Int]`、`Tree Int` 是 kind 为 `*` 的类型。

🦂 `Maybe` 不是 **Hask** 的对象，`Maybe Int` 才是。`Functor Maybe` 的含义不是一次具体的搬运，
而是一套规则：给每个对象 `a` 指定对象 `Maybe a`，给每个函数 `a -> b` 指定函数
`Maybe a -> Maybe b`。这正是 6.1.1 节区分对象与类型构造子的原因。

给 `Functor` 传一个已经是类型的 `Int` 会得到 kind 错误：

```
badfunctor.hs:3:18: error: [GHC-83865]
    • Expected kind ‘* -> *’, but ‘Int’ has kind ‘*’
    • In the first argument of ‘Functor’, namely ‘Int’
      In the instance declaration for ‘Functor Int’
  |
3 | instance Functor Int where
  |                  ^^^
```

`Int` 不能再接受类型参数，而函子必须能对任意 `a` 给出 `f a`。

### 7.2.2 对象映射与态射映射

**定义 7.1（函子）** 对范畴 $\mathcal{C},\mathcal{D}$，函子 $T\colon\mathcal{C}\to\mathcal{D}$
由两部分组成：给每个对象 $a$ 指定对象 $Ta$；给每个态射 $f\colon a\to b$ 指定态射
$Tf\colon Ta\to Tb$。并要求

$$
T(1_a)=1_{Ta},\qquad T(g\circ f)=Tg\circ Tf.
$$

对 `Maybe`：对象映射是类型构造子本身，态射映射是 `fmap`。标准库的实现要点是
`fmap h Nothing = Nothing`、`fmap h (Just x) = Just (h x)`。`Maybe` 把 `Int` 映射到 `Maybe Int`，
把 `show :: Int -> String` 映射到 `fmap show :: Maybe Int -> Maybe String`。
`fmap show Nothing` 不调用 `show`，因为 `Nothing` 里没有元素；这不是 `fmap` 的特殊行为，而是
对象映射保留了"没有元素"这个结构。

### 7.2.3 两条定律

**定义 7.2（函子定律）** `Functor f` 的实例应当满足

$$
\mathsf{fmap}\;\mathsf{id}=\mathsf{id},\qquad
\mathsf{fmap}\;(g\circ f)=\mathsf{fmap}\;g\circ\mathsf{fmap}\;f.
$$

第一条：不改变元素的函数也不能改变结构。第二条：先在元素上复合再遍历，与先遍历一次再遍历
一次相同。两条合起来就是定义 7.1 的保恒等与保复合；Haskell 没有发明另一套规则。

**例 7.2（树的两条定律）** 在有限测试集上逐项核对：

```haskell
{{#include ../code/src/Ch07/Functor.hs:functor-laws}}
```

测试用三棵树、`(+ 1)` 与 `(* 2)`，结果都为 `True`。这不能代替证明；证明对 `Tree` 作结构
归纳。

◇ **复合律的归纳证明。** 对 `Leaf x`，左边是 `Leaf ((g . f) x)`，右边是
`fmap g (Leaf (f x)) = Leaf (g (f x))`，相等。对 `Branch l r`，两边都归结为在 `l`、`r` 上
成立的两个等式，由归纳假设得相等。因此对任意有限 `Tree` 成立。证明只用 `Tree` 的两个构造
子，不依赖任何测试数据。

## 7.3 自然变换

`fmap` 在一个函子内部把态射映射到态射。程序里同样常见的操作是在两个不同函子之间转换：把
`Maybe a` 变成 `[a]`，无值变空列表，有值变单元素列表。

```haskell
{{#include ../code/src/Ch07/Functor.hs:maybe-to-list}}
```

这个函数不知道 `a` 是什么，因此不能检查、排序或构造元素，只能处置 `Nothing` 与 `Just x`
的外层结构。**自然变换（natural transformation）**把"不看元素值"变成精确的等式条件。

**定义 7.3（自然变换）** 设 $T,S\colon\mathcal{C}\to\mathcal{D}$ 是函子。自然变换
$\alpha\colon T\Rightarrow S$ 给每个对象 $a$ 指定态射 $\alpha_a\colon Ta\to Sa$，并要求对
每个 $f\colon a\to b$ 下图交换：

```
        Tf
   Ta -------> Tb
   |           |
   | α_a       | α_b
   v           v
   Sa -------> Sb
        Sf

   α_b . Tf = Sf . α_a
```

（排 PDF 样章时，此图用 TikZ 手画。）

对 `maybeToList`，$T=\mathsf{Maybe}$，$S=\mathsf{List}$，自然性写成

$$
\mathsf{maybeToList}\,(\mathsf{fmap}\;f\;x)
=
\mathsf{fmap}\;f\,(\mathsf{maybeToList}\;x).
$$

左边先改元素、再把 `Maybe` 改成列表；右边先改外层、再改列表元素。自然性断言两条路的结果
相同。

**例 7.3（`maybeToList` 的自然性）** 把方块写成可执行的有限检查：

```haskell
{{#include ../code/src/Ch07/Functor.hs:naturality}}
```

测试对 `Nothing`、`Just (-1)`、`Just 3` 与 `(* 2)` 返回 `True`。一般证明按 `Maybe` 的两个
构造子分类：`Nothing` 时两边都是 `[]`；`Just x` 时两边都是 `[f x]`。

### 7.3.1 非自然的同类型函数

删掉多态，得到同样形状的函数，却可以破坏自然性：

```haskell
{{#include ../code/src/Ch07/Functor.hs:non-natural}}
```

`inspectMaybe` 只保留非负整数。取 `f = (* (-1))` 与 `x = Just 1`，`inspectMaybe (fmap f x)`
得 `[]`，`fmap f (inspectMaybe x)` 得 `[-1]`。两边不同，所以它不是自然变换。问题不在 guard；
问题在它观察了 `Int` 的具体值，转换不再只由 `Maybe` 的结构决定。

🦂 "多态就自然"在这个例子里对，但不是可以随意推广的口号。条件是真正的参数多态类型
$\forall a.\,Ta\to Sa$，并且函数不借 `seq`、`Typeable`、`unsafeCoerce` 等手段窥探或制造元素。
Haskell 有 $\bot$ 和 `seq`，所以参数多态的自由定理（free theorem）要加限定后才能用于全函数，
这正是 6.3 节的结论。把 $\bot$ 一并纳入语义、让等式严格成立的通行做法是**域论**（domain
theory）：类型解释为 CPO，函数解释为连续函数，见章末 Abramsky 与 Jung 的综述。

## 7.4 函子范畴

6.1.1 节说过：函子相对范畴而言。在 **Cat** 中函子是态射；换个范畴看，函子又成为对象。现在把
后一半说清楚。

**定义 7.4（函子范畴）** 给定范畴 $\mathcal{C},\mathcal{D}$，函子范畴
$[\mathcal{C},\mathcal{D}]$ 的对象是从 $\mathcal{C}$ 到 $\mathcal{D}$ 的函子，态射是自然变换。
恒等态射的分量是 $1_{Ta}$；两个自然变换按分量复合。

三个层次并排看：

| 范畴 | 对象 | 态射 |
|---|---|---|
| **Hask** | 类型 | Haskell 函数 |
| **Cat** | 小范畴 | 函子 |
| $[\mathcal{C},\mathcal{D}]$ | 函子 $\mathcal{C}\to\mathcal{D}$ | 自然变换 |

"函子是对象"与"函子是态射"不矛盾，指的不是同一个范畴。自然变换的每个分量都是普通态射，
但自然性方块把这些分量绑成一个整体；任意一组 $Ta\to Sa$ 的函数不自动构成自然变换。

### 7.4.1 `fmap` 与自然性

`fmap` 本身不是 $T\Rightarrow S$ 这种自然变换：它是函子 $T$ 的态射映射，不是两个函子之间
的转换。但 `fmap` 的类型 $(a\to b)\to fa\to fb$ 在 $a$、$b$ 上都是参数多态的；固定 $a$，令
$b$ 变动，`fmap` 给出从 $\mathrm{Hom}(a,-)$ 到 $\mathrm{Hom}(Ta,T-)$ 的自然变换。Wadler 的
自由定理正是从这里得出：多态类型的实现被迫对每个类型"做同样的事"。

这一观察给出检查 API 的办法。若一个库声称某函数是"泛型容器转换"，只给出几个类型上的实现
不够；还应核对转换与 `fmap` 是否可交换。不可交换通常意味着它在观察、丢弃或人为生成元素，
调用者就不能自由移动 `map` 的位置。

## 7.5 常见错误

**把 `Functor` 当作容器接口。** `((->) r)` 与 `Const m` 是反例。`Functor` 不要求存放元素，
只要求对象映射与满足两条定律的态射映射。

**用类型正确代替定律检查。** `Weird` 的实例类型正确，GHC 一条错也不报，两条定律却都不成立：

```haskell
{{#include ../code/src/Ch07/Functor.hs:weird}}
```

`fmap id (Weird 1 0)` 得 `Weird 1 1`，恒等律失败；`fmap (g . f)` 与 `fmap g . fmap f` 在
`Weird 1 0` 上分别得 `Weird 4 1` 与 `Weird 4 2`，复合律也失败。类型检查只保证 `fmap` 接受
`a -> b` 并返回 `f b`，不保证任何定律。`Weird` 里的 `Int` 字段是突破口：实例改变了类型参数
之外的另一个数据。

🦂 两条定律地位不同。复合律由 `fmap` 的类型自动保证：在总函数与参数多态的范围内，自由定理
给出的正是 `fmap (g . f) = fmap g . fmap f`，7.4.1 的自然性就是这条律的重述。恒等律不随
类型而来；`Mod2` 是总函数、满足复合律，却违反恒等律：

```haskell
{{#include ../code/src/Ch07/Functor.hs:mod2}}
```

`fmap id (Mod2 1 2)` 得 `Mod2 1 0`。复合律照常成立，因为对 `Int` 字段的变换 `mod 2` 是幂等
的。因此对全函数，检查 `Functor` 实例时真正要核的是恒等律；复合律仍应写进测试，因为一旦
引入 $\bot$、`seq` 或 `unsafeCoerce`，自由定理的前提被破坏，两条都可能失效（6.3 节）。

**把"自然"读成日常用语。** 自然性是交换方块的技术条件，不表示实现简单、效率高或符合直觉。
`maybeToList` 自然，因为它与任意 `f` 可交换；`inspectMaybe` 不自然，因为存在具体的 `f` 使
方块不等。

**以为多态函数自动自然。** 在纯粹、总的参数多态语言里，参数多态可以推出自然性（自由定理）。Haskell 有 `seq`、异常与 $\bot$，所以这句话只在忽略 $\bot$ 后成立；需要严格语义时回到
6.4 节的出路，或采用域论语义。

## 7.6 练习

1. 为 `Tree` 写 `foldTree :: (a -> b) -> (b -> b -> b) -> Tree a -> b`，并用它重写 `fmap`。
2. 证明 `fmap id = id` 对 `Tree` 成立，分别写出 `Leaf` 与 `Branch` 两步。
3. 定义 `eitherToList :: Either e a -> [a]`，证明它是从 `Either e` 到列表的自然变换。
4. 给出一个 `Maybe Int -> [Int]` 函数不是自然变换；用具体的 `f` 与 `x` 写出自然性方块两边
   不同的结果。
5. 设 $\alpha\colon F\Rightarrow G$、$\beta\colon G\Rightarrow H$ 是自然变换，证明按分量复合的
   $\beta\circ\alpha$ 仍满足自然性。
6. 仿照 `Mod2` 写一个违反恒等律的 `Functor` 实例，说明为什么它的复合律依然成立（提示：
   复合律只要求对 `Int` 字段的变换是幂等的）。

## 7.7 延伸

- 数学：函子范畴 $[\mathcal{C},\mathcal{D}]$ 与 Yoneda 引理；`fmap` 的多态类型是 Yoneda 引理
  的一个特例。
- 工程：`Data.Functor` 的 `(<$>)` 是 `fmap` 的中缀形式；`void`、`(<$)` 等派生函数；`lens`
  包的遍历是自然性的工程应用。

## 参考文献

- **Awodey, Steve.** *Category Theory*, 2nd ed. Oxford University Press, 2006. §1.4（函子）、
  §7.4（自然性）、§7.7（函子范畴）。定义 7.1、7.3、7.4 与自然性方块的表述据此。
- **Wadler, Philip.** "Theorems for Free!" *FPCA 1989*. 参数多态、自然性与自由定理的关系；
  7.3.1 的限定以第 6 章关于 $\bot$ 的结论为界。
- **Danielsson, Nils Anders; Hughes, John; Jansson, Patrik; Gibbons, Jeremy.** "Fast and Loose
  Reasoning is Morally Correct." *POPL 2006*. 在含 $\bot$ 的 Haskell 中使用全函数等式推理的
  条件。
- **Abramsky, Samson; Jung, Achim.** "Domain Theory." In *Handbook of Logic in Computer
  Science*, Volume 3. Clarendon Press, 1994. CPO、连续函数、最小不动点；把 $\bot$ 纳入语义的
  标准做法。
- **`base` 文档**：[`Data.Functor`](https://hackage.haskell.org/package/base/docs/Data-Functor.html)
  及 `Maybe`、列表、函数类型、`Const` 的实例。两条定律由文档说明，但不由编译器检查。
