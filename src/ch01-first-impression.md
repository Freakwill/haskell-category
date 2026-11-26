# 第 1 章 Haskell 初体验

> 状态：试写稿 ｜ 目标 1.2 万字 ｜ 代码：`code/src/Ch01/Tour.hs`、`Hello.hs`

本章先用一个最小脚本熟悉 Haskell 的基本语法与 GHCi（1.1 节）；再用同一个求值器演示三种
写法：Python 的 `isinstance` 派发、抽象基类、Haskell 的 `data` 加模式匹配（1.2 节），并在
1.3 节比较三种实现的取舍，引出"表达问题"。1.4 节把比较延伸到状态处理与 C、Go、Scala；1.5 节看函数式语言内部的差异、Haskell 的近亲与各家 REPL；1.6 节讲惰性求值与副作用。读完本章应能区分：Haskell 与 Python 的差别主要不在语法，而在类型系统的检查能力与默认
求值方式。语法细节、类型类规则与范畴论留到后续章节。

## 1.1 脚本与 GHCi

### 脚本
Haskell 程序由一组**定义**组成：先写类型签名，再写实现。一个最小的脚本：

```haskell
{{#include ../code/src/Ch01/Hello.hs:hello}}
```

`double :: Int -> Int` 是签名，读作"double 把 `Int` 映射到 `Int`"；`main :: IO ()` 是程序
入口，此处只需知道它是"执行后返回 `()` 的动作"，`IO` 的类型与组合规则在工程各章随用随讲。运行：

```text
$ runghc code/src/Ch01/Hello.hs
42
```

这个例子让初学者快速了解 Haskell 的基本语法。本书不追求语法细节的完整覆盖。缩进规则、`let` 的完整规则、模块头语法等，第 2–4 章按"够用"原则引入；写代码时以编译器报错为准，具体语法需要时查手册即可。

### GHCi 用法与注意事项
交互地试一行定义、查一个类型，用 **GHCi**（Haskell 的 REPL）：

```text
ghci> :l code/src/Ch01/Hello.hs
ghci> double 21
42
ghci> :t double
double :: Int -> Int
```

在 GHCi 中，每行以 `ghci>` 开头等待输入；以 `:` 开头的词是命令而非表达式：`:l`（load）加载
文件，`:t`（type）查类型，`:i`（info）看定义，`:r`（reload）重新加载。上面第三行输出
`double :: Int -> Int`：`::` 读作"具有类型"，这一行是签名，不是运行结果。GHCi 对每个输入
表达式求值后立即打印其值，因此 `double 21` 的下一行就是 `42`。

使用中有几件事需要注意。GHCi 里的 `let` 是定义不是赋值：重复 `let x = 1` 再 `let x = 2` 是
遮蔽（shadowing），两个 `x` 并存、旧定义不受影响，1.4.1 节"没有可变变量，只有定义"在 REPL
里同样成立。跨行的定义要包在 `:{ ... :}` 里（或 `:set +m`），否则函数体写不下一行时直接
回车，GHCi 会提前对已输入的部分求值。函数本身不能打印：`ghci> id` 报错
`No instance for (Show (a0 -> a0))`，因为函数没有显示方式。惰性只推迟计算、不推迟打印：
`[1..]` 不会挂起，但 `print [1..]` 会无限输出（1.6 节）。

## 1.2 一个求值器

任务是：给定一棵算术表达式树，求出它的值。

用 Python 实现，最直接的写法是四个只保存字段的类，加一个用 `isinstance` 判断形状的函数。

### 第一种实现：isinstance 派发

```python
class Lit:
    def __init__(self, n): self.n = n

class Add:
    def __init__(self, a, b): self.a, self.b = a, b

class Mul:
    def __init__(self, a, b): self.a, self.b = a, b

class Neg:
    def __init__(self, a): self.a = a

def evaluate(e):
    if isinstance(e, Lit): return e.n
    if isinstance(e, Add): return evaluate(e.a) + evaluate(e.b)
    if isinstance(e, Mul): return evaluate(e.a) * evaluate(e.b)
    if isinstance(e, Neg): return -evaluate(e.a)
    raise TypeError(f"unknown expression: {e!r}")

print(evaluate(Mul(Lit(6), Add(Lit(2), Lit(3)))))   # 30
```

