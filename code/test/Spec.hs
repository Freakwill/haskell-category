module Main (main) where

import qualified Data.Map.Strict     as Map
import qualified Data.Text           as T
import           Ch01.Basics
import           Test.Hspec

main :: IO ()
main = hspec $ do
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
