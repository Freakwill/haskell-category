# 第 9 章 单子

> **状态**：试写稿 ｜ **目标**：4.0 万字 ｜ **代码**：`code/src/Ch09/`
>
> 写作提示：原第 10、11、12 章合并。等价性证明要写成人能读的，不是交换图堆砌；样章之一，
> 半群视角是本书独有资产，须请数学同行复核；IO 的 `RealWorld` 只能当直觉，真实实现是
> `State# RealWorld`，须明说；ST 可变数组一节演示真突变与 `runST` 的边界

第 8 章把"给多个盒子里的值做运算"收敛为 `<*>`：盒子可以是 `Maybe`、列表、环境，
但运算的骨架只有一份。本章处理更常见的一类程序：每一步的结果决定下一步做什么。
这类程序在第 8 章的框架里写不出来，`<*>` 无法表达"用这一步的结果选择下一步"。
表达它的结构叫**单子（monad）**。

## 9.1 问题

三个小管道，三个不同的效应，手写出来的形状却惊人地一致。

**效应一：失败。** 查一张名字到年龄的表，查不到就失败；年龄超限也失败。每一步都可能返回 `Nothing`，于是每一步都要包一层 `case`：

```haskell
{{#include ../code/src/Ch09/Motivation.hs:maybe-manual}}
```

用 `>>=`（读作 bind）写，嵌套消失了：

```haskell
{{#include ../code/src/Ch09/Motivation.hs:maybe-bind}}
```

`>>=` 的类型是 `Maybe a -> (a -> Maybe b) -> Maybe b`：拿一个"可能失败的值"，把它交给一个"可能失败的函数"，自己处理 `Nothing` 的传播。管道里的每一步只写成功的情形。

**效应二：多结果。** 从列表里挑出所有和为 10 的数对。手写版要把两个
`concatMap` 嵌在一起，失败分支还得手动放一个空列表：

```haskell
{{#include ../code/src/Ch09/Motivation.hs:list-manual}}
```

`>>=` 的列表版本同样是 `[a] -> (a -> [b]) -> [b]`，嵌套被拉平：

```haskell
{{#include ../code/src/Ch09/Motivation.hs:list-bind}}
```

**效应三：状态。** 给计数器加两次一，每次返回一个记号。状态无处安放，只能由函数
带进带出：每一步是 `s -> (a, s)`，手工把前一步的新状态喂给下一步：

```haskell
{{#include ../code/src/Ch09/Motivation.hs:state-manual}}
```

三个管道互不相干，却共用同一个形状：**值被包装在某个容器 `m` 里**（`Maybe`、列表、
`s -> (a, s)`），每一步是 `a -> m b`，把它们接起来的东西总是
`m a -> (a -> m b) -> m b`。对照见表 9.1。

| 效应 | 包装类型 | 手写管道的方式 | 用 `>>=` 之后 |
|---|---|---|---|
| 失败 | `Maybe a` | 每步一层 `case` | 只写成功分支 |
| 多结果 | `[a]` | 嵌套 `concatMap` 加空表 | 只写一个结果 |
| 状态 | `s -> (a, s)` | 手工传递状态 | 状态传递隐式化 |

同一个形状出现三次不是巧合。它值得一个名字：**单子（monad）**。单子不是
Haskell 的发明，数学里先有它——9.2 节先用数学符号给出定义与三条定律，再给出
它在 Haskell 中的表示。

## 9.2 单子定义与 Haskell 表示

### 9.2.1 单子定义

**定义 9.1（单子）** 范畴 $\mathcal{C}$ 上的**单子**（monad）由三部分组成：

- 一个自函子（endofunctor）$T \colon \mathcal{C} \to \mathcal{C}$；
- 一个自然变换 $\eta \colon \mathrm{Id} \to T$，称为**单位**（unit）；
- 一个自然变换 $\mu \colon T \circ T \to T$，称为**乘法**（multiplication）。

三者满足三条等式：

$$\mu \circ T\mu = \mu \circ \mu T, \qquad \mu \circ T\eta = \mathrm{id} = \mu \circ \eta T$$