输出 `30`（`code/python/eval_naive.py`，CI 中执行）。

这段代码的结构与后面的 Haskell 版本基本相同：都是一个函数按形状分支。区别不在结构，而在谁
保证分支完整。`isinstance` 链依赖运行时反射，Python 并不知道 `Expr` 有几种形状（这里也没有
`Expr` 这个类型），因此最后一行 `raise TypeError` 承担了本应由编译器承担的工作。

### 第二种实现：抽象基类

Python 也可以写成抽象基类加方法分派，`if` 链随之消失：

```python
from abc import ABC, abstractmethod


class Node(ABC):
    @abstractmethod
    def eval(self) -> int: ...

class Lit(Node):
    def __init__(self, n: int) -> None: self.n = n

    def eval(self) -> int:
        return self.n

class Add(Node):
    def __init__(self, a: Node, b: Node) -> None: self.a, self.b = a, b

    def eval(self) -> int:
        return self.a.eval() + self.b.eval()
```

`Mul`、`Neg` 同理，完整文件在 `code/python/eval_oop.py`。

`Mul(Lit(6), Add(Lit(2), Lit(3))).eval()` 同样得到 `30`。每个类只处理自己那一种形状，增加
一种节点只需写一个类，其余代码不变。这是相对第一种实现的实质改进。

但这种实现仍有代价，只是代价转移到别处：

- **一个操作被拆分到四个类中。** `eval` 的定义分散在各处，阅读时需要来回跳转；修改语义
  （例如除法取整还是取浮点）需逐一修改。
- **增加一种操作仍需改动每个类。** 1.3.3 节增加 `pretty` 时，四个类各要写一个方法。
- **"共有哪些形状"仍无一处完整写出。** `Node` 只知道自己是基类，不知道有多少子类；
  `isinstance` 与 `issubclass` 也提供不了这一信息。
- **类型注解无法补足。** mypy 检查的是"每个类都实现了 `eval`"，不是"处理了所有形状"，
  其能力边界与抽象基类相同。

第二种实现得到的是"增加节点容易"与"以对象组织代码"，没有获得"编译器掌握全部情况"。

### Haskell 实现

先定义表达式有哪些形状：

```haskell
{{#include ../code/src/Ch01/Tour.hs:expr}}
```

一行 `data` 声明了四种情况。`Lit Int` 是叶子，`Add Expr Expr` 是两个子表达式的组合，
`deriving (Eq, Show)` 由编译器生成相等判断与打印函数。Python 中若要 `__eq__` 与 `__repr__`
通常需自行编写（`@dataclass` 可代为生成，但那是标准库的功能，不属于语言本身）。

求值：

```haskell
{{#include ../code/src/Ch01/Tour.hs:eval}}
```

四个方程，每行左侧一个形状，右侧一个结果。没有 `return`，没有 `isinstance`，也没有兜底异常。
使用方式：

```haskell
{{#include ../code/src/Ch01/Tour.hs:demoExpr}}
```

`eval demoExpr` 得到 `30`。这些代码位于 `code/`，每次提交由 GHC 编译、由 hspec 断言，书中
引用的每一行都可运行。

三种写法并排：

| | 形状写在哪 | 一个操作写在几个地方 | 漏了一种，谁知道 |
|---|---|---|---|
| Python 第一种 | 四个哑类 + `isinstance` 链 | 一处，靠运行时反射 | 运行时抛 `TypeError` |
| Python 第二种 | 四个类，各自一个方法 | 四处，每个类一处 | 实例化时，抽象基类拦截 |
| Haskell | 一处 `data` 声明 | 一处，一个函数 | 编译时，并给出名字 |

表 1.1 有两点需要注意。第一，Python 两种写法的差别只在第二列，即操作写在一处还是四处，这属于代码组织问题。第二，Haskell 多出的能力在第三列，即穷尽性由编译器保证，这属于检查问题。
两者正交：操作放在哪里，以及谁负责检查完整性。

