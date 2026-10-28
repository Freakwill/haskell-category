# 边学Haskell 边学范畴论

[TOC]

## 序

## Haskell语法基础

笔者假定读者已经有编程了经验，对一些计算机世界的概念不会觉得陌生。

下表列出Haskell中的基本概念，以及对应的变量或类型。同时给出了Python的比较。

|              | Haskell              | Python                |
| ------------ | -------------------- | --------------------- |
| 空值         | ()                   | None                  |
| 字符、字符串 | Char、String==[Char] | str                   |
| Boole类型    | Bool                 | bool                  |
| 数值         | number               | int,float             |
| 元组、列表   | (a,b)、[a]           | list、tuple           |
| 函数         | Function             | Callable              |
| 类型         | data                 | object                |
| 类型类       | class                | type                  |
| 类型测试     | x :: String          | isinstance(x, string) |



### 常量、变量、类型

本节只介绍常量、变量、和常用类型。对于有经验的读者，下面一个例子就够了。

```haskell
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
```

这里面`print` 是打印函数，其定义在默认导入的Prelude模块中。



### 函数

#### 函数定义与调用



#### Haskell常用函数

#### 匿名函数、高阶函数、递归函数

#### 函数活学活用

一个最简单的函数，无实质性的作用, 但是却起到了美化注释的效果：一方面它提示这是一段注释，另一方面，如果编辑器里注释的颜色很暗淡，可以改用这个函数.

```lua
comment :: String -> IO ()
comment s = return ()
main :: IO ()
main = do
    comment "print Hello World"
    putStrLn "Hello World"
```

如果这是某个需要注意的地方就用`remark`函数名.

#### 数值函数

## 范畴论

用一个类比，开始这一章的写作。读者熟悉哪种知识，就用哪种类比。如果读者了解OOP(比如有Python和Ruby这样高度OOP的计算机语言编程经验)，就用OOP的类比。本文只采用范畴论的类比。

| Haskell        | 数据    | 类型                         | 类型类                   |
| -------------- | ------- | ---------------------------- | ------------------------ |
| 范畴论         | 元素    | 对象/集合                    | 子范畴/范畴              |
| 例子           | 3       | Int                          | Num/Show/Eq/Hack         |
| oop            | 对象    | 类型                         | 元类                     |
| 代数学(集合论) | 元素    | 代数系统(集合)               | 代数系统类型(集合的集合) |
| Haskell 关键词 | 3:: Int | instance,data, type, newtype | class                    |

### 范畴论基本知识

**范畴定义**

### 类型声明

#### 数据声明

```haskell
data Drug = MakeDrug String
MakeDrug "wtf" :: Drug
```



#### 类型别名、新类型声明

```haskell
type List a = [a] -- 类型别名, 右侧没有函数
type Function1D = Double -> Double
type Function1D a = a -> a

-- newtype 只接收一个参数
newtype Transform a = Transform （a->a） -- 接近 data (看作 data 特例) 而非 type，比data快速
newtype Const a b = Const a
newtype State s a = State {runState :: s -> (a, s)}
```

`newtype` 避免额外的打包解包过程, 右侧包裹的类型必须是上层类型.



#### 常见类型





### 函子

建立范畴论的真正动机不是范畴而是函子的发现。然而函子的概念要比范畴复杂。函子是范畴上的映射，表达的是范畴之间的关系。如果要用OOP来理解，函子可能会被设计成元类上的某个方法。

**定义**

第一个函子很可能是同调群的构造$H_n(X)$。最有名的是基础群$H_1(X)$，即闭曲线构成的同伦类。然而学习Haskell，并不需要掌握这个。我们来看Haskell入门必备的例子。

#### Maybe 函子

```haskell
data Maybe a = Just a | Nothing -- 必须有 Just, 作为构造函子，尽管数学上好像没有什么作用。
Just 3 :: Maybe Int
Just "Hello" :: Maybe String
```