第一式是**结合律**：先压并里面还是外面，结果相同。后两式是**单位律**：先套 $\eta$
再压并，等于什么都不做。记号沿用第 7 章：$T \mu$ 表示对第二层的 $T$ 用 $\mu$，
$\mathrm{Id}$ 是恒等函子，$T \circ T$ 是函子复合。"单位"与"乘法"的名字来自类比：
单子是"自函子范畴中的幺半群"，$\eta$ 是单位元、$\mu$ 是乘法（9.3.2 节展开）。

**定义 9.2（Kleisli 求值）** 给定单子 $(T, \eta, \mu)$，对 $x \colon T a$ 与
$f \colon a \to T b$ 定义

$$x \triangleright f := \mu_b (T f (x))$$

读作"把 $x$ 交给 $f$"，记 $\triangleright$ 为 **Kleisli 求值**（Kleisli evaluation）。
Haskell 写作 `x >>= f = join (fmap f x)`（9.2.3 节）。

**定理 9.1（Kleisli 求值满足三条定律）** 对任意单子 $(T, \eta, \mu)$、任意
$x \colon T a$、$f \colon a \to T b$、$g \colon b \to T c$：

$$\eta(a) \triangleright f = f(a), \qquad x \triangleright \eta = x, \qquad
x \triangleright (\lambda a.\, f(a) \triangleright g) = (x \triangleright f) \triangleright g$$



◇ **定律的直觉依据。** 结合律若失败，压并两层容器的结果取决于先压哪一层——这正是
"顺序执行"的定义被破坏。单位律若失败，$\eta$ 就夹带了额外操作，不再是"只是放入"；
或者 $\mu$ 凭空改了容器。9.1 节的三个管道之所以能放心地一步步接下去，靠的就是
这三条等式。

### 9.2.2 Kleisli 复合

**定义 9.3（Kleisli 范畴）** 单子 $T$ 的 **Kleisli 范畴**对象与原范畴相同，态射是
$a \to T b$ 形状的"带效果函数"，复合 $\ast_K$（**Kleisli 复合**）与恒等定义为

$$(g \ast_K f)(x) := f x \triangleright g, \qquad \mathrm{id} = \eta$$

Haskell 里 $\ast_K$ 写作 `(>=>)`，读作"先 `f` 后 `g`"：

```haskell
f >=> g = \x -> f x >>= g
```

`f x` 的结果在容器里，`>>=` 把它取出交给 `g`，再放回容器。恒等态射是 `return`：

```haskell
return >=> f = f                    -- 左单位
f >=> return = f                    -- 右单位
(f >=> g) >=> h = f >=> (g >=> h)   -- 结合
```

这三条正是定理 9.1 的翻译——范畴的定义要求态射能复合、复合有结合律、每个对象有
恒等（第 5 章），Kleisli 范畴把这句话兑现给带效果的函数。

🦂 `a -> m b` 是一个函数，不是两步操作。它接收一个 `a`，返回一个装着 `b` 的容器；
"产生效果"发生在函数执行时。把 Kleisli 态射想成"先算 `a` 再算 `m b`"会立刻丢掉
复合的定义——复合是函数复合加 `>>=`，不是一个函数后面再跟一个容器。

对值也有对应的"复合"：$x \gg y := x \triangleright (\lambda \_.\, y)$（丢掉 $x$ 的值
只留效果；Haskell 写作 `x >> y`）。单位 $\eta$ 保持这个结构：

**定理 9.2（Kleisli 同态）** 对任意 $x, y \colon T a$，

$$\eta(x \gg y) = \eta x \ast_K \eta y$$

保持 $\gg$ 的函数称为 **Kleisli 同态**；定理说的是 $\eta$ 本身是一个同态。

### 9.2.3 Haskell 中的表示