至于哪种更好，取决于代码将来的修改方向。1.3.2 与 1.3.3 节分别沿两个方向各走一遍，
1.3.4 节讨论这一取舍。

## 1.3 三种实现的比较

### 1.3.1 函数体是表达式

Python 的函数体是一串语句：赋值、分支、循环、返回。Haskell 的函数体是一个表达式，
`if`、`case`、`let` 都是表达式，都有值。

因此 Haskell 没有 `return` 语句，函数的值就是最后一个表达式的值。语言也不规定
`eval (Add a b)` 中先算 `a` 还是先算 `b`。

这一规定的实际后果是：函数内部无法修改状态。需要修改时，必须把新状态作为返回值传递。
第 9 章的 State 单子把这一过程封装起来，此处暂不展开。

### 1.3.2 增加节点

假设需要支持除法。以第二种实现为对照（它强于第一种），只需增加一个类：

```python
class Div(Node):
    def __init__(self, a: Node, b: Node) -> None:
        self.a, self.b = a, b

    def eval(self) -> int:
        return self.a.eval() // self.b.eval()
```

其余代码不变，`Div(Lit(7), Lit(2)).eval()` 直接得到 `3`。新类自动成为 `Node` 的子类，
也自动被 `expr.eval()` 使用。

Haskell 中则需要修改数据类型本身：

```haskell
data Expr = Lit Int | Add Expr Expr | Mul Expr Expr | Neg Expr | Div Expr Expr
```

然后用 `-Wall` 编译，GHC 会指出哪些函数遗漏了这一分支。`-Wall` 是 GHC 的编译选项：`-W` 是警告
选项的前缀，`-Wall` 打开其中常用的一批（并非全部，例如 `-Wmissing-export-lists` 不在其内），
负责这一项的是 `-Wincomplete-patterns`。开启方式有三种：命令行 `ghc -Wall`、工程文件里的
`ghc-options: -Wall`、源文件顶部的 `{-# OPTIONS_GHC -Wall #-}`。以下是本机实际输出：

```
ExpressionProblem.hs:12:1: warning: [GHC-62161] [-Wincomplete-patterns]
        Patterns of type 'Expr' not matched: Div _ _
12 | eval (Lit n)   = n

ExpressionProblem.hs:18:1: warning: [GHC-62161] [-Wincomplete-patterns]
        Patterns of type 'Expr' not matched: Div _ _
18 | pretty (Lit n)   = show n
```

两条警告分别对应 `eval` 与 `pretty`，既指出遗漏的存在，也指出遗漏所在的函数与构造子。
这是"类型封闭"的结果：`data` 声明处列出全部构造子，编译器得以逐个核对。

在增加节点这一点上，Python 的实现更省力。下一节改变方向。

### 1.3.3 增加操作

不改动节点，增加一个操作：把表达式打印成中缀字符串（`pretty`）。它不改变求值结果，只是
以另一种形式表示同一棵树。

Haskell 中只需增加一个函数：

```haskell
{{#include ../code/src/Ch01/Tour.hs:pretty}}
```

`pretty demoExpr` 得到 `"(6 * (2 + 3))"`。`Expr` 与 `eval` 均未改动。

Python 中需要在 `Node` 上增加抽象方法，再回到四个类逐一实现：

```python
class Node(ABC):
    @abstractmethod
    def eval(self) -> int: ...
    @abstractmethod
    def pretty(self) -> str: ...


class Lit(Node):
    def __init__(self, n: int) -> None:
        self.n = n

    def eval(self) -> int:
        return self.n

    def pretty(self) -> str:
        return str(self.n)
# Add / Mul / Neg 各来一遍
```

遗漏的实现会被抽象基类拦截，但拦截发生在实例化时：

```
TypeError: Can't instantiate abstract class Broken without an implementation for abstract method 'eval'
```

（该输出由 `code/python/eval_oop.py` 实际产生。）它的能力与边界都需注意：它保证"每个类都
实现了 `eval`"，不保证"处理了所有类"；且错误在 `Broken()` 这一行触发，若该类只在很少的
路径上被构造，问题可能延迟到运行期才暴露。

