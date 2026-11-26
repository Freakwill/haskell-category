# 第 4 章 类型类：ad-hoc 多态

> 状态：试写稿 ｜ 目标 1.4 万字 ｜ 代码：`code/src/Ch04/TypeClass.hs`

第 2 章的 `id :: a -> a` 对每个类型做同一件事。本章处理另一种情形：同一个名字，对不同类型
做不同的事。这类多态在 Haskell 里由**类型类**（type class）承担。本章说明它的语法、它与
面向对象接口的差别，以及它的约束在类型论中是什么。

## 4.1 问题：两种多态

先区分两件事。

```haskell
id :: a -> a
id x = x
```

`id` 只有一份实现，参数类型由调用点决定。这称为**参数多态**（parametric polymorphism）：
一个定义，适用于所有类型，行为与类型无关。

```haskell
(==) :: Eq a => a -> a -> Bool
```

`(==)` 的行为依类型而变：整数比较数值，字符串逐字符比较，自定义类型按声明决定。这称为
**ad-hoc 多态**（ad-hoc polymorphism）：同一个名字配多份实现，由类型选择。参数多态无法
表达这件事——`id` 只有一种行为可写。

### 4.1.1 Python（等其他语言）实现

Python 用三种方式处理"按类型选实现"。

**第一种：鸭子类型。** 只要有 `describe` 方法就能调用，签名里不写任何约束。

```python
{{#include ../code/python/describe_dispatch.py:duck}}
```

运行 `describe_duck(WithoutDescribe())` 得到：

```
AttributeError: 'WithoutDescribe' object has no attribute 'describe'
```

错误在调用时发生，而且发生在被调函数内部，堆栈指向 `x.describe()` 这一行，不指向调用点。
调用者无法从签名判断需要什么。

**第二种：`Protocol`。** 用类型标注描述结构要求，供静态检查器使用。

```python
{{#include ../code/python/describe_dispatch.py:protocol}}
```

`def f(x: Describable) -> str` 现在能说明 x 需要什么。但协议只作用于类型检查，运行时没有任何
变化：传一个不带 `describe` 的对象仍然能通过，直到调用时才失败。

**第三种：`singledispatch`。** 这才是 ad-hoc 多态的直接对应物：按第一个参数的类型查表，
选择实现。

```python
{{#include ../code/python/describe_dispatch.py:dispatch}}
```

运行：

```
$ python3 code/python/describe_dispatch.py
true
[true, false]
TypeError: no description for int
```

三行分别对应 `describe(True)`、`describe([True, False])`、`describe(3)`。列表的实现递归调用
`describe`，因此元素类型也必须注册过，否则落到默认分支。这三点与 Haskell 的对应关系如下：

| | 何时决定实现 | 遗漏一项时 | 能否对类型构造器抽象 |
|---|---|---|---|
| 鸭子类型 | 调用时（属性查找） | 调用时 `AttributeError` | 不能 |
| `Protocol` | 静态检查时 | 检查器报错，运行时不报 | 不能 |
| `singledispatch` | 调用时（查注册表） | 调用时落到默认分支 | 不能 |

第三列是关键。`Container f` 要对"任意的容器类型构造器"写一份实现，而 Python 的类型系统里
没有高阶类型。类型变量只能代表类型：`int`、`str`、`list[int]` 是类型，裸的 `list` 不是
类型，因此不能作为类型变量的取值被抽象——`list` 必须先拿到参数才成为类型。这并不是语法
缺失，是类型系统的表达力边界。

### 4.1.2 Haskell 实现

Haskell 把"某类型支持哪些操作"写成一个类：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:describe-class}}
```

`class` 声明两个方法：`describe` 必须有实现，`describeAll` 给了默认实现（`map describe`），
实例可以覆盖它，也可以不管。

实例用 `instance` 声明，可以依赖别的约束：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:describe-maybe}}
```

这段 `instance` 声明的意思是：只要元素类型可描述，`Maybe` 与列表就可描述。这不是继承，而是**约束的传播**：
使用 `describe (Just True)` 时，编译器需要 `Describable Bool`，而它来自更早的那个实例。

约束写在类型签名里，是类型的一部分：