用数学的记法，可以写成$A=A\cup\{*\}$
$$
\tilde{f}(x)=\begin{cases}
f(x),x\in A\\
*, x=*
\end{cases}, f:A\to B
$$
从这个定义上看，这个函子并没有带来什么特别的东西，$A$和$*$完全是两个平行的世界。但是它确实是有用的，比如处理异常值。

```haskell
divide :: Int -> Int -> Maybe Int
divide x 0 = Nothing
divide x y = x/y
```

这样定义除法，就不用特别担心除数是0的情况。



### 自然升格

```haskell
<$> :: (a -> b) -> f a -> f b
f <$> x = fmap f x  -- (= (pure f) <*> x)
<$ :: b -> f a -> f b
<$ = fmap . const  -- a <$ x = fmap (const a) x, x $> a

*> :: Applicative f => f a -> f b -> f b
x *> y = (id <$ x) <*> y = (\_ -> id) <$> x <*> y -- y <* x
{-
f a = c -> a, -- F = Hom(c, .)
x *> y = y

f a = [a]
x *> y = y ++ y ++ ... ++ y
-}
-- example
replicate <$> Just 1 *> Just (+1) <*> Just 1234
-- > 

-- listAx
```



### 应用函子

在范畴论里，并没有应用函子的概念。

下面是应用函子的定义。

```haskell
class Functor f => Applicative f where
    pure :: a -> f a   -- minimum context
    (<*>) :: f (a -> b) -> f a -> f b
    pure id <*> v = v  -- identity
    pure (.) <*> u <*> v <*> w = u <*> (v <*> w) -- compostition
    pure f <*> pure x = pure (f x)  -- homomorphism
    u <*> pure y = pure ($ y) <*> u -- interchange
```

我们尝试要用范畴论的记号重述定义。

定义自然变换$\eta: I\dot\to T$, $T:X\to X$。在Haskell里，这个叫最小上下文。

$\circledast: F(a\to b)\to Fa\to Fb, a,b,a\to b:X$。

从这个定义中就可以看出，它不太可能出现在范畴里，因为我们要确立一个范畴包含$ a,b,a\to b$。在数学实体里，我能想象出的是集合范畴。$\circledast$还应该满足如下条件。

**事实**

设$X$上的态射$f:a\to b$。

- $\eta(f)\circledast x=F(f)(x)$ (这个等式大概说明了它为什么被命名为应用函子)

- $\eta(f)\circledast \eta(x)=\eta(f(x))$

- $\eta(\circ) \circledast u \circledast v \circledast w = u \circledast(v \circledast w)$

第三个，看上去不好理解，$\circ$是函数复合运算，如果$X=Set$当然也算态射。

请读者尝试证明

$f\circledast \eta(x)=\eta(e_x)\circledast f$，$\eta(i)\circledast x=x$.

$\eta(\circ) \circledast \eta(u) \circledast \eta(v) = \eta(u\circ v)$



### List、Reader 应用函子

```haskell
-- List [a]
-- f <*> a = [f[i](a[i]), i]
-- c -> a
f2 <*> f1 = \x -> f2 x $ f1 x
-- const id <*> f1 == f1
```

Reader应用函子$f\circledast u(x)=f(x, u(x))$

它有很好的性质：

$\tilde{f}(u)\circledast v\circledast w(x)=f(u(x), v(x), w(x))$, 其中$f$不限于三元函数，可以是任意元的函数。

它自然地把一个多元函数，和多个函数进行复合。这种复合在数学上，很平凡，可是计算机实现却不容易。



#### 反例

f = Const c -- 常函子



### 半群与应用函子

#### Const 应用函子

Const a 在半群意义下是应用函子.

```haskell
-- Const a
instance Monoid a => Applicative (Const a) where
    pure _ = Const mempty :: Const a
    (Const x) <*> (Const y) = (Const x <> y)
```

$x \circledast y =xy$.



#### 选择应用函子

类似于加法半群

