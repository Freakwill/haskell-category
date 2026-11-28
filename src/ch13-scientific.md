# 第 13 章 科学计算

> **状态**：试写稿 ｜ **目标**：1.6 万字 ｜ **代码**：`code/src/Ch13/`
>
> 写作提示：数组操作、向量/矩阵/线性代数、机器学习、符号计算、自动微分五个主题；w

本章把科学计算的五件事写成能跑的 Haskell：数组操作、向量与矩阵（线性代数）、
机器学习（线性回归）、符号计算（表达式化简与求导）、自动微分（对偶数）。五个
主题各自独立，共享同一套工具：代数数据类型描述结构，模式匹配与递归描述算法，
测试断言描述正确性。对照见表 13.1。

| 主题 | 数据 | 核心操作 | 正确性靠什么保证 |
|---|---|---|---|
| 数组操作 | `Seq` 向量 | 逐元素运算、点积 | 长度检查 + 测试 |
| 线性代数 | 行向量组成的矩阵 | 转置、矩阵乘向量、矩阵乘 | 单位阵不动点测试 |
| 机器学习 | 点集、参数对 | 均方误差、梯度下降 | 收敛到闭式解 |
| 符号计算 | `Expr` 表达式 | 化简、求导 | 对已知导数逐点核对 |
| 自动微分 | `Dual` 对偶数 | 带导数值的算术 | 与符号求导逐点一致 |

## 13.1 问题

导数有三种算法，正好是科学计算三股力量的缩影。

**数值差分**用一个差商逼近导数，写起来只要两行，但误差受步长支配：步长太小
浮点舍入反噬，太大截断误差膨胀，永远只在"近似"里打转。

**符号求导**把表达式当成结构递归处理，结果是精确的公式；代价是要先定义表达式
类型、写出化简与求导规则。第 5 章说过：代码写不出来说明概念还没落地。符号
计算就是"把数学规则写成模式匹配"这件事本身。

**自动微分**走第三条路：给每个数值配一个"导数值"成对携带（对偶数，dual
number），算术运算同时做值与导数的运算。求导不再有步长误差，也不需要表达式
类型——一个多项式函数定义一次，值与导数一次算出。

三条路在本章都有能跑的代码，并且互相核对：同一个多项式，符号求导、自动微分、
中心差分在测试里逐点一致。再加上数组与线性代数的两个基础主题（第 2 章的
递归与折叠在这里长成向量和矩阵），就是本章的全部内容。

## 13.2 数组操作

向量用 `Data.Sequence` 的 `Seq`（第 2 章的队列实现，`containers` 包）。
点积带长度检查——长度不符是错误，不是静默的错误答案：

```haskell
{{#include ../code/src/Ch13/Numeric.hs:dot}}
```

```haskell
ghci> dot (Seq.fromList [1,2,3]) (Seq.fromList [4,5,6])
32
```

`zipWith` 的逐元素运算是数组操作的基本形态，但它的截断语义要当心：长度不一致
时静默取短边。13.7 节有 `dotTrunc` 的实测输出。`Seq` 的其他操作
（`Seq.replicate`、`Seq.fromFunction`、`Seq.scanl`）与列表同名函数一一对应，
长度是 $O(1)$ 可知的，这正是第 2 章队列结构带来的数组能力。

## 13.3 向量、矩阵与线性代数

矩阵用"行向量组成的 `Seq`"表示。转置、矩阵乘向量、矩阵乘都建立在点积之上：

```haskell
{{#include ../code/src/Ch13/Numeric.hs:matvec}}
```

```haskell
ghci> toList (matVec eye (Seq.fromList [3,4]))
[3,4]
```

单位阵是线性代数代码的免费测试：任何向量被单位阵作用后不变，单位阵自乘仍是
单位阵。这两条断言都在 `Spec.hs` 里真实通过，它们是"矩阵乘实现正确"的最低
门槛。本章到此为止只做稠密小矩阵——稀疏矩阵、分解算法（LU、特征值）留到
13.9 节的库清单。

## 13.4 机器学习

拟合直线 $y = a + bx$：均方误差与它的梯度是同一组点集上的两个遍历：

```haskell
{{#include ../code/src/Ch13/Regression.hs:mse}}
```

梯度下降把"一步更新"写成纯函数，把循环交给 `iterate`：

```haskell
{{#include ../code/src/Ch13/Regression.hs:descend}}
```

闭式解一次算完，作为下降的对照：

```haskell
{{#include ../code/src/Ch13/Regression.hs:ols}}
```

数据取直线 $y = 1 + 2x$ 上的六个点：

```haskell
ghci> ols lrDemo
(1.0,2.0)

ghci> last (take 3000 (descend 0.01 lrDemo (0,0)))
(0.9999999922894952,2.000000002172905)
```