在增加操作这一点上，Haskell 的实现更省力。需要补充的是，第一种实现在这一方向上的改动量也不大：
再写一个 `pretty(e)` 函数即可。但它仍需自行编写 `isinstance` 链并兜底，且与 `evaluate` 一样
没有任何静态保证。

### 1.3.4 表达问题

两个方向的改动量并列如下：

|  | 增加一种节点 | 增加一种操作 |
|---|---|---|
| Python 的类 | 增加一个类，其余不改 | 每个类都要改 |
| Haskell 的 ADT | 修改定义 + 所有匹配它的函数（编译器列出清单） | 增加一个函数 |

表 1.2 列出的不是优劣，而是选择：代码将来主要沿哪个方向扩展。

- 节点固定、操作会不断增加（求值、打印、类型检查、优化、编译为字节码），适合用 ADT。
  实际编译器多数如此，GHC 本身也是。
- 操作固定、类型会不断增加（例如一个"保存到磁盘"的接口，将来支持更多文件格式），适合用对象。

这一问题称为**表达问题**（the expression problem），没有无代价的解法，只能决定把代价放在
哪一侧。Haskell 与 Python 恰好各在一侧。（名称来历见本章末参考文献。）

Haskell 也能写成对象的形式。把"每个节点自带方法"直接迁移过来，最简单的形式是：

```haskell
data Expr = Expr { eval :: Int }
```

节点在此成为记录：`eval` 是构造时算好的一个 `Int`，形状信息在构造时即被吸收。这条路
（final style 或 Church 编码）可用，也有其适用场合，但它使"同一棵树、多种解释"不再成立：
值的解释在构造时已经确定。

### 1.3.5 函数作为值

Python 同样支持**高阶函数**（higher-order function）：`map`、`filter`、`sorted(key=...)`
都是常用形式。Haskell 的差别不在"是否支持"，而在这是默认的组织方式。

例：把一串数各自平方。

```haskell
squaresOf :: [Int] -> [Int]
squaresOf = map (^ 2)
```

`map (^ 2)` 本身即函数 `[Int] -> [Int]`，右侧无须写参数。Python 中对应写法是列表推导
`[x*x for x in xs]`，或 `lambda` 加 `list(map(...))`；后者可写但不常见，因为嵌套较深。
语言的默认表达方式会影响代码的组织形式。

## 1.4 与命令式语言比较

### 1.4.1 状态

把列表求和，Python 的常见写法：

```python
total = 0
for x in xs:
    total += x
```

包含三个步骤：初始化、循环、累加。`total` 在迭代中多次改变取值，其正确性依赖两个前提：
循环体按顺序执行，且每轮都更新 `total`。

Haskell 写作 `sum xs`，不使用循环。数学上，求和是把 `+` 插入列表元素之间：

```haskell
foldr (+) 0 [1,2,3]   -- 1 + (2 + (3 + 0))
```

（`base` 为性能考虑实际使用严格左折叠 `foldl' (+) 0`，结果相同；必须如此的原因见第 2 章
关于惰性的讨论。）

这里没有计数器，没有"当前值"，也没有"第几次迭代"。

需要区分的是：**Haskell 没有可变变量，只有定义**。`x = 5` 不是把 5 存入 `x`，而是声明从此
`x` 表示 5。`x = x + 1` 能通过类型检查，但它不是赋值，而是递归定义：这个等式没有有限解，
求值得到 $\bot$。需要可变的量时，有两种做法：作为参数显式传递，或用单子封装传递过程（第 9
章）。前者属于数学，后者属于工程，本书两者都会涉及。

C 程序员会问：用指针、`for` 循环与可变数组不也可以吗？可以，但代价是：无法从函数签名判断它
是否会修改传入的参数。Haskell 的类型签名提供了这一保证：`eval :: Expr -> Int` 除了算出那个
`Int`，不做别的事。

### 1.4.2 与 C、Go、Scala 比较