```haskell
-- Monoid a => [a]
mempty = []
mappend = ++

-- Monoid a => Maybe a
empty = Nothing
Nothing <> x = x <> Nothing = x
Just x <> Just y = Just (x <> y)

-- Alternative
class Applicative f => Alternative f where
    empty :: f a
    <|> :: f a -> f a -> f a

instance Alternative [] where
 ...
 
instance Alternative Maybe where
 ...
 
asum :: (Foldable t, Alternative f) => t (f a) -> f a  
asum = foldr (<|>) empty 

class (Alternative m, Monad m) => MonadPlus m where
   mzero :: m a
   mzero = empty
   mplus :: m a -> m a -> m a
   mplus = (<|>)
```

#### 拉链应用函子

```haskell
newtype Ziplist = ZipList (getZipList :: [a])
instance Applicative ZipList where
    pure x = ZipList (repeat x)
    ZipList fs <*> ZipList xs = ZipList (zipWith ($) fs xs)
```

$\eta(x)=\{x_i=x\}; Z(\{f_i\})\circledast Z(\{x_i\})= Z(\{f_i(x_i)\})$.



## 单子

单子是Haskell最有特点的一部分，值得用单独的一章来讨论。单子也是范畴论里的重要概念。

```haskell
class Monad m where  
    return :: a -> m a  -- pure
    join :: m (m a) -> m a -- bind function

    (>>=) :: m a -> (a -> m b) -> m b
    x >>= f = join $ fmap f x
    
    bind f = join . (fmap f)

    (>>) :: m a -> m b -> m b  
    x >> y = x >>= \_ -> y  -- mempty >>= f

    fail :: String -> m a  
    fail msg = error msg  
    
(<=<) :: (Monad m) => (b -> m c) -> (a -> m b) -> (a -> m c)  
f <=< g = (\x -> g x >>= f)  -- g >=> f

f <*> x = join $ fmap (\f -> fmap f x) f -- f>>= (\f -> f <$> x)

-- example
-- guard : true|->[()], false|->[]
Prelude Control.Monad> [1..50] >>= (\x -> guard ('7' `elem` show x) >> return x)   
[7,17,27,37,47]  
Prelude Control.Monad> do { x <- [1..50]; guard ('7' `elem` show x); return x }  
[7,17,27,37,47]  
Prelude Control.Monad> [ x | x <- [1..50], '7' `elem` show x ]  
[7,17,27,37,47] 

-- Control.Monad
when/until/void
```



$\triangleright: Ma\to(a\to Mb)\to Mb=(a\to Mb)\to (Ma\to Mb)$

$x\triangleright f=\mu(Mf(x))$.  *Kleisli 求值*

左右单位性 $\eta(x)\triangleright f=f(x), m\triangleright \eta=m$.

结合性 $m\triangleright (\lambda x. f(x)\triangleright g)=m\triangleright f\triangleright g=m\triangleright (f \ast_K g)$ *Kleisli 复合*

$m \gg y=m\triangleright c y$ *Kleisli 结合运算*

$c (x\gg y) = c x *_K c y$ *Kleisli 同态*

```haskell
List, join = concat
Maybe, join: Maybe Maybe a -> Maybe a

r ->, join: (r -> r -> a) -> (r -> a)
join f = \x -> f x x

x >>= f = \t -> f(x(t), t)
```



| 函子           | 应用函子            | 单子      |
| -------------- | ------------------- | --------- |
| 解包-计算-打包 | 解包-解包-计算-打包 | 解包-计算 |



### do 语法糖

```haskell
count:: Int
count = sum $ [1..10] >>= (\x -> [x..10] >>= \_ -> return 1)
      = sum $ [1..10] >>= (\x -> [x..10]) >> [1]
count = sum $ do
    x <- [1..10]
    _ <- [x..10]
    return 1

getLine :: IO String
putStrLn :: String -> IO ()
main :: IO ()
main = getLin >>= putStrLn
main = do
    line <- getLine
    putStrLn line

do {x<-s; y<-t; g} == s >>= \x -> (t >>= \y->g) == s >>= ((\x -> t) >=> g)
do {s; t; g} == s >> t >> g
```

 

### 列表单子/控制结构