```haskell
describeAll :: Describable a => [a] -> [String]
```

读法是：对任意类型 `a`，若 `a` 是 `Describable` 的实例，则本函数可用。调用点必须能提供这个
证据，否则编译失败。这与 Python 三种写法都不同：判断发生在编译期，且证据沿调用链传递。

## 4.2 类的语法

**超类约束。** 类可以要求实例先满足另一个类：

```haskell
class Eq a => Ord a where
    compare :: a -> a -> Ordering
```

`Ord` 的每个实例必须先是 `Eq` 的实例。这条要求写在类头上，因此任何使用 `Ord` 的地方都自动获得 `Eq` 的能力。

**对类型构造器抽象。** 类的参数不限于具体类型，也可以是类型构造器：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:container}}
```

`f` 在 `class Container f` 中代表一个类型构造器，`empty :: f a` 对任意 `a` 成立。`[]` 的实例
把 `f` 取为列表构造器。这正是 Python 三种写法都无法表达的部分。

**实例与类型的对应关系。** 一个类可以有多个互不相干的实例，实例之间没有子类型关系：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:area-class}}
```

`Shape` 与 `Side` 之间没有任何关系，二者都只是 `Area` 的实例。把它们放进同一个列表则需要
一个共同的类型：

```
Couldn't match expected type 'Shape' with actual type 'Side'
```

🦂 这是本节最容易被忽略的一点：**类型类不引入子类型**。`Area a => [a]` 里的所有元素必须是同一个
具体类型。若确实需要混装，要另加一层包装（存在类型或 `Either`）。

**`deriving`。** 编译器可以为若干标准类生成实例：

```haskell
data Shape = Circle Double | Rect Double Double
    deriving (Eq, Show)
```

派生的是结构性的实现：`Eq` 逐字段比较，`Show` 按构造子名与字段顺序打印。

**例 4.1（`deriving Ord` 的比较顺序）** 对记录类型，`Ord` 先比第一个字段，相等时再比第二个：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:person-ord}}
```

测试中核对两条比较：

```haskell
compare (Person 30 "Alice") (Person 25 "Bob")  -- GT
compare (Person 25 "Zed")   (Person 25 "Amy")  -- GT
```

🦂 第一条由 `age` 决定；第二条在 `age` 相等时由 `name` 决定。若业务上要求"先比姓名"，`deriving`
给出的顺序就是错的，必须手写实例。派生给出的是可用的默认值，不是正确的语义。字段顺序一旦
调整，比较结果随之改变，且不触发任何警告。

## 4.3 与接口的差别

把类型类当作"Haskell 的接口"，多数时候能猜对用法，但会在四个地方出错。

| | 类型类约束 | 面向对象接口 |
|---|---|---|
| 选择实现的时机 | 编译期，由类型决定 | 运行时，由对象的动态类型决定 |
| 实例的存放 | 全局唯一，编译器按类型查表 | 每个对象持有一份（虚表指针） |
| 能否对类型构造器抽象 | 能（`Container f`） | 不能（除非语言支持高阶类型） |
| 异构容器 | 不允许，元素同类型 | 允许，都是基类引用 |

第一行的差别在性能与可预测性上都重要：`show x` 的目标实现由 `x` 的静态类型确定，运行时不查
表。第二行的差别在一致性上重要：一个类型在全程序范围内只有一份 `Show` 实例，不会因为对象
来自哪个模块而不同。第四行的差别在数据布局上重要：`[Area a]` 是同质数组，没有逐个元素的
标签。

反过来，接口有类型类不便表达的能力：把不同实现放进同一个容器、按运行时类型分派、增量地
为已存在的类型添加实现（Haskell 需要 orphan instance，且受一致性约束）。

◇ **类型类的作用是约束，不是继承。** 接口建立"是一种"的关系，类型类只声明"支持哪些操作"。
`Circle` 不是 `Area` 的子类型，它只是 `Area` 的一个实例。

## 4.4 HoTT 视角：约束是类型上的结构

第 3 章把类型读作空间。在这一读法下，类型类约束是什么？

**定义 4.1（类型类约束）** 一个类型类 $C$ 的约束是对类型的谓词：对每个类型 $a$，$C\,a$ 这个类型要么有元素（存在实例），要么为空（不存在实例）。约束作为类型的一部分出现在签名中，由
编译器在调用点解析。

`Describable a` 的 kind 是 `Constraint`，因此它本身是一个类型。这与第 3 章的"命题即类型"一致，只不过这里的命题关于类型，而不是关于值。

**定义 4.2（实例的 coherence）** 若对任意类型，程序任何位置至多有一个可用实例，则称该类是 coherent 的。此时"$a$ 是 $C$ 的实例"是一个性质，选择哪个实例不影响结果。

**带方法的类是一个记录，定律不在其中。** 一个实例提供若干运算与常量。把这些方法收集起来，
得到一个记录类型：

$$
\mathrm{Dict}_{\mathrm{Combine}}(a) \;=\; (a \to a \to a)
$$

数学上要的对象比它多一个分量——一个函数，连同它满足结合律的证明：

$$
\sum_{f \,:\, a \to a \to a} \mathrm{Assoc}(f)
$$

Haskell 的类只给出第一个分量，证明不在其中：

```haskell
class Combine a where
    combine :: a -> a -> a