1.3 节比较了 Python 与 Haskell。把 C、Go、Scala 一并纳入，问题仍是同一组：形状如何表达，
谁能增加新形状，遗漏分支时由谁在何时报告。各语言的答案见表 1.3。

| 语言 | 形状怎么表达 | 谁能加新形状 | 漏写分支会怎样 |
|---|---|---|---|
| C | 手写的 `enum` / `union` / `switch` | 任何人（改头文件） | 编译通过；`-Wswitch` 只是提醒 |
| Go | 接口 + type switch | 任何人（实现方法即可） | 编译通过；没有穷尽性检查 |
| Scala | `sealed trait` + `case class` | 只有同文件内（`sealed`） | 编译警告 |
| Haskell | `data Expr = Lit Int \| …` | 只有定义处（封闭） | 编译警告，并列出遗漏的名字 |

**C** 使用手写的 ADT：`enum` 是构造子表，`union` 是负载，`switch` 是**模式匹配**（pattern matching）。技术上它是
封闭的，但任何代码都可以修改头文件增加一个 tag，其他编译单元不会因此重新检查。遗漏分支时
编译器不报告（`-Wswitch` 仅在开启时提醒 enum 少列）。这与其设计定位一致：编译器不替程序员
决定内存布局。

**Go** 的 `interface` 是开放集合：任何类型只要实现相应方法即自动满足，包括尚未编写的类型。
成员在原则上不可枚举，`type switch` 因此没有穷尽性可言：遗漏分支走 `default`，或者什么
也不做。Go 用可检查性换取了可扩展性，这一取舍符合其设计目标。

**Scala** 的 `sealed trait` 将子类限制在同一文件内，非穷尽 `match` 会给出警告，与 GHC 属于
同一类。它的差异在其他方面：默认严格求值、副作用不受限制、类型系统更复杂。下一节讨论。

**Haskell** 的情况已在 1.3.2 节说明：封闭，且由编译器检查。

需要指出的是，上表实际混合了三个独立的问题：

1. **能否穷举？** 形状表能否在一处列完。C 能，但依赖纪律；Go 原则上不能；Scala 与 Haskell
   能，且由语言强制。
2. **由谁在何时检查？** 编译期（Scala、Haskell）、运行时（Python 的抽象基类在实例化时），
   或不做检查（C、Go）。
3. **谁能扩展这张表？** 任何位置（C 的头文件、Go 的接口、Python 的子类），或仅限一处
   （Scala 的 `sealed`、Haskell 的 `data`）。

三者可以独立组合。因此"Haskell 的类型系统更强"这一说法信息量有限；更准确的表述是：Haskell
选择了"可穷举 + 编译期检查 + 单点扩展"，并接受了相应的代价。

最后是 `null`，它不属于上述三项中的任何一项，而是第四件事：类型是否把可能性写全。C 的
`NULL`、Go 的 `nil`、Java 的 `null` 使 `String` 同时表示"有一个字符串"与"什么都没有"，
类型未写全，因此每个调用点都要补一个判断。Haskell 把这一情形写入类型：可能缺失即 `Maybe a`，
取值为 `Just x` 或 `Nothing`，遗漏 `Nothing` 时编译器会提示。第 9、10 章将把 `Maybe` 作为
普通实例处理。

## 1.5 函数式语言及其近亲

这一节把视野从 Haskell 扩展到整个函数式语言家族：先看家族内部三条路线的差异，再看
Haskell 的近亲，最后看各家 REPL 的差别。

### 1.5.1 三条路线

首先需要澄清一点：**函数式不等于静态类型**。Lisp 是函数式语言的源头，默认没有静态类型；
Python 支持类型注解但不强制；Haskell 的 ADT 也不是函数式的必然产物，它来自 Hindley–Milner
类型系统与 ML 家族，Scala 从中借用。函数式与静态类型是两条独立的轴。

三条路线的差别如下。

**Lisp（Scheme / Common Lisp）** 的特点是语言可塑性强。代码即列表，列表即数据，宏可以把
语法改造成任意形式。代价是抽象依赖约定与文档；求值为严格求值（call-by-value），需要惰性时
须使用 `delay` / `force` 或手写 thunk。Lisp 的方向是"语言本身可被改写"，Haskell 不在这一
方向上：它有 Template Haskell，但主流写法不以宏做抽象，而是用类型与类型类。