```haskell
sequence :: t (m a) -> m (t a)  -- 类型转换
-- t = []
sequence [] = return []
sequence a:as = a >>= \x -> ((\l -> x:l) <$> sequence as) -- 类似于 Descartes 积

sequence :: t (m a) -> m () -- Kleisli 连乘
sequence_ [] = return ()
sequence_ a:as = a >> sequence_ as

mapM = sequence . map :: (a -> m b) -> [a] -> m [b]
mapM_ = sequence_ . map :: (a -> m b) -> [a] -> m ()

forM = flip mapM :: [a] -> (a -> m b) -> m [b] -- 模拟 for 循环
forM_ = flip mapM_

main = forM_ [5..10] $ \n -> do
    putStrLn $ "Solutions for queen" ++ (show n) ++ " problem:"
    forM_ (queensN n) $ print

replicateM :: Int -> m a -> m [a]
replicateM_ :: Int -> m a -> m ()

-- m: s -> a , s
sequence_ [m1, m2, ....] ~ m1'm2'.... :: s -> (), s
replicateM_ n m = m ^ n :: s -> (), s
sequence [m1, m2, ....] ~ m1'm2'.... :: s -> [....], s


forever :: m a -> m b -- sequence . repeat

main = forever $ do
    input <- getLine
    putStrLn $ answer input

filterM :: (a -> m Bool) -> [a] -> m [a]

foldM :: (b -> a -> m b) -> b -> t a -> m b
-- do
-- b1 <- f(b, a0)
-- b2 <- f(b1, a1)
-- ...
-- f(bn, an)
-- == (f(a0)*f(a1)*f(a2)...f(an))(b)

-- example

\m -> mapM . (const m) :: m b -> [a] -> m [b]

```



### State 单子

模拟命令式语言。

给定$s$，定义单子

$S a = s\to a\times s$。

```haskell
newtype State a s = State {runState: s -> (a, s)}
instance Functor (State s) where
    fmap f fs = State $ \s -> let (a, s') = runState fs s in (f a, s')
    -- (f(a), s'), (a, s') = fs(s)
    
instance Monad (State s) where
    return x = State $ \s -> (x, s)
    fa >>= f = State $ \s -> let (a, s') = runState fa s in (runState (f a) s')
    -- f(a)(s'), (a, s') = fa(s)
    -- do {b <- fa; f b}

    fa >> f == State $ \s -> let (a, s') = runState fa s in (runState f s')
    -- f(s'), (a, s') = fa(s) -- 不利用fa的输出
    -- f . fa_2

get = State $ \s -> (s, s)  -- 获取当前状态，不做改变
put :: s -> State s ()  -- 输入状态，无输出
put s = State $ \_ -> ((), s)
modify f = State $ \s -> ((), f s) -- 无输出的状态迁移

fa >> put s = State $ \s -> ((), fa_1 s) = modify fa_1
```



### IO 单子

定义 IO 单子的动机

Haskell的Hello World程序是，`putStrLn "Hello World"`。这个程序修改了标准输出设备的显示情况，同时函数没有返回任何值，是否意味着Haskell的程序也有副作用？实际上`putStrLn`依然是一个纯函数，类型为: `String->IO ()`。IO 是一个单子，可以认为是一种特殊的 State 单子。

IO x = :milky_way:->​x,​ :milky_way:

```haskell
-- 第一种定义，foo, bar编译器会认为是一样的
putStrLn' :: String -> ()
getLine' :: String

foo = putStrLn' getLine'
bar = putStrLn' getLine'

-- 第二种定义，执行部分顺序
putStrLn' :: String -> Unique
getLine':: Unique -> String

-- 第三种定义, 变量上的依赖，有求值顺序
foo :: Unique
foo = putStrLn' $ getLine' ???
bar = putStrLn' $ getLine' foo

-- 标准定义
newtype IO a = IO (RealWorld -> (RealWorld, a))

-- 常用函数
getChar:: IO Char
getLine :: IO String
getContents :: IO String
interact :: (String -> String) -> IO ()

readIO :: Read a => String -> IO a
readLn :: Read a => IO a
readMaybe :: Read a => String -> Maybe a

-- 文件操作
readFile :: FilePath -> IO ()
writeFile :: FilePath -> String -> IO()
appendFile :: ...

-- 变量
data IORef a = ...
newIORef :: a -> IORef a  -- a <- newIORef 0 :: IORef Int
readIORef :: IORef a -> IO a
writeIORef :: IORef a -> a -> IO ()
modifyIORef :: IORef a -> (a->a) -> IO ()  -- modifyIORef‘ 立刻执行
```