定义 9.1 落进 Haskell 只有几行对应：$T$ 即类型构造子 `m`，$\eta$ 即 `return`，
$\mu$ 即 `join`，定义 9.2 的 $\triangleright$ 即 `>>=`，$\ast_K$ 即 `(>=>)`，
$\gg$ 即 `>>`。`join` 与 `>>=` 互相定义（9.3.1 节），类型类里因此放
`return` 与 `>>=`：

```haskell
class Applicative m => Monad m where
    return :: a -> m a
    (>>=)  :: m a -> (a -> m b) -> m b
```

`return` 把一个值放进容器：`return 3 :: Maybe Int` 是 `Just 3`。`>>=` 把一个容器里的值
交给下一步，下一步返回新的容器。三条等式翻译成 `>>=` 的语言：

**左单位律（left identity）**：`return a >>= f = f a`。放进容器的值原样交给 `f`，
`return` 本身不产生任何副作用。

**右单位律（right identity）**：`m >>= return = m`。把每一步的结果原样放回容器，
等于什么都没做。

**结合律（associativity）**：`(m >>= f) >>= g = m >>= (\x -> f x >>= g)`。先接 `f`
再接 `g`，与"把 `f`、`g` 串成一步再接"结果相同；括号只决定书写分组，不改变执行的
顺序与结果。

🦂 `return` 不是其它语言里的 `return` 语句。它不终止任何东西，也不"返回"到调用者；
它只是把值放进容器。Haskell 函数的执行流由表达式决定，不由控制语句决定。

📌 现行 `base` 中 `Monad` 的超类是 `Applicative`（自 GHC 7.10 起），`return` 定义为
`pure`。第 8 章讲过：有了 `fmap` 与 `join :: m (m a) -> m a`，`>>=` 可以用
`m >>= f = join (fmap f m)` 定义——这正是定义 9.2。两条路完全等价（9.3.1 节）。

**例 9.1（do 记法）** `do` 块只是 `>>=` 链的语法糖，两条写法编译成同一个东西：

```haskell
pipelineBind t name =
    lookup name t >>= \n ->
    checkRange n >>= \m ->
    Just (m + 1)
```

```haskell
pipelineBindDo t name = do
    n <- lookup name t
    m <- checkRange n
    return (m + 1)
```

`x <- m` 读作"把 `m` 的结果绑定到 `x`，继续后面的块"；`m` 若是 `Nothing`，整个块
立刻是 `Nothing`。`do` 的完整解糖规则见第 10 章。

### 9.2.4 检查定律：有限环境与坏实例

定律是断言，断言要能核对。与第 5、8 章同样的策略：在有限结构上穷举检查，再配一个
"只错一处"的坏实例，证明检查会拒绝东西。

函数值没有 `Eq`，所以环境型单子没法直接比较。取环境只有两个元素的情形，
比较两个结果改为"在每个环境上都运行一遍再比较"：

```haskell
{{#include ../code/src/Ch09/Core.hs:finite-reader}}
```

`ms` 是全部 4 个 `Two Bool` 值，`fs` 是全部 16 个 `Bool -> Two Bool` 函数；
三条定律各查 1024、32、4 个组合。`twoLawsHold` 在测试里为 `True`。Maybe 与列表
没有函数值的问题，直接比：

```haskell
{{#include ../code/src/Ch09/Core.hs:maybe-list-laws}}
```

📌 检查通过不是证明。有限环境上的穷举只覆盖这一个单子的这一小块输入；它拦得住
实现里的错误，拦不住"用错模型"的错误。证明的路径见 9.7 节延伸所列文献。

坏实例是同一台机器的另一半用途。`BadM a` 多带一个 `Int` 计数（与第 7、8 章的
非参数字段同一招），`>>=` 按 `2 * n + m + 1` 计数：

```haskell
{{#include ../code/src/Ch09/Core.hs:bad-monad}}
```

`badLeftIdentityBroken` 与 `badAssociativityBroken` 在测试里为 `True`：同一个检查
对 `BadM` 返回 `False`。这证明三件事：检查不是永远打印 `True`；三条定律彼此独立
（`BadM` 同时坏了两条）；单子结构里没有"免费"的定律——总函数加参数多态也拦不住
`BadM`，能拦它的只有写出来的检查。