**Scala** 的特点是渐进落地。它运行在 JVM 上，可与 Java 库互操作，允许从命令式写法开始逐步
转向函数式。默认严格求值，需要惰性时写 `lazy val` 或按名参数（`=> T`）；Haskell 相反，默认
惰性，需要严格时用 `seq` 或 `!`。Scala 的类型系统比 Haskell 更复杂（子类型、`implicit` /
`given`、match types），代价是错误信息往往很长。其 `sealed trait` 加 `case class` 就是 ADT，
`for` 推导式即 Haskell 的 `do`，两项均借鉴自 Haskell 与 ML。

**Haskell** 同时固定了三件事：默认惰性、默认纯、以类型类实现 ad-hoc 多态。三者相互依赖：

- 若允许随处修改状态，惰性求值的时机将影响结果，按需求值不再安全；
- 若默认严格，纯函数仍需规定求值顺序，抽象退化为"先算完再传"；
- 若没有类型类，`+` 只能绑定单一类型，或退回 C++ 式的运算符重载。

因此其他语言中的"Haskell 特性"，多数是这三条的推论，而不是彼此独立的设计选择。

### 1.5.2 Haskell 的近亲

内部路线之外，还有另一类关系：哪些语言直接模仿 Haskell，哪些与 Haskell 共享核心特性。
了解它们的目的不是换用它们，而是分清 Haskell 的哪些部分属于家族共享，哪些是它独有。

**PureScript** 语法与类型系统取自 Haskell（类型类、ADT、`do` 记法），语义独立设计：严格
求值，编译到 JavaScript，无运行时依赖。它在浏览器端保留了 Haskell 的抽象能力，放弃了默认
惰性，换来可预测的性能与较小的产物。

**Elm** 同样是面向前端的纯函数语言，但刻意做小：没有类型类，整个程序由固定的 Elm 架构
（model–update–view）组织。Haskell 用户会熟悉它的语法，却不会把它当作 Haskell 在浏览器上
的移植。

**Frege** 是 JVM 上的 Haskell：把 Haskell 语义搬进 Java 平台并与之互操作。项目已停止开发，
但代表"Haskell 语义、更换运行平台"这条路线；同一条路线上还有 GHCJS 与 Haste，它们把
Haskell（或子集）直接编译为 JavaScript，保留语义，代价是生成代码体积大。

**Clean** 与 Haskell 同源：两者都出自惰性纯函数语言的传统，共享惰性求值、纯函数、代数数据
类型这些核心特性，独立发展至今。Clean 用唯一性类型（uniqueness types）把副作用写进类型，
Haskell 的答案是单子（第 9 章）。

**Idris** 语法接近 Haskell，类型系统强一档：类型可以依赖值（依赖类型），能在类型中写出
"长度为 $n$ 的列表"这类精确性质。第 3 章的 HoTT 讨论是同一方向的数学基础。对 Haskell 读者，
Idris 展示的是"把更多约束交给编译器"的极限。

对照之下，Haskell 独有的部分是默认惰性、以 `IO` 组织副作用，以及 GHC 的工程生态；语法、
ADT、类型类与纯函数则是整个家族共享的面。

### 1.5.3 各家 REPL

1.1 节介绍了 GHCi 的基本用法。把不同语言的 REPL 并排看，差别同样反映语言核心：

- **Python** 的 REPL 同样打印表达式值，差别有两点：Python 允许 `x = x + 1` 这类修改状态的
  语句，GHCi 没有可变变量；Python 打印任何对象（函数显示为 `<function id at 0x...>` 的
  地址形式），Haskell 对没有 `Show` 实例的值直接报错。
- **Node / Lisp** 的 REPL 以表达式为核心，但可以随时就地产生副作用（修改对象、打印）；
  GHCi 中副作用必须显式进入 `IO`：`putStrLn "hi"` 会执行，但对象无法就地修改。
