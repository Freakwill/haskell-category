-- | Chapter 9: the four hand-rolled instances and their demos.  Each type
-- exists in mtl (Control.Monad.Writer / Reader / State / Except); the
-- versions here show the internals the standard library wraps.
module Ch09.Instances
    ( WriterM (..)
    , ReaderM (..)
    , StateM (..)
    , ExceptM (..)
    , writerLog
    , readerEnv
    , stateCount
    , exceptErr
    ) where

-- ANCHOR: writer
newtype WriterM w a = WriterM { runWriterM :: (a, w) }
    deriving (Eq, Show)

instance Functor (WriterM w) where
    fmap f (WriterM (a, w)) = WriterM (f a, w)

instance Monoid w => Applicative (WriterM w) where
    pure a = WriterM (a, mempty)
    WriterM (f, w1) <*> WriterM (a, w2) = WriterM (f a, w1 <> w2)

instance Monoid w => Monad (WriterM w) where
    WriterM (a, w1) >>= k =
        let WriterM (b, w2) = k a
        in WriterM (b, w1 <> w2)
-- ANCHOR_END: writer

-- ANCHOR: reader
newtype ReaderM r a = ReaderM { runReaderM :: r -> a }

instance Functor (ReaderM r) where
    fmap f (ReaderM g) = ReaderM (f . g)

instance Applicative (ReaderM r) where
    pure a = ReaderM (const a)
    ReaderM f <*> ReaderM g = ReaderM (\r -> f r (g r))

instance Monad (ReaderM r) where
    ReaderM g >>= k = ReaderM (\r -> runReaderM (k (g r)) r)
-- ANCHOR_END: reader

-- ANCHOR: state
newtype StateM s a = StateM { runStateM :: s -> (a, s) }

instance Functor (StateM s) where
    fmap f (StateM g) = StateM $ \s ->
        let (a, s1) = g s
        in (f a, s1)

instance Applicative (StateM s) where
    pure a = StateM (\s -> (a, s))
    StateM f <*> StateM g = StateM $ \s ->
        let (h, s1) = f s
            (a, s2) = g s1
        in (h a, s2)

instance Monad (StateM s) where
    StateM g >>= k = StateM $ \s ->
        let (a, s1) = g s
        in runStateM (k a) s1
-- ANCHOR_END: state

-- ANCHOR: except
newtype ExceptM e a = ExceptM { runExceptM :: Either e a }
    deriving (Eq, Show)

instance Functor (ExceptM e) where
    fmap _ (ExceptM (Left e))  = ExceptM (Left e)
    fmap f (ExceptM (Right a)) = ExceptM (Right (f a))

instance Applicative (ExceptM e) where
    pure = ExceptM . Right
    ExceptM (Left e) <*> _           = ExceptM (Left e)
    ExceptM (Right f) <*> ExceptM r  = ExceptM (fmap f r)

instance Monad (ExceptM e) where
    ExceptM (Left e)  >>= _ = ExceptM (Left e)
    ExceptM (Right a) >>= k = k a
-- ANCHOR_END: except

-- ANCHOR: writer-demo
writerLog :: WriterM [String] Int
writerLog = do
    a <- WriterM (3, ["add 3"])
    b <- WriterM (4, ["add 4"])
    WriterM (a + b, ["sum"])
-- ANCHOR_END: writer-demo

-- ANCHOR: reader-demo
readerEnv :: ReaderM Int Int
readerEnv = do
    a <- ReaderM (\r -> r + 1)
    b <- ReaderM (\r -> r * 2)
    ReaderM (\r -> a + b + r)
-- ANCHOR_END: reader-demo

-- ANCHOR: state-demo
stateCount :: StateM Int String
stateCount = do
    a <- StateM (\n -> (n, n + 1))
    b <- StateM (\n -> (n, n + 1))
    StateM (\n -> ("tick:" ++ show (a + b), n))
-- ANCHOR_END: state-demo

-- ANCHOR: except-demo
exceptErr :: ExceptM String Int
exceptErr = do
    a <- ExceptM (Right 3)
    b <- ExceptM (Left "boom")
    ExceptM (Right (a + b))
-- ANCHOR_END: except-demo