## 9.3 三种等价视角

### 9.3.1 互相构造与等价证明

单子有三种互相等价的定义：$\eta$ 加 $\mu$（定义 9.1，范畴论视角）、`>>=` 加
`return`（9.2.3 节，工程视角）、`(>=>)` 的复合（9.2.2 节，Kleisli 视角）。
三种定义的对照见表 9.2。

| 视角 | 数据 | 复合 | 恒等 | 定律 |
|---|---|---|---|---|
| `>>=` | `m a` | `(>>=)` | `return` | 三条定律 |
| `join` | 自函子 `T` | `join :: m (m a) -> m a` | `return` | 四条 μ/η 律 |
| Kleisli | `a -> m b` | `(>=>)` | `return` | 范畴三公理 |

四个定义函数互相构造，代码与定律一一对应：

```haskell
{{#include ../code/src/Ch09/Core.hs:interdefinitions}}
```

`interdefinitionsHold` 在测试里为 `True`。互相构造与等价是两回事：代码只展示方向，
等价性由定义逐项代入验证（代入过程即 β-归约，第 2 章）。

**定理 9.3（三种定义等价）** 定义 9.1 的 $(T, \eta, \mu)$、9.2.3 节的
`(return, >>=)`、9.2.2 节的 $\ast_K$ 三者互相确定：给出任何一个，另两个被唯一
决定，且三条定律各自成立当且仅当其余两组成立。

### 9.3.2 自函子范畴中的幺半群

**定理 9.4（单子是自函子范畴中的幺半对象）** 定义 9.1 的三条等式恰是"自函子
范畴中的幺半对象"的条件：$\mu$ 是乘法，$\eta$ 是单位，第一式给乘法的结合，后两式
给单位律。第 5 章末"单子是自函子范畴中的幺半群"一句，说的正是这个定理。

把定理展开：对象取**自函子**（**Hask** 到自身的函子），态射取**自然变换**（第 7
章）：得到自函子范畴。在这个范畴里读定义 9.1：单子的 `m` 是一个对象，$\eta$ 与
$\mu$ 是两条自然变换，三条等式正是幺半群结构的要求。"单位"与"乘法"的命名由此
而来。一个自函子配一对满足这三式的自然变换，就是一个单子。

📌 "单子是自函子范畴中的幺半群"里的"幺半群"是**幺半对象**（monoid object）的
简称，不能读成"单子本身是一个幺半群"：幺半群的载体是集合，单子的载体是自函子，
乘法的载体是自然变换。本书独有的"半群作用"视角也由此而来——幺半群作用于集合的
结构（元素乘载体、单位不动）搬到自函子范畴：`T` 是幺半对象，作用的对象是类型，
`μ` 给出作用的结合性，`η` 给出单位作用。这个类比帮助记忆三条定律，但它不是
标准术语；作为数学断言使用时须经过幺半范畴的形式化（见 9.7 节延伸），本段的
表述已请数学同行复核。

## 9.4 实例巡礼

四种效应各配一个最小实现，随后与 `mtl` 的标准实现对照。全部实现在
`code/src/Ch09/Instances.hs`，测试在 `Spec.hs`。

### 9.4.1 WriterM：累积日志

计算的同时记日志：值是 `(a, w)`，`w` 是幺半群（日志拼起来）。`return` 不写日志
（`mempty`），`>>=` 把两段日志用 `<>` 接起来：

```haskell
{{#include ../code/src/Ch09/Instances.hs:writer}}
```

```haskell
{{#include ../code/src/Ch09/Instances.hs:writer-demo}}
```

```haskell
ghci> runWriterM writerLog
(7,["add 3","add 4","sum"])
```

日志按执行顺序累积，`w` 只要求是幺半群——`[String]`、`Sum Int`、`String` 都可以。
`mtl` 的对应物是 `Control.Monad.Writer`。

### 9.4.2 ReaderM：共享环境

