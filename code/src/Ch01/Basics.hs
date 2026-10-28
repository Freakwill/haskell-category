-- | 第 1 章示例模块：只依赖 base + containers + text + mtl。
module Ch01.Basics
    ( myNub
    , myNubText
    , countWords
    , totalWords
    ) where

import           Control.Monad.State.Strict (State, execState, modify)
import qualified Data.Map.Strict            as Map
import qualified Data.Text                  as T

-- | 去除重复元素，保留首次出现的位置。
--
-- 书中 @foo@ 的写法是「保留最后一次出现」，这里用更常见的「保留首次出现」，
-- 两者都不依赖 Ord，只要求 Eq。
myNub :: Eq a => [a] -> [a]
myNub []       = []
myNub (x : xs) = x : myNub [y | y <- xs, y /= x]

-- | 与 'myNub' 同义，只是为 Text 提供一个显式签名的入口，
-- 便于在测试里验证 text 依赖确实被链接进来。
myNubText :: [T.Text] -> [T.Text]
myNubText = myNub

-- | 词频统计：用 State 单子累加 Map，顺带验证 mtl + containers。
countWords :: [T.Text] -> Map.Map T.Text Int
countWords ws = execState (mapM_ bump ws) Map.empty
  where
    bump :: T.Text -> State (Map.Map T.Text Int) ()
    bump w = modify (Map.insertWith (+) w 1)

-- | 总词数，用于第 2 章 do 语法的对照示例。
totalWords :: Map.Map T.Text Int -> Int
totalWords = sum . Map.elems