- **ML 系（SML / OCaml）** 的 REPL 与 GHCi 最接近：表达式驱动、静态类型，差别主要在求值
  策略（严格）与模块系统的组织方式。

这些差别不是交互环境的设计选择，而是语言核心（纯函数、无赋值）在 REPL 上的体现。
本书对 REPL 的介绍到此为止：日常使用以脚本运行为主，工程各章的代码都以可编译文件的形式
给出。

## 1.6 惰性求值与副作用

### 惰性

下面这个定义不产生计算，也不会陷入死循环：

```haskell
{{#include ../code/src/Ch01/Tour.hs:lazy}}
```

`[0 ..]` 是全体自然数，`map (^ 2)` 作用其上得到另一个无限长的列表。实际被计算的只有
`take 5` 所需的前五项 `[0,1,4,9,16]`，其余元素从未产生。

Python 中表达同一件事需使用生成器：`(x*x for x in itertools.count())`。区别在于 Python 的
**惰性求值**（lazy evaluation）是局部的（生成器是特殊对象），Haskell 的惰性求值是全局的
（所有值默认按需求值）。这一差别在后文会反复出现：`let xs = [1..]` 为何成立，`undefined`
为何能放进数据结构而不立即出错，以及某些线性算法为何占用大量内存。

惰性有代价。`foldl (+) 0 [1..10^7]` 会先积累一千万层未求值的加法表达式（thunk），再一次性
求值，内存占用可达数 GB；正确写法是严格的 `foldl'`。第 2 章将详述这一问题。此处只需记住：
惰性把求值时机交给运行时，代价由使用者承担。

### 副作用

初学者常见的疑问是：既然函数不能有**副作用**（side effect），`print` 如何解释？

`eval` 的类型是 `Expr -> Int`。签名中没有 `IO`，因此 `eval` 不能打印、不能读文件、不能发起
网络请求，只能算出一个 `Int`。这不是编码约定，而是类型系统强制的结果：要产生副作用，签名中
必须出现 `IO`。

程序的入口是 `main :: IO ()`；其余 `IO` 动作在被接到它上面之前不会执行。`IO` 是类型构造子，
`IO ()` 表示"一个执行动作并返回 `()` 的值"。`putStrLn "hi"` 的类型是 `String -> IO ()`：给定字符串，返回一个动作。
动作本身是值，可以传递、组合、放入列表，但只有接到 `main` 上才会执行。

Haskell 处理副作用的方式不是禁止，而是**把副作用写进类型**，使其在签名上可见。编译器因此
可以判断哪些函数是纯的；纯函数可以被重排、缓存、并行与内联。第 8 章之后将说明，正是这一性质
使"以组合替代循环"在工程上可行。

## 1.7 总结

本章需要保留的结论有三条：

1. **函数体是表达式**，因此没有语句序列，也没有 `return`；
2. **类型可以封闭**，因此遗漏一种情况会在编译期被发现，代价是增加节点时改动更多；
3. **副作用写在类型里**，一个函数是否纯净可以直接从签名读出。

第 2 章起逐条展开这三点。语法细节、类型类的完整规则、范畴论与真实项目的组织方式分别
留到第 2–4、4、5、11 章。

## 参考文献

本章属于概念综述，没有依赖某一本书的推导，两处关键概念的出处如下：

- **Cook, William R.** "Object-Oriented Programming Versus Abstract Data Types." 1990.
  讨论对象与抽象数据类型取舍的论文；本章 1.3.4 节的分析框架来自此文。
- **Wadler, Philip.** "The Expression Problem." Java Generics 邮件列表，1998.
  "表达问题"这一名称的出处；正文的两轴表可与该邮件中的表述对照。
- **Awodey, Steve.** *Category Theory*, 2nd ed. Oxford University Press, 2006. §1.3。
  本章未展开范畴论，但 1.3 节使用的对象与态射语言与该节定义一致。
- **PureScript 文档**。"[Related Projects](https://github.com/purescript/documentation/blob/master/Related-Projects.md)"。
  1.5 节对派生语言与同源语言的对比据此文档。