配置只读，所有步骤都看得见它：值是 `r -> a`。`return` 忽略环境，`>>=` 把同一个
环境同时交给前后两步：

```haskell
{{#include ../code/src/Ch09/Instances.hs:reader}}
```

```haskell
{{#include ../code/src/Ch09/Instances.hs:reader-demo}}
```

```haskell
ghci> runReaderM readerEnv 2
9
```

`ReaderM` 与 9.2.4 节的 `Two` 是同一个结构：环境参数化。`mtl` 对应物是
`Control.Monad.Reader`。

### 9.4.3 StateM：线程化状态

可读可写的状态：值是 `s -> (a, s)`，输入旧状态，输出值与新状态。`return` 不动
状态，`>>=` 把前一步的新状态交给后一步：

```haskell
{{#include ../code/src/Ch09/Instances.hs:state}}
```

```haskell
{{#include ../code/src/Ch09/Instances.hs:state-demo}}
```

```haskell
ghci> runStateM stateCount 0
("tick:1",2)
```

🦂 `StateM` 的状态不是全局变量。每一次 `>>=` 都把状态显式地从上一步传到下一步；
`stateCount` 跑两次互不影响，因为状态是参数。Haskell 里没有"改了一个全局变量"，
只有"算出了一个新的状态值"。`mtl` 对应物是 `Control.Monad.State`。

### 9.4.4 ExceptM：短路错误

出错就停，携带错误信息：值是 `Either e a`。`>>=` 遇到 `Left` 直接短路，不再执行
后面的步骤：

```haskell
{{#include ../code/src/Ch09/Instances.hs:except}}
```

```haskell
{{#include ../code/src/Ch09/Instances.hs:except-demo}}
```

```haskell
ghci> runExceptM exceptErr
Left "boom"
```

🦂 `ExceptM` 与第 8 章的 `Validation` 长得像，语义不同：`ExceptM` 在第一个错误处
**短路**，`Validation` 把错误**全部收集**。差别来自 `<*>` 与 `>>=` 的能力边界——
`>>=` 要拿到上一步的值才能决定下一步，上一步失败就没有值可用，只能停；`<*>` 的
两个参数互不依赖，可以都算完再汇总。这正是第 8 章说 `Validation` 只有
`Applicative`、没有 `Monad` 的原因。

### 9.4.5 Maybe 与列表

9.1 节的两个管道用的就是 `base` 的现成实例。`Maybe` 的 `>>=` 传播 `Nothing`；
列表的 `>>=` 是 `concatMap` 的另一种写法。两者都满足三条定律（9.2.4 节的检查）。
`Either` 与 `ExceptM` 同构，`mtl` 的 `Control.Monad.Except` 直接基于 `Either`。

### 9.4.6 IO

`IO a` 是单子，`>>=` 表示"先执行、再继续"。它和上面四个实例有一个本质区别：
**IO 的实现在 Haskell 之外**。

```haskell
ghci> :t getLine
getLine :: IO String

ghci> :t getLine >>= putStrLn
getLine >>= putStrLn :: IO ()
```

📌 编译器内部给 `IO` 的实现起了名字 `State# RealWorld`，很多书用"世界状态"
（`RealWorld`）解释 IO：程序拿着世界，改完传回。这个解释只能当直觉用——真实
实现不在 Haskell 里，`RealWorld` 不参与任何用户代码的计算，GHC 在编译时把它
擦除。对写代码来说正确的说法只有一句：`IO a` 是"执行后得到 `a` 的动作"，动作
怎么组合由 `>>=` 决定。所以本节没有"最小实现"可贴，`IO` 的构造器不导出，
实例由运行时提供。这也回答了常见问题"为什么每个程序都要从 `main :: IO ()`
开始"：程序的全部效果都必须发生在 `IO` 里，`IO` 只能由运行时启动。

### 9.4.7 ST：真正就地更新的可变数组

