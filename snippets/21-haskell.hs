-- snippet 21 | Haskell.md:L608-L656 | lang=haskell | code-lines=47
-- 原文第 608 行是开始围栏，代码对应原文第 609-655 行
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