```

结合律没有出现在类型里，它写在文档和测试里。Haskell 的类提供的是**结构**（structure）；
定律是实例作者必须遵守的**义务**，不是数据。义务不是规范术语，规范的说法是定律（law）或
公理（axiom），软件工程里相近的词是**契约**（contract）。本书用义务强调一件事：编译器不
检查定律，任何数据里也存不下定律，成立的唯一保证是写实例的人遵守。

🦂 **coherence 即实例空间是命题。** 若一个类的任意两个实例都相等（实例空间是 -1-截断的），那么"`a` 是 `C` 的实例"就是一个性质，选择哪个实例不影响结果。Haskell 原则上保证这一点：实例全局唯一，编译器按类型查表。但这条保证可以被破坏——重叠实例（overlapping instances）与孤儿实例（orphan instances）都能让同一类型在不同模块看到不同实现。因此严格地说，Haskell 的约束是结构而不是性质。

**为什么定律检查不了。** 定律的陈述用到等号：`combine (combine x y) z == combine x (combine y z)`。在 Haskell 里，这个等号属于 `Eq` 类，是一个返回 `Bool` 的判定过程；在第 3 章的意义上，它不是恒等类型。类型系统能检查的是"有没有 `combine`"，不能检查"`combine` 是否结合"。这不是实现上的疏忽，而是 Haskell 没有把恒等类型放进类型系统：`=` 在语言里不是可构造的类型。

## 4.5 定律的义务

**例 4.2（减法不满足结合律）** 把上面的分析落到一个具体反例上。类只声明签名，定律写在注释里：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:combine-class}}
```

🦂 `String` 的实例满足结合律，`Diff` 的实例不满足。类型系统对二者一视同仁：都能编译，都能通过
类型检查。唯一能发现差别的方式是在具体值上抽查：

```haskell
{{#include ../code/src/Ch04/TypeClass.hs:assoc-check}}
```

测试中的真实结果：

```haskell
associatesOn ["a", "b", "c"]          -- True
associatesOn [Diff 1, Diff 2, Diff 3] -- False
combine (combine (Diff 1) (Diff 2)) (Diff 3)  -- Diff (-4)
combine (Diff 1) (combine (Diff 2) (Diff 3))  -- Diff 2
```

`1 - (2 - 3) = 2`，而 `(1 - 2) - 3 = -4`。减法不满足结合律，这在算术上人人知道；但写成实例
之后，编译器不会再提醒一次。

抽查只能证伪，不能证明。`associatesOn` 在三个元素上通过，不代表在四个元素上通过，更不代表对
任意元素成立。定律的证明只能靠人：写在文档里、在 code review 中核对、在需要时用
等式推理完成。第 7 章的函子定律、第 9 章的单子定律，都是同一类义务。

这一区分也解释了为什么库的文档必须写定律。类型签名说明"能做什么"，定律说明"做了之后能用
什么等式推理"。前者编译器检查，后者只有文档与测试。

## 4.6 其他语言与其他类型系统