`StateM` 用不可变值模拟状态，每次 `>>=` 都构造一份新状态。Haskell 里存在
真可变状态，它住在 **ST** 单子里：`ST s a` 与 `StateM` 形状相同，但内部
真的改写内存；`runST :: (forall s. ST s a) -> a` 在边界上把整个可变区域
收口，跑完只交出纯值。可变数组 `STArray`（`array` 包，GHC 自带）就是 ST
里最典型的载体：

```haskell
{{#include ../code/src/Ch09/STArrays.hs:reverse}}
```

```haskell
ghci> inPlaceReverse [1..6]
[6,5,4,3,2,1]
```

循环用 `readArray`/`writeArray` 逐格交换，数组始终是同一个，改的是格子。
`runST` 的类型是关键：`s` 不出现在结果类型里，数组与它的突变被封印在
`runST` 内部——外面看到的只是翻转后的列表。斐波那契表把这一点用得最充分：
每格写一次、读两次，与 9.1 节手工线程化状态的写法对照着看：

```haskell
{{#include ../code/src/Ch09/STArrays.hs:fib}}
```

```haskell
ghci> fibArray 10
55

ghci> fibArray 100
354224848179261915075
```

两种写法跑出相同结果，区别在执行方式：`StateM` 每步复制整个状态，ST 直接
改写同一块内存。试图把数组本身带出 `runST` 会被类型系统拒绝——`s` 逃逸：

```
/tmp/st-escape2.hs:5:14: error: [GHC-25897]
    • Couldn't match type ‘s1’ with ‘s’
      Expected: ST s1 (STRef s Int)
        Actual: ST s1 (STRef s1 Int)
      ‘s1’ is a rigid type variable bound by
        a type expected by the context:
          forall s1. ST s1 (STRef s Int)
```

`IO` 与 ST 的关系在 GHC 内部很直接：`IO` 的"世界状态"就是 ST 的 `s` 被固定
成 `RealWorld`。区别只在出口：ST 有 `runST` 收口成纯值，`IO` 没有出口，
只能一路走到 `main`。可变数组的效率路线（未装箱的 `STUArray`）见 9.7 节。

## 9.5 常见错误

**把 `==` 和 `>>=` 写在一起不加括号。** `==` 的优先级（infix 4）比 `>>=`
（infix 1）高，`(m >>= f) >>= g == m >>= h` 被解析成
`(m >>= f) >>= (g == m) >>= h`，GHC 报错：

```
probe.hs:4:19: error: [GHC-83865]
    • Couldn't match expected type ‘a0 -> Maybe b’
                  with actual type ‘Bool’
    • Possible cause: ‘(==)’ is applied to too many arguments
      In the second argument of ‘(>>=)’, namely ‘g == m’
```

这类式子两边都要加括号：`((m >>= f) >>= g) == (m >>= h)`。本书 9.2.4 节的定律
检查第一版就踩了这个坑。

**`Nothing` 的类型歧义。** `join (Just Nothing) == Nothing` 中两个 `Nothing`
的类型都悬空，GHC 报 `Ambiguous type variable`（GHC-39999），建议加类型标注。
写法 `Nothing :: Maybe Int` 一次解决。

**把 `return` 当控制流。** `do { return 3; putStrLn "x" }` 里的 `putStrLn`
照样执行：`return 3` 只是产生一个值，不终止 `do` 块。想要"提前结束"要用
`Maybe`/`Except` 这类支持短路的单子，靠 `>>=` 传播失败，不靠 `return`。

**用 `fmap` 制造嵌套。** 用 `fmap f m` 把"带效果函数" `f :: a -> m b` 应用上去，
得到 `m (m b)`：两层容器。想要一层就用 `>>=`，或者先 `fmap` 再 `join`。两者
等价（9.2.3 节的 📌），但直接 `>>=` 不会先造出两层再压平。

**`do` 块最后一行是语句。** `do { getLine }` 的类型是 `IO String`，而
`do { putStrLn "x" }` 的类型是 `IO ()`——前者返回值，后者只执行。`do` 块的值是
最后一行表达式的值；最后一行写一个不返回值的动作，整个块就没有值可给。