闭式解精确命中真参数；梯度下降 3000 步后误差在 $10^{-8}$ 量级，学习率换成
0.05 收敛更快，换成 0.5 就发散（13.7 节有发散的实际输出）。两条路互相印证：
闭式解由公式给出，下降由迭代逼近，测试断言二者一致。更大规模的机器学习
（神经网络、自动微分驱动训练）在第 16 章，本章的梯度与 `iterate` 循环就是
那一切的雏形。

## 13.5 符号计算

表达式是代数数据类型：变量、常数、加法、乘法。求值是在环境上的递归：

```haskell
{{#include ../code/src/Ch13/Symbolic.hs:expr}}
```

化简是逐条恒等式的模式匹配——$0 + x = x$、$0 \cdot x = 0$、$1 \cdot x = x$，
常数直接合并。它不是完整正规形：不展开分配律、不合并同类项，只演示"把规则
写下来"这件事：

```haskell
{{#include ../code/src/Ch13/Symbolic.hs:simplify}}
```

```haskell
ghci> simplify (Mul (Lit 0) (Var "x"))
Lit 0.0
```

求导是三条规则：变量的导数是 1，常数的导数是 0，和与积分别按和法则与
乘法法则递归（乘法法则的两项就是定义里的两个加数）：

```haskell
{{#include ../code/src/Ch13/Symbolic.hs:deriv}}
```

```haskell
ghci> derivDemo
Add (Add (Var "x") (Var "x")) (Lit 3.0)

ghci> eval [("x", 2)] exprDemo
12.0
```

`derivDemo` 是 $x^2 + 3x + 2$ 的导数化简后：$x + x + 3$。测试在 1、2、3 三个
点与 $2x + 3$ 逐点核对——符号计算没有"无穷多输入"可测，逐点核对是它的测试
方式。定理自动证明（第 17 章）把这条线推到更远：从公理出发重写等式，而不是
套用已知规则。

## 13.6 自动微分

对偶数是"值 + 导数值"的一对数，算术规则就是求导规则：加减逐分量传递，
乘法用乘法法则（两项交叉相加）：

```haskell
{{#include ../code/src/Ch13/Autodiff.hs:dual}}
```

```haskell
ghci> Dual 2 1 + Dual 3 2
Dual 5 3

ghci> Dual 2 1 * Dual 3 2
Dual 6 7
```

第一个结果：值与导数各自相加。第二个：值 $2 \times 3 = 6$，导数
$2 \times 2 + 3 \times 1 = 7$——乘法法则的两项。求导器只有一行：把 $f$
作用在对偶数 $(x, 1)$ 上（"值 $x$、导数为 1"是导数的起点），读回导数分量：

```haskell
{{#include ../code/src/Ch13/Autodiff.hs:deriv-at}}
```

```haskell
ghci> derivAt polyDemo 1
5.0

ghci> derivAt polyDemo 3
9.0

ghci> derivAt (\x -> x * x * x) 2
12.0
```

没有差商、没有表达式类型：多项式写一次，值与导数同时算出。三条路的对照在
同一个点上最直观——$x^3$ 在 2 处的导数：

```haskell
ghci> centralDiff (\x -> x * x * x) 2 1e-6
12.000000000345068
```

自动微分给出精确的 12.0（上面），中心差分给出带 $3 \times 10^{-10}$ 误差的
近似；符号求导在测试里与二者逐点一致。`derivAt` 的类型
`(forall a. Num a => a -> a) -> Double -> Double` 值得注意：参数必须是
对任意 `Num` 类型都有定义的多态函数，否则 `f (Dual x 1)` 无法构造——这是
"把 $f$ 同时用于两个不同 `Num` 类型"的代价。深度学习框架的自动微分原理与此
相同，差别只在把对偶数换成张量、把显式循环换成计算图（第 16 章）。

## 13.7 陷阱

**`zipWith` 静默截断。** 列表与 `Seq` 的 `zipWith` 都取较短的一边，长度不一致
不报错：

```haskell
ghci> dotTrunc (Seq.fromList [1,2,3]) (Seq.fromList [1,2])
5
```

正确行为是报错。`dot` 显式检查长度；所有用 `zipWith` 做逐元素运算的代码都要
问一句：长度不一致时，静默截断是想要的行为吗。

**差分步长太小，浮点反噬。** 步长减小时截断误差减小，但舍入误差增大。实测：

```haskell
ghci> forwardDiff sin 1 1e-8
0.5403022917960243

ghci> forwardDiff sin 1 1e-17
0.0
```

$h = 10^{-17}$ 时 $\sin(1 + h)$ 与 $\sin 1$ 在 `Double` 里相同，差商变成
$0 / h = 0$。而中心差分在 $h = 10^{-6}$ 处误差约 $3 \times 10^{-11}$
（13.2 节的实测），前向差分在 $h = 10^{-8}$ 处误差约 $10^{-8}$：两种差分
对步长与误差的敏感度不同，数值上这一点直接可见。

