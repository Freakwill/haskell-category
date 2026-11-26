{-# LANGUAGE FlexibleInstances #-}

-- | Chapter 4: type classes as constraints, not interfaces.
module Ch04.TypeClass
    ( Describable (..)
    , Combine (..)
    , Diff (..)
    , associatesOn
    , Container (..)
    , sumArea
    , Area (..)
    , Shape (..)
    , Side (..)
    , Person (..)
    ) where

-- ANCHOR: describe-class
-- | 一个方法 + 一个带默认实现的方法。
class Describable a where
    describe :: a -> String
    describeAll :: [a] -> [String]
    describeAll = map describe
-- ANCHOR_END: describe-class

instance Describable Bool where
    describe True  = "true"
    describe False = "false"

-- ANCHOR: describe-maybe
-- 实例可以带约束：只要元素可描述，Maybe 就可描述。
instance Describable a => Describable (Maybe a) where
    describe Nothing  = "nothing"
    describe (Just x) = "just " ++ describe x

instance Describable a => Describable [a] where
    describe xs = "[" ++ unwords (map describe xs) ++ "]"
-- ANCHOR_END: describe-maybe

-- ANCHOR: combine-class
-- 类的文档里写着一条定律，类型系统不检查它：
--   combine (combine x y) z == combine x (combine y z)
class Combine a where
    combine :: a -> a -> a

-- 满足定律的实例
instance Combine String where
    combine = (++)

-- 不满足定律的实例：减法不满足结合律
newtype Diff = Diff Int
    deriving (Eq, Show)

instance Combine Diff where
    combine (Diff x) (Diff y) = Diff (x - y)
-- ANCHOR_END: combine-class

-- ANCHOR: assoc-check
-- 定律只能在具体值上抽查，不能在类型层面证明。
associatesOn :: (Eq a, Combine a) => [a] -> Bool
associatesOn [x, y, z] = combine (combine x y) z == combine x (combine y z)
associatesOn _         = True
-- ANCHOR_END: assoc-check

-- ANCHOR: container
-- 对类型构造器抽象：f 是类型构造器，不是类型。
class Container f where
    empty  :: f a
    insert :: a -> f a -> f a
    toList :: f a -> [a]

instance Container [] where
    empty  = []
    insert = (:)
    toList = id
-- ANCHOR_END: container

-- ANCHOR: person-ord
-- 派生 Ord 的比较顺序由字段声明顺序决定：先 age，再 name。
data Person = Person { age :: Int, name :: String }
    deriving (Eq, Ord, Show)
-- ANCHOR_END: person-ord

-- ANCHOR: area-class
-- 同一个类可以有两个毫不相干的实例：类型类不要求实例之间有子类型关系。
class Area a where
    area :: a -> Double

data Shape = Circle Double | Rect Double Double

instance Area Shape where
    area (Circle r)   = pi * r * r
    area (Rect w h)   = w * h

newtype Side = Side Double

instance Area Side where
    area (Side s) = s * s

sumArea :: Area a => [a] -> Double
sumArea = sum . map area
-- ANCHOR_END: area-class