本章以 Python 为对照。类型系统的设计空间远不止"有无静态检查"，这一节列出与 Haskell 关系最近
的几支，说明它们各自放松或收紧了哪一条。

### 4.6.1 依值类型

Haskell 的类型不依赖值。`replicate :: Int -> a -> [a]` 的长度只存在于运行时，类型里写不出来。
**依值类型**（dependent type）把值放进类型：

```agda
replicate : ∀ {A : Set} → (n : Nat) → A → Vec A n
```

返回值的长度与参数 `n` 相同，这一点由类型检查器保证。Haskell 要达到同样效果，只能用类型级
自然数加单例类型模拟，写法和错误信息都会变长。

四个系统的差别在基础与取向：

| 系统 | 基础 | 等式与证明 | 终止性检查 | 主要用途 |
|---|---|---|---|---|
| Agda | Martin-Löf 类型论 | `x ≡ y` 是类型，项是证明 | 有 | 研究与形式化 |
| Idris 2 | 依值类型 + 定量类型 | 同上 | 有，`%default total` | 通用编程 |
| Lean 4 | 依值类型 + 归纳类型 | `Prop` 中证明无关 | 有 | 数学形式化 |
| Coq / Rocq | 归纳构造演算 | `Prop` 与 `Type` 分层 | 有 | 形式化验证 |

🦂 依值类型不是"更强的 Haskell"。三处差别要先知道：类型检查一般不可判定，所以系统要求终止性
证明，或把某些检查推迟到运行期；证明与程序共用一套语法，写起来比 Haskell 冗长；类型错误常常
表现为"证明目标对不上"，而不是"类型不匹配"。

### 4.6.2 细化类型

**细化类型**（refinement type）在既有类型上加谓词，检查交给 SMT 求解器：

```haskell
{-@ divide :: Int -> {d : Int | d /= 0} -> Int @-}
```

能归入可判定片段的约束自动通过，归不进去的拒绝。它与本章的类约束有共同点：签名承担更多信息，
检查在编译期完成。区别在证据来源——类约束的证据是实例，细化类型的证据由求解器搜索。

### 4.6.3 资源、效果与渐进

**线性类型。** Linear Haskell 用 `a %1 -> b` 表示参数恰好使用一次。它约束资源的用量，与单子
约束副作用的顺序是两条不同的轴。

**效果系统。** Koka、Eff 把能做什么写成效果行，例如 `() -> <io,exn> a`。Haskell 用一个 `IO`
概括全部副作用，效果系统逐项列出。

**渐进类型。** TypeScript 与 Python 的 `typing` 允许部分标注：有标注的检查，没标注的放过。
这是 4.1.1 节三种写法的系统化版本，取舍与 `Protocol` 相同——用检查范围换迁移成本。

### 4.6.4 各自放弃了什么

四条轴：类型能否依赖值、等式是否为类型、终止性是否检查、副作用是否写进类型。

- Haskell：不依值，等式不是类型，不检查终止，副作用写进 `IO`；
- Agda、Idris、Lean、Coq：依值，等式是类型，检查终止，副作用靠单子或 `IO`；
- Liquid Haskell：不依值，签名可带谓词，检查交给 SMT；
- Linear Haskell：不依值，用使用次数约束资源。

没有一种组合全面占优。依值与终止性检查带来表达力，代价是检查更慢、写法更长；Haskell 的选择
是让类型检查保持可判定、错误信息保持短，把等式与定律留给文档（4.5 节）。

## 4.7 常见错误

**遗漏约束。** 在签名中忘记写约束，或约束不足以确定类型时，编译器的报错形式不同。前者的
典型信息是：

```
No instance for (Show a) arising from a use of 'show'
```

后者的典型信息是歧义类型变量——这正是本书测试中真实遇到的一次：

```
Ambiguous type variable 'a0' arising from a use of 'show'
  prevents the constraint '(Show a0)' from being solved.
  Probable fix: use a type annotation to specify what 'a0' should be.
```

原因是 `eitherRec show (\x -> show (x * 2)) (Right 7)` 中，`Right 7` 使左侧类型完全不受约束，
而 `show` 又要求它有 `Show` 实例。加一处类型标注即可解决。

**与同名的库函数冲突。** 类方法常与常见函数重名：