IO 操作自动不是阻塞的，所有读写操作都在运行时交给IO管理器处理。



### ST 单子— 状态线程单子，比IO弱的单子

```haskell
newtype ST s a = ST (STRef s a)
type STRef s a = State# s -> (# State# s, a #)
-- newtype ST s a = ST (s -> (s, a))

newSTRef :: a -> ST s (STRef s a)
readSTRef :: STRef s a -> ST s a
writeSTRef :: STRef s a -> a -> ST s ()
modifySTRef

-- example
fib :: Int -> ST s Integral
fib n = do {a <- newSTRef 0;
            b <- newSTRef 1;
            repeatFor n
            (do {x <- readSTRef a;
                y <- readSTRef b;
                writeSTRef a y;
                writeSTRef b $! (x+y)});
            readSTRef a}
```



#### 可变数组

```haskell
newListArray :: Ix i => (i, i) -> [e] -> ST s (STArray s i e)
getElems :: STArray s i e -> ST s [e]
```



### Reader 单子

```haskell
-- 模板渲染

headT, bodyT :: String -> String  -- Template

-- greatingMike = headT "Mike" ++ bodyT "Mike"
renderGreeting = gather <$> headT <*> bodyT <*> where
    gather x y z = x ++ y
    
data Greet = Greet {
    headT :: String
    , bodyT :: String
} deriving Show

renderGreeting :: String -> Greet
renderGreeting = Greet <$> headT <*> bodyT  -- Greet (headT x)  (bodyT x)

renderGreeting = do
    h <- headT
    b <- bodyT
    return $ Great h b

--
data Greet = Greet {
    name :: String
    , headT :: String
    , bodyT :: String
    , footT :: String
} deriving Show

renderGreeting = do
    n <- ask
    h <- headT
    (b, f) <- local ("Mr. and Mrs." ++) $ do
        b' <- bodyT
        f' <- footT
        return (b', f')  -- x -> (bodyT(x), footT(x)) : String -> (String, String)
    return $ Greet n h b f

-- renderGreeting(x) = Greet(n(x), h(x), b(l(x)), f(l(x)))

-- Reader

newtype Reader r a = Reader {runReader :: r -> a}
instance Functor (Reader r) where
    fmap f m = Reader $ \r -> f (runReader m r) = Reader (f . (runReader m))

m >> f = Reader $ \r -> runReader (f (runReader m r)) r
```

$Rr:$ Reader 函子, $Hom(r,\cdot)$

$Rr(f)x= R(\lambda y:r. f(\phi(x)(y)))=R(f\circ\phi(x))$

$Rr(f)R(g)=R(fg)$.

$\mu(x)=R(\lambda t:r.\phi(\phi(x)(t))(t)), \mu(Rg)=R(\lambda t:r.\phi(g(t))(t)).$



### 半群作用单子

```haskell
f a = (m, a)
(x, a) >>= f = (xf1(a), f2(a))

```

$\phi((s,a), f)=(sf(a)_1, f(a)_2)$.

$\mu(s_1,s_2,a)=(s_1s_2,a),\eta(a)=(1,a)$.



### 半群State单子

```haskell
f a = a->(m, a)
```

$f\star g = f \triangleright \lambda m.F(m) g, f\star g (a)=\lambda m. (m g(s)_1, g(s)_2), (m,s)=f(s)$.



## 模块包



## 并行计算



## 数据库

## 第三方库推荐



## 实战