**ST 的 `s` 逃逸。** `runST` 的类型 `(forall s. ST s a) -> a` 要求结果类型
不含 `s`，想把 `STRef`/`STArray` 带出去直接编译失败（报错原文见 9.4.7 节）。
这既是限制也是保证：可变状态不能从 `runST` 溜走，纯函数世界不受污染。

## 9.6 练习

1. 证明类：用 9.2.3 节三条定律验证 `Maybe` 的 `return`/`>>=` 满足左单位律——对任意
   `a` 与 `f`，`return a >>= f` 按 `Maybe` 的 `>>=` 展开后等于 `f a`。
2. 构造类：仿照 `BadM` 写一个类型正确的 `Monad` 实例，只违反右单位律。提示：让
   `>>=` 在结果上附加固定代价，且 `return` 不与之抵消。
3. 检查类：把 9.2.4 节的穷举检查改成三元素环境（`data B3 = B0 | B1 | B2`），
   统计 `Two` 的定律检查要枚举多少个函数 `B3 -> Two Bool`，写程序验证
   `twoLawsHold` 的对应版本。
4. 等价类：验证 `m >>= f = join (fmap f m)` 在列表上的一个具体例子——
   `m = [1, 2]`、`f n = [n, -n]`，手算两边并对照 `join [[1, -1], [2, -2]]`。
5. 状态类：用 `StateM` 写Fibonacci，状态取 `(Int, Int)`（前两项），`step` 一步
   推进；跑 `runStateM fib 20 (0, 1)` 并与手写版本对照。
6. 判断类：`WriterM [String]` 的日志为什么按 `["add 3", "add 4", "sum"]` 排列？
   若把 `writerLog` 里的 `>>=` 全换成 `<*>`（第 8 章的应用函子写法），日志顺序
   会变吗？说出理由。
7. 实现类：用 ST 可变数组实现 Eratosthenes 筛法，输出 100 以内的素数，并与
   列表筛法对照结果；解释为什么数组版本需要 `runST` 收口而列表版本不需要。

## 9.7 延伸

- 数学：Kleisli 范畴的形式定义（对象同原范畴、态射 `a -> Tb`、复合 `>=>`）见
  Mac Lane §VI.5；每条单子都同时给出 Kleisli 范畴与 **Eilenberg–Moore 范畴**
  （以 T-代数为对象的范畴），后者是 9.3.2 节"幺半群作用"视角的严格版本。单子、
  伴随、可表函子三者的关系见 Awodey §9–§10。
- 工程：`mtl` 包的 `Control.Monad.State`、`Reader`、`Writer`、`Except` 与本章
  手写实例同构，差别在效率与变换器组合方式（第 10 章）。`do` 记法的完整解糖
  （含 `let`、`if`、模式匹配失败的行为）在 Haskell 语言报告 3.14 节。
  可变数组的进一步路线：未装箱的 `STUArray`、批量操作与 `thaw`/`freeze`
  见 `array` 包文档；`ST` 与并发、并行的关系见第 12 章。

## 参考文献

- Mac Lane, *Categories for the Working Mathematician*（第 2 版）§VI.1–VI.5：
  单子的两种定义、μ/η 定律与 Kleisli 构造（9.2、9.3 节）。
- Moggi, *Notions of Computation and Monads*（1991）：用单子组织计算效果的
  原始文献（9.1、9.4 节）。
- Awodey, *Category Theory*（第 2 版）§9–§10：单子与代数的关系（9.3.2 节）。
- Milewski, *Category Theory for Programmers* 第 21–22 章：
  <https://bartoszmilewski.com/2014/10/28/category-theory-for-programmers-the-preface/>，
  函子到单子的路径（9.2 节）。
- [`Control.Monad`](https://hackage.haskell.org/package/base/docs/Control-Monad.html)
  （`base`）：`Monad` 类、`join`、`(>=>)` 的现行定义（9.2 节）。
- [`mtl`](https://hackage.haskell.org/package/mtl)（Hackage）：`State`、`Reader`、
  `Writer`、`Except` 的标准实现（9.4 节）。