```
Ambiguous occurrence 'describe'.
It could refer to
   either 'Ch04.TypeClass.describe',
   or 'Test.Hspec.describe'
```

这不是类型类的缺陷，而是导入方式的问题：用 `import qualified` 或 `hiding`。重名的另一个常见
来源是不同章节的示例模块导出同名函数（本书的 `area` 在 Ch03 与 Ch04 中都出现）。

**把不同类型的实例放进同一个列表。**

```
Couldn't match expected type 'Shape' with actual type 'Side'
```

类型类的实例不构成子类型，`[Circle 1, Side 1]` 不合法。若确实要混装，用 `Either Shape Side`
或存在类型包装。

**以为 `deriving` 派生的是语义。** `deriving Ord` 按字段声明顺序比较，`deriving Eq` 逐字段
比较。二者都是结构性的，与业务语义无关。字段顺序变化会静默改变比较结果，且不触发任何警告。

## 4.8 练习

1. 为 `Bool`、`Maybe a`、`[a]` 之外的第三种类型写 `Describable` 实例，要求使用默认的
   `describeAll`，并说明默认实现为什么够用。
2. 把 `Area` 的实例改为记录字段形式（`data Shape = Shape { area :: Double }`），比较两种
   写法在"增加一种形状"时的改动量。
3. 证明 `String` 上的 `(++)` 满足结合律：对任意字符串 `x, y, z`，
   `(x ++ y) ++ z = x ++ (y ++ z)`（对 `x` 归纳）。
4. 证明：若 `f` 满足结合律，则由 `combine x y = f x y` 定义的实例满足 `Combine` 的定律。
5. 为 `Diff` 增加一个满足结合律的变体（例如在 `Diff` 上定义加法），使 `associatesOn` 返回
   `True`，并用三个具体值说明。
6. 构造一个类型，使它同时是 `Combine` 与 `Describable` 的实例，且两个类的定律都成立。

## 参考文献

- **Haskell 2010 Language Report.** 第 4 章（声明与绑定）中类型类与实例的语法，本章 4.2 节
  的规则以此为准；`deriving` 的派生规则见同一章。
- **The Univalent Foundations Program.** *Homotopy Type Theory: Univalent Foundations of
  Mathematics*. IAS, 2013. 第 2 章（类型族与恒等类型）、第 3 章（集合与纯命题）。4.4 节的
  "约束是类型族""实例空间是命题"两个说法取自这两章的约定。
- **`base` 文档**：`Data.Eq`、`Data.Ord`、`Data.Semigroup`、`Data.Monoid` 的类声明与文档中的
  定律列表；`Control.Monad` 的单子定律留待第 9 章。
- **`functools.singledispatch`**（Python 标准库）：4.1.1 节"按类型查表"的实现依据。
- **Agda**：*Agda User's Manual*（`Vec`、`Set` 与终止性检查）；Bove, Ana; Dybjer, Peter.
  "Dependent Types at Work." 2009。4.6.1 节的 `Vec` 例子取自此文。
- **Brady, Edwin.** "Idris 2: Quantitative Type Theory in Practice." *ECOOP 2021*.
  4.6.1 节的定量类型与 `%default total`。
- **Carneiro, Mario.** "The Type Theory of Lean." 2019. 本地文件
  `~/Folders/Math/Category/slides.pdf`。Lean 4 的 `Prop` 与证明无关取自这份讲稿。
- **Coq / Rocq**：*Reference Manual*，归纳构造演算与 `Prop`/`Type` 的分层。
- **Rondon, Patrick M.; Kawaguchi, Ming; Jhala, Ranjit.** "Liquid Types." *PLDI 2008*；
  `liquidhaskell` 文档。4.6.2 节的细化类型签名。
- **Bernardy, Jean-Philippe; Boespflug, Mathieu; Newton, Ryan R.; Peyton Jones, Simon;
  Spiwack, Arnaud.** "Linear Haskell: Practical Linearity in a Higher-Order Polymorphic
  Language." *POPL 2018*。4.6.3 节的 `%1 ->`。
- **Leijen, Daan.** "Koka: Programming with Row Polymorphic Effect Types." 2014.
  4.6.3 节的效果行。