**学习率过大，下降变发散。** MSE 是凸的，但步子太大会跳过谷底：

```haskell
ghci> last (take 3 (descend 0.5 lrDemo (0,0)))
(-46.08333333333334,-164.30555555555557)

ghci> last (take 10 (descend 0.5 lrDemo (0,0)))
(2.0271548232294387e8,7.19331358126062e8)
```

参数从零附近一路炸到 $10^8$。发散的判据很实际：误差在几步之间变大就停。学习率
0.01 与 0.05 都收敛（13.4 节），0.5 发散——"调学习率"不是玄学，是每一步
都在赌二阶项。

**GHC2021 里没有 `\case`。** `\case`（LambdaCase）属于 GHC2024 扩展集，
GHC2021 直接报错：

```
src/Ch13/Symbolic.hs:23:13: error: [GHC-51179]
    Illegal \case
    Suggested fix:
      Perhaps you intended to use the ‘LambdaCase’ extension
```

本书工程用 GHC2021（cabal 文件里的 `default-language`），写 `\case` 前要么
加扩展，要么写显式 `case ... of`。13.5 节的 `eval` 第一版就踩了这条。

**`Data.Sequence` 不导出 `map`。** `Seq` 是 `Functor`，但没有自己的 `map`
函数：

```
src/Ch13/Numeric.hs:42:11: error: [GHC-76037]
    • Not in scope: ‘Seq.map’
    • Note: The module ‘Data.Sequence’ does not export ‘map’.
```

用 `fmap` 或 `Data.Foldable` 的遍历。这条错误本身无害，但它提醒：容器类型
的标准接口是类型类（`Functor`、`Foldable`），模块自带的专有函数只是补充。

## 13.8 练习

1. 实现类：给 `dot` 加长度检查后，`matMul` 对"行宽与列高不符"的两个矩阵会
   怎样？动手试，贴出 `dot` 抛出的报错。
2. 实现类：扩展 `Expr` 加入 `Neg` 与 `Sub` 两个构造子，补上 `eval`、
   `simplify`（$x - x = 0$）、`deriv` 三处模式，并写测试核对
   $(x^2 - 1)$ 在 2 处的值与其导数值。
3. 数值类：对 $\exp x$ 在 0 处分别用前向差分（$h = 10^{-4}, 10^{-8},
   10^{-12}$）与中心差分，列表记录误差；找出误差随 $h$ 变小的转折点，并解释
   为什么前向差分更早开始变差。
4. 实现类：给 `Dual` 写 `Fractional` 实例（除法法则），再用 `derivAt`
   计算 $1 / x$ 在 2 处的导数，与 $-1/4$ 核对。
5. 对照类：对照 `gradMse` 的代码，逐项指出系数 $-2/n$ 与 `-2 * x` 对应的
   误差项位置，说明为什么对 $b$ 的梯度多乘一个 $x_i$。
6. 判断类：为什么 13.4 节的测试断言"下降 3000 步 ≈ 闭式解"而不是"恰好
   相等"？`Double` 的舍入之外，还有哪个原因（提示：迭代次数与步长的关系）？

## 13.9 延伸

- 数学：差分的误差分析属于数值分析，系统性处理见 Burden & Faires
  *Numerical Analysis*；最小二乘的几何解释见 Strang *Introduction to
  Linear Algebra*。本章刻意不展开推导，代码与实测先行；需要误差界时按
  上述文献补。
- 工程：生产级数组用 `vector`（连续内存）与 `massiv`（多维 + 并行）；线性
  代数绑定 `hmatrix`（BLAS/LAPACK）；符号计算有 `sbv`（SMT）与 `symengine`；
  自动微分的工业实现是 `ad` 包，深度学习框架在此基础上加计算图。与 Python
  生态的对照：`numpy` 的 `dot`、`scipy` 的 `derivative`、`scikit-learn`
  的 `LinearRegression`、PyTorch 的 `autograd` 与本章模块一一对应，差异在
  数组的底层表示与 GPU 路径。本章只用 `base` 与 `containers`，让五个主题的
  结构露在外面；工程中换成上述库，结构不变。

## 参考文献

- Burden & Faires, *Numerical Analysis*（第 9 版）：浮点误差与差分公式
  （13.2、13.7 节）。
- Strang, *Introduction to Linear Algebra*（第 5 版）：最小二乘与矩阵运算
  （13.3、13.4 节）。
- Baydin, Pearlmutter, Radul & Siskind, *Automatic Differentiation in
  Machine Learning: a Survey*（2018）：自动微分综述（13.6 节）。
- [`Data.Sequence`](https://hackage.haskell.org/package/containers/docs/Data-Sequence.html)
  （`containers`）：`Seq` 的 API 与复杂度（13.2 节）。
- [`ad`](https://hackage.haskell.org/package/ad)（Hackage）：自动微分的
  工业实现（13.6、13.9 节）。
