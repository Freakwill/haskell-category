module Main (main) where

import           Control.Exception (evaluate)
import qualified Data.Map.Strict     as Map
import           Data.Monoid         (Sum (..))
import qualified Data.Sequence       as Seq
import qualified Data.Text           as T
import           Ch01.Basics
import           Ch01.Tour           (Expr (..), demoExpr, eval, firstFive, pretty, squaresOf)
import           Ch02.Functions
import           Ch03.ADT
import qualified Ch04.TypeClass     as TC
import           Ch05.Category
import           Ch06.Hask          (lawsHoldOn, etaCounterexample)
import qualified Ch07.Functor       as F
import qualified Ch08.Applicative   as A
import qualified Ch09.Core          as C9
import qualified Ch09.Instances     as I9
import qualified Ch09.Motivation    as M9
import qualified Ch09.STArrays      as ST9
import qualified Ch13.Autodiff     as D13
import qualified Ch13.Numeric       as N13
import qualified Ch13.Regression    as R13
import qualified Ch13.Symbolic      as S13
import           Test.Hspec

main :: IO ()
main = hspec $ do
  describe "Ch01.Tour / eval" $ do
    it "求值 6 * (2 + 3) = 30" $
      eval demoExpr `shouldBe` 30

    it "嵌套取负：Neg (Mul (Lit 2) (Lit 3)) = -6" $
      eval (Neg (Mul (Lit 2) (Lit 3))) `shouldBe` (-6)

    it "同一个数据、另一个函数：pretty 不做求值" $
      pretty demoExpr `shouldBe` "(6 * (2 + 3))"

  describe "Ch01.Tour / 惰性" $ do
    it "从无限列表里取前五项" $
      firstFive `shouldBe` [0, 1, 4, 9, 16]

    it "map 不强制求值整个输入" $
      take 3 (squaresOf [1 ..]) `shouldBe` [1, 4, 9]

  describe "Ch02.Functions" $ do
    it "递归求和" $
      total [1 .. 4] `shouldBe` 10

    it "严格折叠与递归求和结果一致" $
      totalStrict [1 .. 100] `shouldBe` total [1 .. 100]

    it "递归映射" $
      doubleAll [1, 2, 3] `shouldBe` [2, 4, 6]

    it "递归过滤" $
      evens [1 .. 6] `shouldBe` [2, 4, 6]

    it "部分应用：add 10 还是一个函数" $
      addTen 5 `shouldBe` 15

    it "curry 把二元函数拆成两个一元函数" $
      addCurried 1 2 `shouldBe` 3

    it "管道：filter 与 map 串起来" $
      names `shouldBe` ["ann", "cy", "dee"]

    it "zipWith 以最短的列表为准" $
      pairs `shouldBe` [10, 40, 90]

    it "section：左节 (1 -) 与 subtract 不是一回事" $ do
      map (subtract 1) [5, 4 :: Int] `shouldBe` ([4, 3] :: [Int])
      map (1 -) [5, 4 :: Int] `shouldBe` ([-4, -3] :: [Int])
      map (const (-1)) [5, 4 :: Int] `shouldBe` ([-1, -1] :: [Int])

    it "guard 从上往下取第一个成立的分支" $ do
      map grade [95, 85, 61, 12] `shouldBe` ["A", "B", "C", "F"]

    it "where 把重复计算提到外面" $
      normalize [10, 20, 30] `shouldBe` [0, 50, 100]

    it "全部分数相同时不会除以零" $
      normalize [5, 5] `shouldBe` [0, 0]

    it "$ 只是最低优先级的函数应用" $
      (sum $ map (^ 2) [1 .. 10]) `shouldBe` 385

  describe "Ch05.Category" $ do
    it "复合的方向：先 f 后 g" $ do
      compose (identity B) AB `shouldBe` Just AB
      compose AB (identity A) `shouldBe` Just AB

    it "类型对不上就复合不了" $
      compose AB BC `shouldBe` Nothing

    it "两条路径都得到 AC：BC . AB = AC" $
      compose BC AB `shouldBe` Just AC

    it "结合律在全部 6^3 个三元组上成立" $
      assocHolds `shouldBe` True

    it "左右单位律成立" $
      identityHolds `shouldBe` True

    it "幺半群 Z/3 作为单对象范畴也满足结合律" $
      assocHoldsM3 `shouldBe` True

    it "函子保恒等、保复合" $
      functorLawHolds `shouldBe` True

    it "函子的具体取值" $
      interp AC 3 `shouldBe` 8

    it "同构：swapPair 自逆" $
      swapIsIso `shouldBe` True

    it "假函子被同一套检查抓住" $
      badFunctorLawHolds `shouldBe` False

  describe "Ch03.ADT" $ do
    let nats3 = [Zero, Succ Zero, Succ (Succ Zero)] :: [Nat]

    it "递归子把 Nat 归约成 Int" $
      map toInt nats3 `shouldBe` [0, 1, 2]

    it "用递归子定义加法" $
      toInt (plus (Succ Zero) (Succ (Succ Zero))) `shouldBe` 3

    it "加法结合律在 0..2 上成立" $
      and [ toInt (plus (plus a b) c) == toInt (plus a (plus b c))
          | a <- nats3, b <- nats3, c <- nats3 ] `shouldBe` True

    it "用递归子定义乘法" $
      toInt (times (Succ (Succ Zero)) (Succ (Succ (Succ Zero)))) `shouldBe` 6

    it "和类型的两个分支各自求值" $ do
      area (Circle 1) `shouldBe` pi
      area (Rect 2 3) `shouldBe` 6
      perimeter (Rect 2 3) `shouldBe` 10

    it "积类型的投影" $
      swap (Pair 1 'a') `shouldBe` Pair 'a' 1

    it "标准库的分情况函数就是消去规则" $ do
      boolRec "yes" "no" True `shouldBe` "yes"
      maybeRec 0 (+ 1) (Just 41) `shouldBe` 42
      maybeRec 0 (+ 1) Nothing `shouldBe` 0
      eitherRec show (\x -> show (x * 2)) (Left 7 :: Either Int Int) `shouldBe` "7"
      eitherRec show (\x -> show (x * 2)) (Right 7 :: Either Int Int) `shouldBe` "14"

  describe "Ch04.TypeClass" $ do
    it "类方法按类型选择实例" $ do
      TC.describe True `shouldBe` "true"
      TC.describe (Just True) `shouldBe` "just true"
      TC.describe [True, False] `shouldBe` "[true false]"

    it "默认方法可以直接复用" $
      TC.describeAll [True, False] `shouldBe` ["true", "false"]

    it "约束沿类型构造器传下去" $ do
      TC.describe (Just (Just True)) `shouldBe` "just just true"
      TC.describe ([] :: [Bool]) `shouldBe` "[]"

    it "一个类的两个实例彼此无关" $ do
      TC.area (TC.Circle 1) `shouldBe` pi
      TC.area (TC.Side 2) `shouldBe` 4
      TC.sumArea [TC.Circle 1, TC.Circle 2] `shouldBe` 5 * pi

    it "对类型构造器抽象" $ do
      TC.toList (TC.insert 1 (TC.insert 2 (TC.empty :: [Int]))) `shouldBe` [1, 2]

    it "类型系统不检查定律：String 满足结合律" $
      TC.associatesOn ["a", "b", "c"] `shouldBe` True

    it "类型系统不检查定律：Diff 不满足结合律" $ do
      let x = TC.Diff 1
          y = TC.Diff 2
          z = TC.Diff 3
      TC.associatesOn [x, y, z] `shouldBe` False
      TC.combine (TC.combine x y) z `shouldBe` TC.Diff (-4)
      TC.combine x (TC.combine y z) `shouldBe` TC.Diff 2

    it "deriving Ord 按字段声明顺序比较" $ do
      compare (TC.Person 30 "Alice") (TC.Person 25 "Bob") `shouldBe` GT
      compare (TC.Person 25 "Zed") (TC.Person 25 "Amy") `shouldBe` GT

  describe "Ch06.Hask" $ do
    it "三条定律在全函数上成立" $
      lawsHoldOn (+ 1) (* 2) (subtract 3) [0, 1, 5, -2 :: Int] `shouldBe` True

    it "恒等律在 ⊥ 上失效：seq 能区分 id . f 与 f" $ do
      (composed, bare) <- etaCounterexample
      composed `shouldBe` True
      bare `shouldBe` False

  describe "Ch07.Functor" $ do
    let trees =
          [ F.Leaf 1
          , F.Branch (F.Leaf 1) (F.Leaf (-2))
          , F.Branch (F.Branch (F.Leaf 0) (F.Leaf 3)) (F.Leaf 5)
          ]

    it "fmap 只改 Tree 的元素，不改树形" $
      fmap (* 2) (F.Branch (F.Leaf 1) (F.Leaf (-2)))
        `shouldBe` F.Branch (F.Leaf 2) (F.Leaf (-4))

    it "Tree 的 Functor 实例满足恒等与复合律" $ do
      F.treeIdentityOn trees `shouldBe` True
      F.treeCompositionOn (+ 1) (* 2) trees `shouldBe` True

    it "maybeToList 对任意函数满足自然性方块" $
      F.naturalMaybeToListOn (* 2) [Nothing, Just (-1), Just 3] `shouldBe` True

    it "inspectMaybe 不是自然变换：先乘负再检查与先检查再乘负不同" $ do
      let f = (* (-1))
          x = Just 1
      F.inspectMaybe (fmap f x) `shouldBe` []
      fmap f (F.inspectMaybe x) `shouldBe` [-1]

    it "手写的 addOne 与 fmap (+ 1) 一致" $ do
      F.addOneMaybe (Just 3) `shouldBe` fmap (+ 1) (Just 3)
      F.addOneList [1, 2, 3] `shouldBe` fmap (+ 1) [1, 2, 3]

    it "Weird 违反复合律与恒等律" $ do
      F.weirdIdentityBroken `shouldBe` True
      F.weirdCompositionBroken `shouldBe` True

    it "Mod2 满足复合律但违反恒等律" $ do
      F.mod2CompositionHolds `shouldBe` True
      F.mod2IdentityBroken `shouldBe` True

  describe "Ch08.Applicative" $ do
    it "addMaybe 与手写版一致" $ do
      A.addMaybe (Just 1) (Just 2) `shouldBe` Just 3
      A.addMaybe (Just 1) Nothing `shouldBe` Nothing
      A.addMaybeManual (Just 1) (Just 2) `shouldBe` Just 3

    it "tripleMaybe 组合三个参数" $
      A.tripleMaybe (Just 1) (Just 2) (Just 3) `shouldBe` Just (1, 2, 3)

    it "Maybe 实例满足四条定律" $
      A.applicativeLawsOnMaybe `shouldBe` True

    it "BadAp 违反恒等律与复合律" $ do
      A.badIdentityBroken `shouldBe` True
      A.badCompositionBroken `shouldBe` True

    it "Maybe 实例：Nothing 传播" $ do
      A.pairMaybe `shouldBe` Just (1, 'a')
      A.failMaybe `shouldBe` Nothing

    it "List 实例是笛卡尔积" $
      A.grid `shouldBe` [(1, 'a'), (1, 'b'), (2, 'a'), (2, 'b')]

    it "ZipList 截断到较短者" $
      A.zipPair `shouldBe` [(1, 'a'), (2, 'b')]

    it "Reader 实例共享环境" $
      A.askBoth 3 `shouldBe` (4, 6)

    it "Const 累积 Monoid" $
      A.constSum `shouldBe` Sum 7

    it "Validation 累积全部错误" $
      A.validatePerson `shouldBe` A.Failure ["age too large", "name is empty"]

  describe "myNub" $ do
    it "去掉重复元素并保持首次出现的顺序" $
      myNub [1, 2, 3, 2, 3 :: Int] `shouldBe` [1, 2, 3]

    it "对字符串（即 [Char]）同样成立" $
      myNub "Hello World" `shouldBe` "Helo Wrd"

    it "空列表返回空列表" $
      myNub ([] :: [Int]) `shouldBe` []

  describe "countWords" $ do
    it "统计词频" $
      countWords (map T.pack ["a", "b", "a"]) `shouldBe`
        Map.fromList [(T.pack "a", 2), (T.pack "b", 1)]

    it "总词数等于各词频之和" $
      totalWords (countWords (map T.pack ["a", "b", "a"])) `shouldBe` 3

  describe "Ch09.Motivation" $ do
    it "Maybe 管道：手写嵌套 case 与 >>= 版本一致" $
      M9.pipelineManual M9.personTable "ann" `shouldBe`
        M9.pipelineBind M9.personTable "ann"

    it "Maybe 管道：查不到人名时两条路径都失败" $
      M9.pipelineManual M9.personTable "x" `shouldBe` Nothing

    it "Maybe 管道：年龄超限时两条路径都失败" $
      M9.pipelineBind M9.personTable "dee" `shouldBe` Nothing

    it "列表管道：手工 concatMap 与 >>= 版本一致" $
      M9.chooseManual [1 .. 9] `shouldBe` M9.chooseBind [1 .. 9]

    it "列表管道：和为 10 的数对全部列出" $
      M9.chooseBind [3, 7, 4] `shouldBe` [(3, 7), (7, 3)]

    it "计数器：手写线程与预期一致" $
      M9.threadManual 0 `shouldBe` ("vv", 2)

  describe "Ch09.Core" $ do
    it "join 与 >>= 互相定义，在 Maybe 与列表上一致" $
      C9.interdefinitionsHold `shouldBe` True

    it "有限环境 Two 上穷举三条单子定律成立" $
      C9.twoLawsHold `shouldBe` True

    it "Maybe 与列表在具体赋值上满足三条定律" $
      (C9.monadLawsOnMaybe && C9.monadLawsOnList) `shouldBe` True

    it "BadM 违反左单位律与结合律" $ do
      C9.badLeftIdentityBroken `shouldBe` True
      C9.badAssociativityBroken `shouldBe` True

  describe "Ch09.Instances" $ do
    it "WriterM 按顺序累积日志" $
      I9.runWriterM I9.writerLog `shouldBe` (7, ["add 3", "add 4", "sum"])

    it "ReaderM 共享环境" $
      I9.runReaderM I9.readerEnv 2 `shouldBe` 9

    it "StateM 串行传递状态" $
      I9.runStateM I9.stateCount 0 `shouldBe` ("tick:1", 2)

    it "ExceptM 短路到第一个错误" $
      I9.runExceptM I9.exceptErr `shouldBe` Left "boom"

  describe "Ch09.STArrays" $ do
    it "ST 就地反转：与列表 reverse 一致" $
      ST9.inPlaceReverse [1 .. 6] `shouldBe` reverse [1 .. 6]

    it "ST 斐波那契表：与递归版一致（含 n = 0, 1）" $
      map ST9.fibArray [0 .. 12] `shouldBe`
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]

    it "ST 斐波那契大数：第 100 项为 354224848179261915075" $
      ST9.fibArray 100 `shouldBe` 354224848179261915075

  describe "Ch13.Numeric" $ do
    it "点积：Seq 上的 (1,2,3)·(4,5,6) = 32" $
      N13.dot (Seq.fromList [1, 2, 3]) (Seq.fromList [4, 5, 6]) `shouldBe` 32

    it "点积：长度不符时报错而不是给错值" $
      evaluate (N13.dot (Seq.fromList [1, 2, 3]) (Seq.fromList [1, 2]))
        `shouldThrow` anyErrorCall

    it "dotTrunc 静默截断：只算了前两项" $
      N13.dotTrunc (Seq.fromList [1, 2, 3]) (Seq.fromList [1, 2]) `shouldBe` 5

    it "矩阵乘向量：恒等阵不动向量" $
      let eye = Seq.fromList [Seq.fromList [1, 0], Seq.fromList [0, 1]]
      in N13.matVec eye (Seq.fromList [3, 4]) `shouldBe` Seq.fromList [3, 4]

    it "矩阵乘：单位阵乘单位阵" $
      let eye = Seq.fromList [Seq.fromList [1, 0], Seq.fromList [0, 1]]
      in N13.matMul eye eye `shouldBe` eye

    it "中心差分近似导数：sin 在 1 处 ≈ cos 1" $
      N13.centralDiff sin 1 1e-6 `shouldSatisfy` \d -> abs (d - cos 1) < 1e-5

  describe "Ch13.Symbolic" $ do
    it "求值：x² + 3x + 2 在 x = 2 处等于 12" $
      S13.eval [("x", 2)] S13.exprDemo `shouldBe` 12

    it "符号求导：在 1、2、3 处与 2x + 3 一致" $
      map (\x -> S13.eval [("x", x)] S13.derivDemo) [1, 2, 3]
        `shouldBe` [5, 7, 9]

    it "化简：0 * x = 0，1 * x = x，x + 0 = x" $
      [ S13.simplify (S13.Mul (S13.Lit 0) (S13.Var "x"))
      , S13.simplify (S13.Mul (S13.Lit 1) (S13.Var "x"))
      , S13.simplify (S13.Add (S13.Var "x") (S13.Lit 0))
      ] `shouldBe` [S13.Lit 0, S13.Var "x", S13.Var "x"]

  describe "Ch13.Regression" $ do
    it "最小二乘：y = 1 + 2x 上取点，闭式解即 (1, 2)" $
      R13.ols R13.lrDemo `shouldBe` (1.0, 2.0)

    it "均方误差在真参数处为零" $
      R13.mse (1, 2) R13.lrDemo `shouldBe` 0.0

    it "梯度下降收敛到闭式解" $
      let path = take 3000 (R13.descend 0.01 R13.lrDemo (0, 0))
          (a, b) = last path
      in (abs (a - 1) < 0.02 && abs (b - 2) < 0.02) `shouldBe` True

  describe "Ch13.Autodiff" $ do
    it "对偶数求导：x² + 3x + 2 在 1、2、3 处导数为 5、7、9" $
      map (D13.derivAt D13.polyDemo) [1, 2, 3] `shouldBe` [5, 7, 9]

    it "自动微分与中心差分一致（误差 1e-6 内）" $
      map (\x -> D13.derivAt D13.polyDemo x - N13.centralDiff
        (\t -> t * t + 3 * t + 2) x 1e-6) [1, 2, 3]
        `shouldSatisfy` \ds -> all ((< 1e-5) . abs) ds

    it "自动微分与符号求导逐点一致" $
      map (\x -> D13.derivAt D13.polyDemo x - S13.eval [("x", x)] S13.derivDemo)
        [1, 2, 3] `shouldBe` [0, 0, 0]
