-- snippet 04 | Haskell.md:L115-L124 | lang=haskell | code-lines=8
-- 原文第 115 行是开始围栏，代码对应原文第 116-123 行
type List a = [a] -- 类型别名, 右侧没有函数
type Function1D = Double -> Double
type Function1D a = a -> a

-- newtype 只接收一个参数
newtype Transform a = Transform （a->a） -- 接近 data (看作 data 特例) 而非 type，比data快速
newtype Const a b = Const a
newtype State s a = State {runState :: s -> (a, s)}
