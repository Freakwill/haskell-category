-- snippet 18 | Haskell.md:L524-L565 | lang=haskell | code-lines=40
-- 原文第 524 行是开始围栏，代码对应原文第 525-564 行
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
